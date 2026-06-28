local Settings <const> = lib.load('data.settings')

---@type integer | false
local particle = false

local BONES <const> = {
    "exhaust",
    "exhaust_2",
    "exhaust_3",
    "exhaust_4",
    "exhaust_5",
    "exhaust_6",
    "exhaust_7",
    "exhaust_8",
    "exhaust_9",
    "exhaust_10",
    "exhaust_11",
    "exhaust_12",
    "exhaust_13",
    "exhaust_14",
    "exhaust_15",
    "exhaust_16",
}

---@class privateNitrousData
---@field active boolean
---@field exhaust string|false

---@class Nitrous : OxClass
---@field private private privateNitrousData
---@diagnostic disable-next-line: assign-type-mismatch
local Nitrous = lib.class('vix_nitro')

function Nitrous:constructor()
    self.private.active = false
    self:setExhaustBone()
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
        for _,bone in pairs(BONES) do
            if GetEntityBoneIndexByName(cache.vehicle, bone) ~= -1 then
                self.private.exhaust = bone
                return
            end
        end
    end

    self.private.exhaust = false
end

function Nitrous:start()
    lib.callback('vix_nitrous:server:sync', false, function()
        lib.requestNamedPtfxAsset(Settings.particle.dict)
        SetPtfxAssetNextCall(Settings.particle.dict)
        UseParticleFxAssetNextCall(Settings.particle.dict)
        ---@diagnostic disable-next-line: param-type-mismatch
        particle = StartParticleFxLoopedOnEntityBone(Settings.particle.fx, cache.vehicle, 0.0, -0.02, 0.0, 0.0, 0.0, 0.0, GetEntityBoneIndexByName(cache.vehicle, self:getExhaustBone()), Settings.particle.size, false, false, false)
    end)

    SetVehicleBoostActive(cache.vehicle, true)
    SetVehicleEnginePowerMultiplier(cache.vehicle, Settings.multiplier.enginePower)
    SetVehicleEngineTorqueMultiplier(cache.vehicle, Settings.multiplier.engineTorque)

    self.private.active = true

    CreateThread(function()
        while self:isActive() do
            local nitro = Entity(cache.vehicle).state.nitrous

            if nitro > 0.0 then
                Entity(cache.vehicle).state:set('nitrous', nitro - Settings.depletionRate, true)
            else
                self:stop(true)
            end

            Wait(Settings.depletionTick)
        end
    end)
end

---@param item boolean
function Nitrous:stop(item)
    lib.callback('vix_nitrous:server:sync', false, function()
        ---@diagnostic disable-next-line: param-type-mismatch
        StopParticleFxLooped(particle, true)
        RemoveNamedPtfxAsset(Settings.particle.dict)
        particle = false
    end)

    SetVehicleBoostActive(cache.vehicle, false)
    SetVehicleEnginePowerMultiplier(cache.vehicle, 0.0)
    SetVehicleEngineTorqueMultiplier(cache.vehicle, 0.0)

    if item and Settings.giveEmpty then
        TriggerServerEvent('vix_nitrous:server:unload', VehToNet(cache.vehicle))
    end

    self.private.active = false
end

return Nitrous