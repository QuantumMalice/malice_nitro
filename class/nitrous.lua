local Settings <const> = lib.load('data.settings')

---@class privateNitrousData
---@field active boolean
---@field vehicles table

---@class Nitrous : OxClass
---@field keybind CKeybind
---@field private private privateNitrousData
---@diagnostic disable-next-line: assign-type-mismatch
local Nitrous = lib.class('malice_nitro')

function Nitrous:constructor()
    self.private.active = false
    self.private.vehicles = {}
    self:addVehicle(cache.vehicle)

    self.keybind = lib.addKeybind({
        name = 'nitrous',
        description = 'press left shift to activate nitrous',
        defaultKey = 'LSHIFT',
        disabled = true,
        onPressed = function()
            if self:isActive() then return end
            if not self:isVehicleValid() then return end
            if not GetIsVehicleEngineRunning(cache.vehicle) then return end

            local nitro = Entity(cache.vehicle).state.nitrous

            if nitro and nitro > 0.0 then
                self:start()
            end
        end,
        onReleased = function()
            if not self:isActive() then return end
            if not self:isVehicleValid() then return end

            local nitro = Entity(cache.vehicle).state.nitrous

            if nitro and nitro > 0.0 then
                self:stop(false)
            end
        end
    })
end

---@return boolean active
function Nitrous:isActive() return self.private.active end

---@return boolean valid
function Nitrous:isVehicleValid()
    local class = GetVehicleClass(cache.vehicle)
    local model = GetEntityModel(cache.vehicle)
    local electric = GetIsVehicleElectric(model)

    return class <= 9 and not electric
end

---@return boolean found
---@return boolean added
function Nitrous:addVehicle(vehicle)
    if not vehicle or not DoesEntityExist(vehicle) then return false, false end

    if self.private.vehicles[cache.vehicle] then return true, false end

    self.private.vehicles[vehicle] = {
        bones = {},
        particles = {}
    }

    for i = 1, 16 do
        local name = i == 1 and "exhaust" or ("exhaust_%d"):format(i)
        local index = GetEntityBoneIndexByName(vehicle, name)

        if index ~= -1 then
            table.insert(self.private.vehicles[vehicle].bones, index)
        end
    end

    if #self.private.vehicles[vehicle].bones == 0 then
        self.private.vehicles[vehicle] = nil

        return false, false
    else
        return false, true
    end
end

function Nitrous:removeVehicle(vehicle)
    if not vehicle then return end

    self:stop(false)

    if self.private.vehicles[vehicle] then
        self.private.vehicles[vehicle] = nil
    end
end

function Nitrous:start()
    self.private.active = true
    Entity(cache.vehicle).state:set('flame', true, true)
    SetVehicleBoostActive(cache.vehicle, true)
    SetVehicleEnginePowerMultiplier(cache.vehicle, Settings.multiplier.enginePower)
    SetVehicleEngineTorqueMultiplier(cache.vehicle, Settings.multiplier.engineTorque)

    CreateThread(function()
        while self:isActive() do
            local nitro = Entity(cache.vehicle).state.nitrous

            if nitro > 0.0 then
                Entity(cache.vehicle).state:set('nitrous', nitro - Settings.depletionRate, true)
            else
                self:stop(true)
                self.keybind:disable(true)
            end

            Wait(Settings.depletionTick)
        end
    end)
end

---@param item boolean
function Nitrous:stop(item)
    self.private.active = false
    Entity(cache.vehicle).state:set('flame', false, true)
    SetVehicleBoostActive(cache.vehicle, false)
    SetVehicleEnginePowerMultiplier(cache.vehicle, 0.0)
    SetVehicleEngineTorqueMultiplier(cache.vehicle, 0.0)

    if item and Settings.giveEmpty then
        TriggerServerEvent('malice_nitrous:server:giveEmpty', VehToNet(cache.vehicle))
    end
end

function Nitrous:startFlame(vehicle)
    local found, added = self:addVehicle(vehicle)
    if not found and not added then return end

    lib.requestNamedPtfxAsset(Settings.particle.dict)

    for _, bone in ipairs(self.private.vehicles[vehicle].bones) do
        UseParticleFxAssetNextCall(Settings.particle.dict)

        local particle = StartNetworkedParticleFxLoopedOnEntityBone(
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
end

function Nitrous:stopFlame(vehicle)
    if not self.private.vehicles[vehicle] then return end

    for _, particle in ipairs(self.private.vehicles[vehicle].particles) do
        StopParticleFxLooped(particle, true)
    end

    RemoveNamedPtfxAsset(Settings.particle.dict)
    self.private.vehicles[vehicle].particles = {}
end

return Nitrous