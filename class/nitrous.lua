local Settings <const> = lib.load('data.settings')
local Progress <const> = lib.load('data.progress')
local Notify <const> = lib.load('data.notify')
local Inventory <const> = exports.ox_inventory

---@class privateNitrousData
---@field active boolean
---@field loaded boolean
---@field vehicles table<number, { bones: number[], particles: number[] }>

---@class Nitrous : OxClass
---@field keybind CKeybind
---@field private private privateNitrousData
---@diagnostic disable-next-line: assign-type-mismatch
local Nitrous = lib.class('malice_nitro')

function Nitrous:constructor()
    self.private.active = false
    self.private.loaded = false
    self.private.vehicles = {}

    self.keybind = lib.addKeybind({
        name = 'nitrous',
        description = 'press left shift to activate nitrous',
        defaultKey = 'LSHIFT',
        disabled = true,
        onPressed = function()
            if self:isActive() then return end
            if not self:isVehicleValid() then return end
            if cache.seat ~= -1 then return end
            if not GetIsVehicleEngineRunning(cache.vehicle) then return end

            local nitro = Entity(cache.vehicle).state.nitrous
            if nitro and nitro > 0.0 then
                self:start()
            end
        end,
        onReleased = function()
            if not self:isActive() then return end

            self:stop(true)
        end
    })

    if cache.seat == -1 and self:isVehicleValid() then
        self:setExhaustBones(cache.vehicle, true)

        local nitro = Entity(cache.vehicle).state.nitrous

        if nitro and nitro > 0.0 then
            self:setLoaded(true)
        end
    end
end

---@return boolean active
function Nitrous:isActive() return self.private.active end

---@return boolean valid
function Nitrous:isVehicleValid()
    if not cache.vehicle or not DoesEntityExist(cache.vehicle) then return false end

    local class = GetVehicleClass(cache.vehicle)
    local model = GetEntityModel(cache.vehicle)
    local electric = GetIsVehicleElectric(model)

    return class <= 9 and not electric
end

function Nitrous:addRadialItem()
    lib.addRadialItem({
        {
            id = 'unload_nitrous',
            label = locale('radial.unload'),
            icon = 'hand-holding-droplet',
            onSelect = function()
                if self:isActive() then return end

                self.keybind:disable(true)

                if lib.progressCircle(Progress['uninstall']) then
                    TriggerServerEvent('malice_nitrous:server:unload')
                end

                -- The nitrous statebag handler removes the radial item once the server has unloaded it
                self.keybind:disable(not self.private.loaded)
            end
        }
    })
end

---Shows or hides the unload radial item and the nitrous keybind
---@param loaded boolean
function Nitrous:setLoaded(loaded)
    if self.private.loaded == loaded then return end

    self.private.loaded = loaded

    if loaded then
        self:addRadialItem()
    else
        lib.removeRadialItem('unload_nitrous')
    end

    self.keybind:disable(not loaded)
end

---@param vehicle number | false
---@param state boolean
function Nitrous:setExhaustBones(vehicle, state)
    if not vehicle or not DoesEntityExist(vehicle) then return end

    if state and not self.private.vehicles[vehicle] then
        self.private.vehicles[vehicle] = { bones = {}, particles = {} }

        for i = 1, 16 do
            local name = i == 1 and "exhaust" or ("exhaust_%d"):format(i)
            local index = GetEntityBoneIndexByName(vehicle, name)

            if index ~= -1 then
                table.insert(self.private.vehicles[vehicle].bones, index)
            end
        end
    elseif not state then
        self.private.vehicles[vehicle] = nil
    end
end

function Nitrous:load()
    if not cache.vehicle or cache.seat ~= -1 then return false end
    if Inventory:Search('count', 'nitrous') < 1 then return false end
    if not self:isVehicleValid() then lib.notify(Notify['not_valid']) return false end
    if Settings.needTurbo and not IsToggleModOn(cache.vehicle, 18) then lib.notify(Notify['no_turbo']) return false end

    local nitro = Entity(cache.vehicle).state.nitrous
    if nitro and nitro > 0.0 then lib.notify(Notify['is_loaded']) return false end

    return lib.progressCircle(Progress['install']) == true
end

function Nitrous:start()
    if self.private.active then return end

    local success = lib.callback.await('malice_nitro:server:start')
    if not success then return end

    self.private.active = true

    -- The key was released while waiting for the server
    if not self.keybind:isControlPressed() then
        return self:stop(true)
    end

    CreateThread(function()
        SetVehicleBoostActive(cache.vehicle, true)

        while self:isActive() do
            SetVehicleEnginePowerMultiplier(cache.vehicle, Settings.multiplier.enginePower)
            SetVehicleEngineTorqueMultiplier(cache.vehicle, Settings.multiplier.engineTorque)

            Wait(0)
        end
    end)
end

---@param notifyServer boolean
function Nitrous:stop(notifyServer)
    if not self.private.active then return end

    if not cache.vehicle then
        self.private.active = false
        return
    end

    self.private.active = false

    if notifyServer then
        lib.callback.await('malice_nitro:server:stop')
    end
end

---@param vehicle number
function Nitrous:startFlame(vehicle)
    self:setExhaustBones(vehicle, true)
    lib.requestNamedPtfxAsset(Settings.particle.dict)

    for _, bone in ipairs(self.private.vehicles[vehicle].bones) do
        UseParticleFxAssetNextCall(Settings.particle.dict)

        local particle = StartParticleFxLoopedOnEntityBone(
            Settings.particle.fx,
            vehicle,
            0.0,
            -0.02,
            0.0,
            0.0,
            0.0,
            0.0,
            bone,
            Settings.particle.size,
            false,
            false,
            false
        )

        self.private.vehicles[vehicle].particles[#self.private.vehicles[vehicle].particles + 1] = particle
    end

    RemoveNamedPtfxAsset(Settings.particle.dict)
end

---@param vehicle number
function Nitrous:stopFlame(vehicle)
    local data = self.private.vehicles[vehicle]
    if not data then return end

    for _, particle in ipairs(self.private.vehicles[vehicle].particles) do
        StopParticleFxLooped(particle, true)
    end

    self:setExhaustBones(vehicle, false)
end

return Nitrous