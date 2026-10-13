lib.versionCheck('QuantumMalice/malice_nitro')
lib.locale()

local Inventory <const> = exports.ox_inventory
local Settings <const> = lib.load('data.settings')
local Notify <const> = lib.load('data.notify')

---@class ActiveNitrous
---@field source integer
---@field startedAt integer
---@field startingNitro number

---@type table<integer, ActiveNitrous>
local activeNitrous = {}

---@param src integer
local function isNear(src)
    local ped = GetPlayerPed(src)
    if ped == 0 then return false end

    local coords = GetEntityCoords(ped)
    for _, location in pairs(Settings.peds) do
        local pedCoords = vec3(location.coords.x, location.coords.y, location.coords.z)

        if #(pedCoords - coords) <= 5.0 then
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

---@param vehicle integer
local function stopNitrous(vehicle)
    local data = activeNitrous[vehicle]
    if not data then return end

    activeNitrous[vehicle] = nil

    if not DoesEntityExist(vehicle) then return end

    local state = Entity(vehicle).state
    state:set('flame', false, true)

    local nitro = Entity(vehicle).state.nitrous
    if nitro and nitro <= 0.0 then
        if Settings.giveEmpty then
            if Inventory:CanCarryItem(data.source, 'nitrous', 1) then
                Inventory:AddItem(data.source, 'nitrous', 1, { durability = 0 })
            else
                lib.notify(data.source, Notify['no_space'])
            end
        end

        state:set('nitrous', nil, true)
    end

    TriggerClientEvent('malice_nitro:client:stop', data.source)
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
    if event ~= 'usingItem' then return end

    local itemSlot = Inventory:GetSlot(inventory.id, slot)
    if not itemSlot then return false end

    local level = itemSlot.metadata.durability
    if not level or level <= 0.0 then return false end

    local success = lib.callback.await('malice_nitrous:client:load', inventory.id)
    if not success then return false end

    local ped = GetPlayerPed(inventory.id)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 then return false end

    local state = Entity(vehicle).state
    local nitro = state.nitrous
    if nitro and nitro > 0.0 then return false end

    state:set('nitrous', level, true)
end)

lib.callback.register('malice_nitro:server:start', function()
    local src = source
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) then return false end
    if activeNitrous[vehicle] then return false end

    local state = Entity(vehicle).state
    local nitro = state.nitrous
    if not nitro or nitro <= 0.0 then return false end

    activeNitrous[vehicle] = {
        source = src,
        startedAt = GetGameTimer(),
        startingNitro = nitro
    }

    state:set('flame', true, true)

    return true
end)

lib.callback.register('malice_nitro:server:stop', function()
    local src = source
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) then
        vehicle = GetVehiclePedIsIn(ped, true)
    end
    if not DoesEntityExist(vehicle) then return end

    local data = activeNitrous[vehicle]
    if not data or data.source ~= src then return false end

    stopNitrous(vehicle)

    return true
end)

RegisterNetEvent('malice_nitrous:server:unload', function()
    local src = source
    local ped = GetPlayerPed(src)
    local vehicle = GetVehiclePedIsIn(ped, false)

    if not DoesEntityExist(vehicle) then return end
    if activeNitrous[vehicle] then return end -- Don't allow unloading while nitrous is actively being used.

    local state = Entity(vehicle).state
    local nitro = state.nitrous
    if not nitro or nitro <= 0.0 then return end

    if not Inventory:CanCarryItem(src, 'nitrous', 1) then lib.notify(src, Notify['no_space']) return end

    local success = Inventory:AddItem(src, 'nitrous', 1, { durability = nitro })

    if success then
        state:set('nitrous', nil, true)
        state:set('flame', false, true)
    end
end)

CreateThread(function()
    while true do
        local now = GetGameTimer()

        for vehicle, data in pairs(activeNitrous) do
            if not DoesEntityExist(vehicle) then
                activeNitrous[vehicle] = nil
                goto continue
            end

            local ped = GetPlayerPed(data.source)

            if ped == 0 then
                activeNitrous[vehicle] = nil
                Entity(vehicle).state:set('flame', false, true)
                goto continue
            end

            if GetVehiclePedIsIn(ped, false) ~= vehicle
                or GetPedInVehicleSeat(vehicle, -1) ~= ped then

                stopNitrous(vehicle)
                goto continue
            end

            local elapsed = now - data.startedAt
            local nitro = data.startingNitro - (elapsed / Settings.depletionTick * Settings.depletionRate)

            if nitro <= 0.0 then
                Entity(vehicle).state:set('nitrous', 0.0, true)
                stopNitrous(vehicle)
                goto continue
            end

            Entity(vehicle).state:set('nitrous', nitro, true)

            ::continue::
        end

        Wait(Settings.depletionTick)
    end
end)

if Settings.giveEmpty then
    RegisterNetEvent('malice_nitrous:server:giveEmpty', function()
        local src = source
        local ped = GetPlayerPed(src)
        local vehicle = GetVehiclePedIsIn(ped, false)

        if not DoesEntityExist(vehicle) then return end
        if activeNitrous[vehicle] then return end

        local state = Entity(vehicle).state
        local nitro = state.nitrous
        if nitro ~= 0.0 then return end

        if not Inventory:CanCarryItem(src, 'nitrous', 1) then
            lib.notify(src, Notify['no_space'])
            return
        end

        local success = Inventory:AddItem(src, 'nitrous', 1, { durability = 0 })

        if success then
            state:set('nitrous', nil, true)
        end
    end)
end

if Settings.useRefill then
    RegisterNetEvent('malice_nitro:server:refill', function()
        local src = source

        local count = Inventory:Search(src, 'count', 'nitrous', { durability = 0 })
        if count < 1 or not isNear(src) then return end

        local success = handlePayment(src)

        if not success then
            lib.notify(src, Notify['no_funds'])
            return
        end

        local slot = Inventory:GetSlotIdWithItem(src, 'nitrous', { durability = 0 }, true)

        if not Inventory:CanCarryItem(src, 'nitrous', 1) then
            lib.notify(src, Notify['no_space'])
            return
        end

        local removed = Inventory:RemoveItem(src, 'nitrous', 1, { durability = 0 }, slot, true, true)
        if not removed then return end

        Inventory:AddItem(src, 'nitrous', 1, { durability = 100 })
    end)
end

AddEventHandler('playerDropped', function()
    local src = source

    for vehicle, data in pairs(activeNitrous) do
        if data.source == src then
            if DoesEntityExist(vehicle) then
                Entity(vehicle).state:set('flame', false, true)
            end

            activeNitrous[vehicle] = nil
        end
    end
end)