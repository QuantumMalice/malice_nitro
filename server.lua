lib.versionCheck("QuantumMalice/malice_nitro")
lib.locale()

local Inventory <const> = exports.ox_inventory
local Settings <const> = lib.load('data.settings')
local Notify <const> = lib.load('data.notify')

---@param src integer
local function isNear(src)
    local entity <const> = GetPlayerPed(src)
    local coords <const> = GetEntityCoords(entity)

    for index, ped in pairs(Settings.peds) do
        local location = vec3(ped.coords.x, ped.coords.y, ped.coords.z)

        if #(location - coords) <= 5 then
            return true
        end
    end

    return false
end

---@param src integer
local function handlePayment(src)
    -- Implement cash/bank or crypto logic here
    return true
end

Inventory:registerHook('createItem', function(payload)
    local metadata = payload.metadata

    if not metadata.durability then
        metadata.durability = 100
        return metadata
    end
end, {
    itemFilter = {
        nitrous = true
    }
})

exports('nitrous', function(event, item, inventory, slot, data)
    if event == 'usingItem' then
        local itemSlot = Inventory:GetSlot(inventory.id, slot)
        local level = itemSlot.metadata.durability

        if level and level > 0.0 then
            local success, netid = lib.callback.await('malice_nitrous:client:load', inventory.id)

            if success then
                local vehicle = NetworkGetEntityFromNetworkId(netid)
                Entity(vehicle).state:set('nitrous', level, true)

                return
            end
        end

        return false
    end
end)

lib.callback.register('malice_nitrous:server:sync', function()
    return true
end)

---@param netid integer
RegisterNetEvent('malice_nitrous:server:unload', function(netid)
    local src = source
    local vehicle = NetworkGetEntityFromNetworkId(netid)

    if DoesEntityExist(vehicle) then
        local nitro = Entity(vehicle).state.nitrous

        if nitro and nitro > 0.0 then
            Entity(vehicle).state:set('nitrous', nil, true)
            Inventory:AddItem(src, 'nitrous', 1, { durability = nitro })
        end
    end
end)

if Settings.giveEmpty then
    ---@param netid integer
    RegisterNetEvent('malice_nitrous:server:giveEmpty', function(netid)
        local src = source
        local vehicle = NetworkGetEntityFromNetworkId(netid)

        if DoesEntityExist(vehicle) then
            local nitro = Entity(vehicle).state.nitrous

            if nitro and nitro <= 0.0 then
                Entity(vehicle).state:set('nitrous', nil, true)
                Inventory:AddItem(src, 'nitrous', 1, { durability = 0 })
            end
        end
    end)
end

if Settings.useRefill then
    RegisterNetEvent('malice_nitro:server:refill', function()
        local src = source
        local count = Inventory:Search(src, 'count', 'nitrous', { durability = 0 })

        if count >= 1 and isNear(src) then
            local success = handlePayment(src)

            if success then
                local slot = Inventory:GetSlotIdWithItem(src, 'nitrous', { durability = 0 }, true)

                if Inventory:CanCarryItem(src, 'nitorus', 1) then
                    Inventory:RemoveItem(src, 'nitrous', 1, { durability = 0 }, slot, true, true)
                    Inventory:AddItem(src, 'nitrous', 1, { durability = 100 })
                else
                    lib.notify(src, Notify['no_space'])
                end
            else
                lib.notify(src, Notify['no_funds'])
            end
        end
    end)
end