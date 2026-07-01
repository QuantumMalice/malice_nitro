lib.locale()

---@class Nitrous : OxClass
local Class = require 'class.nitrous'
local Target <const> = exports.ox_target
local Inventory <const> = exports.ox_inventory
local Progress <const> = lib.load('data.progress')
local Settings <const> = lib.load('data.settings')
local Notify <const> = lib.load('data.notify')

local Nitrous = nil

local function addRadialItem()
    lib.addRadialItem({
        {
            id = 'unload_nitrous',
            label = 'Unload Nitrous',
            icon = 'hand-holding-droplet',
            onSelect = function()
                --TODO: Add a progress bar for unloading nitrous
                local success = lib.callback.await('malice_nitrous:server:unload', false,  VehToNet(cache.vehicle))

                if success then
                    lib.removeRadialItem('unload_nitrous')
                end
            end
        }
    })
end

lib.callback.register('malice_nitrous:client:load', function()
    if not Nitrous then return false end
    if not cache.vehicle or cache.seat ~= -1 then return false end
    if Inventory:Search('count', 'nitrous') < 1 then return false end
    if not Nitrous:isVehicleValid() then lib.notify(Notify['not_valid']) return false end
    if Settings.needTurbo and not IsToggleModOn(cache.vehicle, 18) then lib.notify(Notify['no_turbo']) return false end

    local nitro = Entity(cache.vehicle).state.nitrous
    if nitro and nitro > 0.0 then lib.notify(Notify['is_loaded']) return false end

    if lib.progressCircle(Progress['install']) then
        ClearPedTasks(cache.ped)
        Nitrous.keybind:disable(false)
        addRadialItem()

        return true, VehToNet(cache.vehicle)
    else
        return false
    end
end)

---@param seat number
lib.onCache('seat', function(seat)
    if not Nitrous then return end

    if Nitrous:getExhaustBone() ~= nil then
        Nitrous:setExhaustBone()

        if seat == -1 and Nitrous:isVehicleValid() then
            local nitro = Entity(cache.vehicle).state.nitrous

            if nitro and nitro > 0.0 then
                addRadialItem()
                Nitrous.keybind:disable(false)
            end
        else
            if Nitrous:isActive() then
                Nitrous:stop(false)
            end

            if not Nitrous.keybind.disabled then
                lib.removeRadialItem('unload_nitrous')
                Nitrous.keybind:disable(true)
            end
        end
    end
end)

CreateThread(function()
    Nitrous = Class:new()

    if cache.seat == -1 and Nitrous:isVehicleValid() then
        local nitro = Entity(cache.vehicle).state.nitrous

        if nitro and nitro > 0.0 then
            addRadialItem()
            Nitrous.keybind:disable(false)
        end
    end

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