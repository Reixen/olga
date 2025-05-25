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
---@param distance number
function Util:IsWithin(olga, distance)
    return olga.Player.Position:DistanceSquared(olga.Position) < distance ^ 2
end

---@param olga EntityFamiliar
function Util:CanIdleAnimation(olga)
    return olga.State ~= Util.DogState.OBTAIN and olga.State ~= Util.DogState.RETRIEVE
end

---@param anim string
function Util:CanWag(anim)
    return anim == Util.HeadAnim.HAPPY or anim == Util.HeadAnim.PETTING
end

---@param olga EntityFamiliar
function Util:DoIdleAnim(olga)
end