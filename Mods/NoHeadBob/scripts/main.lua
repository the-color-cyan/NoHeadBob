-- VHOLUME No Head Bob (run shake only)
-- Requires UE4SS / zDEV-UE4SS.

print("[NoHeadBob] Loaded\n")

local RUN_SHAKE_DEFAULT =
    "/Game/FirstPersonBP/Blueprints/CameraShakes/CameraShake_Run.Default__CameraShake_Run_C"

local applied = false

local function disable_run_bob(shake)
    if not shake or not shake:IsValid() then
        return false
    end

    -- Actual vertical head-bob: Z amplitude 8.0 at 15 Hz.
    shake.LocOscillation.Z.Amplitude = 0.0

    -- Accompanying roll/sway: amplitude 0.3 at 8 Hz.
    shake.RotOscillation.Roll.Amplitude = 0.0

    return true
end

local function apply_no_head_bob()
    if applied then
        return
    end

    local shake = StaticFindObject(RUN_SHAKE_DEFAULT)

    if disable_run_bob(shake) then
        applied = true
        print("[NoHeadBob] NoHeadBob successfully applied\n")
    else
        print("[NoHeadBob] Waiting for CameraShake_Run default object...\n")
    end
end

-- The class default may load only after entering a level; retry until found.
LoopAsync(250, function()
    ExecuteInGameThread(apply_no_head_bob)
    return applied
end)
