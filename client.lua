lib.locale()

---@class Nitrous : OxClass
local Nitrous = require('class.nitrous'):new()
local Target <const> = exports.ox_target
local Inventory <const> = exports.ox_inventory
local Settings <const> = lib.load('data.settings')

---@param seat number
lib.onCache('seat', function(seat)
    if seat ~= -1 then
        Nitrous:setLoaded(false)
        return
    end

    if not Nitrous:isVehicleValid() then return end

    Nitrous:setExhaustBones(cache.vehicle, true)

    local nitro = Entity(cache.vehicle).state.nitrous

    Nitrous:setLoaded(nitro and nitro > 0.0 or false)
end)

---@param current number|false
---@param old number|false
lib.onCache('vehicle', function(current, old)
    if current or not old then return end

    Nitrous:setLoaded(false)
end)

lib.callback.register('malice_nitrous:client:load', function()
    if not cache.vehicle then return false end

    return Nitrous and Nitrous:load() or false
end)

RegisterNetEvent('malice_nitro:client:stop', function()
    if not Nitrous:isActive() then return end

    Nitrous:stop(false)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('nitrous', nil, function(bagName, _, value)
    if cache.seat ~= -1 or not cache.vehicle then return end
    if GetEntityFromStateBagName(bagName) ~= cache.vehicle then return end
    if not Nitrous:isVehicleValid() then return end

    Nitrous:setLoaded(value and value > 0.0 or false)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('flame', nil, function(bagName, _, value)
    if value == nil then return end

    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 or not DoesEntityExist(vehicle) then return end

    if value then
        Nitrous:startFlame(vehicle)
    else
        Nitrous:stopFlame(vehicle)
    end
end)

CreateThread(function()
    if Settings.useRefill then
        for index, ped in pairs(Settings.peds) do
            lib.zones.sphere({
                debug = false,
                coords = vec3(ped.coords.x, ped.coords.y, ped.coords.z),
                radius = 20,
                onEnter = function(self)
                    lib.requestModel(ped.model)

                    self.ped = CreatePed(1, ped.model, ped.coords.x, ped.coords.y, ped.coords.z, ped.coords.w, false, true)
                    SetModelAsNoLongerNeeded(ped.model)

                    FreezeEntityPosition(self.ped, true)
                    SetEntityInvincible(self.ped, true)
                    SetBlockingOfNonTemporaryEvents(self.ped, true)
                    TaskStartScenarioInPlace(self.ped, ped.scenario, 0, true)

                    Target:addLocalEntity(self.ped, {
                        name = ('nitro:refill:%s'):format(index),
                        icon = 'fa-solid fa-droplet',
                        iconColor = 'lightblue',
                        label = locale('target.refill'),
                        distance = 2,
                        serverEvent = 'malice_nitro:server:refill',
                        canInteract = function()
                            return Inventory:Search('count', 'nitrous', { durability = 0 }) >= 1
                        end
                    })
                end,
                onExit = function(self)
                    SetPedAsNoLongerNeeded(self.ped)
                    DeleteEntity(self.ped)
                end
            })
        end
    end
end)