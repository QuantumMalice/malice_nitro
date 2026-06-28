return {
    giveEmpty = true, -- Give empty bottle after nitrous is fully consumed
    useRefill = true, -- Use refill locations
    needTurbo = true, -- Require a turbo to be installed first before installing nitrous
    depletionRate = 0.25, -- Rate that the nitrous level will be deducted by
    depletionTick = 200, -- Speed that each deduction will occur (milliseconds)
    multiplier = {
        enginePower = 10.0, -- Engine power multiplier applied when nitrous is being used
        engineTorque = 10.0 -- Engine torque multiplier applied when nitrous is being used
    },
    particle = {
        dict = "veh_xs_vehicle_mods", -- Particle dictionary
        fx = "veh_nitrous", -- Particle effect
        size = 1.3 -- Particle size
    },
    peds = { -- Refill locations
        {
            model = 'mp_m_waremech_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            coords = vec4(-202.012451, -1314.057739, 30.089340, 184.154236),
        },
    }
}