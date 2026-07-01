local Settings <const> = lib.load('data.settings')

---@type integer | false
local particle = false

---@class privateNitrousData
---@field active boolean
---@field exhaust integer|false

---@class Nitrous : OxClass
---@field keybind CKeybind
---@field private private privateNitrousData
---@diagnostic disable-next-line: assign-type-mismatch
local Nitrous = lib.class('malice_nitro')

function Nitrous:constructor()
    self.private.active = false
    self:setExhaustBone()

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

function Nitrous:getExhaustBone() return self.private.exhaust end

---@return boolean valid
function Nitrous:isVehicleValid()
    local class = GetVehicleClass(cache.vehicle)
    local model = GetEntityModel(cache.vehicle)
    local electric = GetIsVehicleElectric(model)

    return class <= 9 and not electric and self:getExhaustBone() ~= false
end

function Nitrous:setExhaustBone()
    if cache.vehicle then
        for i = 1, 16 do
            local name = i == 1 and "exhaust" or ("exhaust_%d"):format(i)
            local bone = GetEntityBoneIndexByName(cache.vehicle, name)

            if bone ~= -1 then
                self.private.exhaust = bone
                return
            end
        end
    end

    self.private.exhaust = false
end

function Nitrous:start()
    if self.private.active then return end

    self.private.active = true

    lib.requestNamedPtfxAsset(Settings.particle.dict)
    SetPtfxAssetNextCall(Settings.particle.dict)
    UseParticleFxAssetNextCall(Settings.particle.dict)
    ---@diagnostic disable-next-line: param-type-mismatch
    particle = StartParticleFxLoopedOnEntityBone(Settings.particle.fx, cache.vehicle, 0.0, -0.02, 0.0, 0.0, 0.0, 0.0, self.private.exhaust, Settings.particle.size, false, false, false)

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
    if not self.private.active then return end

    self.private.active = false

    ---@diagnostic disable-next-line: param-type-mismatch
    StopParticleFxLooped(particle, true)
    RemoveNamedPtfxAsset(Settings.particle.dict)
    particle = false

    SetVehicleBoostActive(cache.vehicle, false)
    SetVehicleEnginePowerMultiplier(cache.vehicle, 0.0)
    SetVehicleEngineTorqueMultiplier(cache.vehicle, 0.0)

    if item and Settings.giveEmpty then
        TriggerServerEvent('malice_nitrous:server:giveEmpty', VehToNet(cache.vehicle))
    end
end

return Nitrous