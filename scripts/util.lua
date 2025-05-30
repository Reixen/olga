--#region Variables
local Mod = OlgaMod

local Util = {}
OlgaMod.Util = Util

Util.HeadAnim= {
    IDLE = "Idle",
    HAPPY = "Happy",
    HAPPY_TO_IDLE = "HappyToIdle",
    IDLE_TO_HAPPY = "IdleToHappy",
    YAWN = "Yawn",
    PETTING = "Petting",
    HAPPY_TO_PETTING = "HappyToPetting",
    PETTING_TO_HAPPY = "PettingToHappy",
    EAR_FLICK_L = "EarFlickLeft",
    EAR_FLICK_R = "EarFlickRight",
    EAR_FLICK_BOTH = "EarFlickBoth",
    -- Unused
    IDLE_TO_HOLD = "IdleToHold",
    HOLD = "Hold",
    HOLD_TO_IDLE = "HoldToIdle"
}

Util.BodyAnim = {
    SIT = "Sit",
    SIT_WAGGING = "SitWagging",
    SIT_TO_STAND = "SitToStand",
    STAND_TO_SIT = "StandToSit",
    STAND = "Stand",
    WALKING = "Walking"
}

Util.DogState = {
    SITTING = 0,
    STANDING = 1,
    OBTAIN = 2,
    RETRIEVE = 3,
}

Util.MiniAnim = {
    EARFLICK = 1
}

Util.MiniAnimVariants = {
    {"EarFlick", {"Left", "Right", "Both"}}
}

local ONE_SEC = 30
Util.ANIM_COOLDOWN = ONE_SEC * 5

--#endregion
--#region Functions
---@param olga EntityFamiliar
---@param anim string
---@param isHead? boolean
function Util:SetAnimation(olga, anim, isHead)
    if isHead then
        local data = olga:GetData()
        data.headSprite:Play(anim, true)
    else
        olga:GetSprite():Play(anim, true)
    end
end

---@param olga EntityFamiliar
---@param target Vector
---@param distance number
function Util:IsWithin(olga, target, distance)
    return olga.Position:DistanceSquared(target) < distance ^ 2
end

-- Special thanks to Kerkel
---@param entity Entity
---@param identifier any
---@param default any
function Util:GetData(entity, identifier, default)
    local data = entity:GetData()
    data._OlgaMod = data._OlgaMod or {}
    data._OlgaMod[identifier] = data._OlgaMod[identifier] or default or {}
    return data._OlgaMod[identifier]
end

---@param olga EntityFamiliar
function Util:CanIdleAnimation(olga)
    return olga.State ~= Util.DogState.OBTAIN and olga.State ~= Util.DogState.RETRIEVE
end

---@param olga EntityFamiliar
---@param anim integer?
function Util:DoMiniIdleAnim(olga, anim)
    local animGamble = not anim and Util.MiniAnimVariants[math.random(#Util.MiniAnimVariants)] or Util.MiniAnimVariants[anim]
    Util:SetAnimation(olga, animGamble[1] .. animGamble[2][math.random(#animGamble[2])], true)
end

---@param olga EntityFamiliar
function Util:DoIdleAnim(olga)
end