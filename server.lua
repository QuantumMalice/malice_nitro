lib.versionCheck("QuantumMalice/malice_nitro")
lib.locale()

local Inventory <const> = exports.ox_inventory
local Settings <const> = lib.load('data.settings')
local Notify <const> = lib.load('data.notify')

local vehicles = {}

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

exports('nitrous', function(event, item, inventory)
    if event == 'usingItem' then
        local success, netid = lib.callback.await('vix_nitrous:client:load', inventory.id)

        if success then
            if Settings.giveEmpty then
                local vehicle = NetworkGetEntityFromNetworkId(netid)
                vehicles[vehicle] = true
            end

            return
        else
            return false
        end
    end
end)

if Settings.giveEmpty then
    ---@param netid integer
    RegisterNetEvent('vix_nitrous:server:unload', function(netid)
        local src = source
        local vehicle = NetworkGetEntityFromNetworkId(netid)

        if vehicles[vehicle] and DoesEntityExist(vehicle) then
            vehicles[vehicle] = nil
            Inventory:AddItem(src, 'emptynitrous', 1)
        end
    end)
end

if Settings.useRefill then
    RegisterNetEvent('vix_nitro:server:refill', function()
        local src = source
        local count = Inventory:Search(src, 'count', 'emptynitrous')

        if count >= 1 and isNear(src) then
            local success = handlePayment(src)

            if success then
                Inventory:RemoveItem(src, 'emptynitrous', 1)
                Inventory:AddItem(src, 'nitrous', 1)
            else
                lib.notify(src, Notify['no_funds'])
            end
        end
    end)
end

lib.callback.register('vix_nitrous:server:sync', function()
    return true
end)