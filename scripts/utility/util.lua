--#region Variables
local Mod = OlgaMod

local Util = {}
OlgaMod.Util = Util

local sfxMan = Mod.SfxMan

Util.ID = "olgaMod"

Util.HeadAnim= {
    IDLE = "Idle",
    GLAD = "Glad",
    GLAD_PETTING = "GladPetting",
    PETTING = "Petting",
    GRAB = "Grab",
    HOLD = "Hold",
    -- Transition Animations
    GLAD_TO_IDLE = "GladToIdle",
    IDLE_TO_GLAD = "IdleToGlad",
    GLAD_TO_GLAD_PETTING = "GladToGladPetting",
    GLAD_PETTING_TO_GLAD = "GladPettingToGlad",
    IDLE_TO_PETTING = "IdleToPetting",
    PETTING_TO_IDLE = "PettingToIdle",
    HOLD_TO_IDLE = "HoldToIdle",
    -- Mini Idle Animations
    EAR_FLICK_L = "EarFlick_Left",
    EAR_FLICK_R = "EarFlick_Right",
    EAR_FLICK_BOTH = "EarFlick_Both",
    EAR_ROTATE_L = "EarRotate_Left",
    EAR_ROTATE_R = "EarRotate_Right",
    EAR_ROTATE_BOTH = "EarRotate_Both",
    -- Idle Animations
    BARK = "Bark",
    YAWN = "Yawn",
}

Util.BodyAnim = {
    SIT = "Sit",
    SIT_WAGGING = "SitWagging",
    STAND = "Stand",
    WALKING = "Walking",
    PLAYFUL = "Playful",
    -- Transitionals
    SIT_TO_STAND = "SitToStand",
    STAND_TO_SIT = "StandToSit",
}

---@enum DogState
Util.DogState = {
    SITTING = 0,
    STANDING = 1,
    FETCH = 2,
    RETURN = 3,
    ANTICIPATE = 4,
    PRONE = 5,
    APPROACH_BOWL = 6,
    EATING = 7,
}

local ONE_SEC = 30
Util.ANIM_COOLDOWN = ONE_SEC * 5
Util.ATTENTION_COOLDOWN = ONE_SEC * 60

Util.SPRITESHEET_SUBSTRING_IDX = 6

Util.ModdedHands = {
    "MAGDALENE",
    "EDEN",
    "BLUEBABY",
    "SAMSON",
    "KEEPER"
}
--#endregion
--#region Callbacks
function Util:OnReviveOrClicker()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        Util:UpdateHandColor(olga.Player, olga:GetData().headSprite)
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, Util.OnReviveOrClicker, CollectibleType.COLLECTIBLE_CLICKER)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, Util.OnReviveOrClicker)

--local PriceTextFontTempesta = Font()
--PriceTextFontTempesta:Load("font/pftempestasevencondensed.fnt")

--local function effectRender(effect)
    --local pos = Isaac.WorldToScreen(effect.Position)
    --PriceTextFontTempesta:DrawStringScaled(
            --effect.Type.."."..effect.Variant.."."..effect.SubType,
            --pos.X,
            --pos.Y,
            --0.75, 0.75, -- scale
            --KColor(1, 1, 1, 1)
        --)
--end

--local function renderEffects(_, effect)
    --if not effect then
        --for index, value in ipairs(Isaac.GetRoomEntities()) do
            --effectRender(value)
        --end
    --else
        --effectRender(effect)
    --end
--end

--Mod:AddCallback(ModCallbacks.MC_POST_RENDER, renderEffects)
---@param pickup EntityPickup
function Util:PrePickupMorph(pickup)
    if pickup.Type ~= EntityType.ENTITY_PICKUP then return end

    if pickup.Variant == PickupVariant.PICKUP_TAROTCARD then
        if pickup.SubType == Mod.Pickup.STICK_ID
        or pickup.SubType == Mod.Pickup.FEEDING_KIT_ID
        or pickup.SubType == Mod.Pickup.TENNIS_BALL_ID
        or pickup.SubType == Mod.Pickup.ROD_OF_THE_GODS_ID then
            return false
        end
    elseif pickup.Variant == PickupVariant.PICKUP_TRINKET
    and pickup.SubType == Mod.Pickup.CRUDE_DRAWING_ID then
        return false
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_MORPH, Util.PrePickupMorph)

---@param pickup EntityPickup
---@param collider Entity
function Util:OnPickupCollision(pickup, collider)
    if (pickup.SubType ~= Mod.Pickup.STICK_ID and pickup.SubType ~= Mod.Pickup.TENNIS_BALL_ID
    and pickup.SubType ~= Mod.Pickup.FEEDING_KIT_ID and pickup.SubType ~= Mod.Pickup.ROD_OF_THE_GODS_ID)
    or collider.Type ~= EntityType.ENTITY_PLAYER then
        return
    end

    if sfxMan:IsPlaying(SoundEffect.SOUND_BOOK_PAGE_TURN_12)
    and collider:ToPlayer():IsHoldingItem() then
        sfxMan:Stop(SoundEffect.SOUND_BOOK_PAGE_TURN_12)
        sfxMan:Play(SoundEffect.SOUND_SHELLGAME)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PICKUP_COLLISION, Util.OnPickupCollision, PickupVariant.PICKUP_TAROTCARD)
--#endregion
--#region Helper Functions
-- Update the petting hand color based on the player's skin
---@param player EntityPlayer
---@param sprite Sprite
function Util:UpdateHandColor(player, sprite)
    local playerColor = player:GetBodyColor()
    local playerType = player:GetPlayerType()
    local data = Mod.Util:GetData(player, Mod.Util.ID)

    if data.pColor and data.pColor == playerColor
    or (data.pType and data.pType == playerType) then
        return
    end

    for string, value in pairs(SkinColor) do
        local colorStr = string:sub(Util.SPRITESHEET_SUBSTRING_IDX, -1)

        if playerColor == value then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_" .. colorStr .. ".png")
            break
        end
    end

    if Epiphany then
        local EPlayer = Epiphany and Epiphany.PlayerType or nil
        if playerType == EPlayer.JUDAS
        or playerType == EPlayer.JUDAS4
        or playerType == EPlayer.JUDAS5 then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_shadow.png")
            goto finish
        elseif playerType == EPlayer.JUDAS2 
            or playerType == EPlayer.JUDAS1 then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_judas_angel.png")
            goto finish
        end

        for _, moddedString in pairs(Util.ModdedHands) do
            local fileName = moddedString:lower()
            if playerType == EPlayer[moddedString] then
                sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_tr_" .. fileName .. ".png")
                break
            end
        end
    end

    ::finish::
    sprite:LoadGraphics()
    data.pColor = playerColor
    data.pType = playerType
end

-- Returns a boolean if olga is near the target. DistanceSquared is faster I heard.
---@param olga EntityFamiliar
---@param target Vector
---@param distance number
function Util:IsWithin(olga, target, distance)
    return olga.Position:DistanceSquared(target) < distance ^ 2
end

-- Creates a unique table to make it less likely for mods to edit your variables.
-- Special thanks to Kerkel
---@param entity Entity
---@param identifier any
---@param default any?
function Util:GetData(entity, identifier, default)
    local data = entity:GetData()
    data._OlgaMod = data._OlgaMod or {}
    data._OlgaMod[identifier] = data._OlgaMod[identifier] or default or {}
    return data._OlgaMod[identifier]
end

-- Adds an underscore if the name's pascal case formatting has more than two words
-- It turns the string into an uppercase string to be used for the enum table.
---@param animName string
function Util:ToEnumName(animName)
    local endString = ""

    for i = 1, #animName do
        local char = animName:sub(i, i)

        if char:match("%u")
        and i ~= 1 then
            endString = endString .. "_" .. char
        else
            endString = endString .. char
        end
    end

    return endString:upper()
end

-- System that automatically fills in the missing animation functions
---@param enums table
---@param animFunc table
---@param transitionAnim function
---@param miniIdleAnim function?
---@param idleAnim function?
function Util:FillEmptyAnimFunctions(enums, animFunc, transitionAnim, miniIdleAnim, idleAnim)
    for _, enumName in pairs(enums) do
        if animFunc[enumName] then
            goto skip
        end

        local isTransition = string.find(enumName, "To")

        if isTransition then
            animFunc[enumName] = transitionAnim
            goto skip
        end

        if not miniIdleAnim and not idleAnim then
            goto skip
        end

        local isMiniIdle = string.find(enumName, "_")

        if isMiniIdle then
            animFunc[enumName] = miniIdleAnim
            goto skip
        end

        animFunc[enumName] = idleAnim

        ::skip::
    end
end

---Returns the animation substring used for transitionals or repeating mini idles
---@param animName string
---@param isMiniIdle boolean?
function Util:FindAnimSubstring(animName, isMiniIdle)
    if isMiniIdle then
        local start = string.find(animName, "_")
        return string.sub(animName, 1, start - 1)
    end

    local _, terminal = string.find(animName, "To")
    local subString = string.sub(animName, terminal + 1, #animName)
    return Util:ToEnumName(subString)
end

---@param olga EntityFamiliar
function Util:IsFetching(olga)
    return olga.State == Util.DogState.FETCH or olga.State == Util.DogState.RETURN
end

-- Special thanks to Epiphany
function Util:IsInStartingRoom()
    local level = Mod.Level()
    return level:GetStage() == LevelStage.STAGE1_1
    and level:GetCurrentRoomIndex() == level:GetStartingRoomIndex()
    and level:GetStageType() ~= StageType.STAGETYPE_REPENTANCE
    and level:GetStageType() ~= StageType.STAGETYPE_REPENTANCE_B
end

---@param olga EntityFamiliar
function Util:IsEating(olga)
    return olga.State == Util.DogState.APPROACH_BOWL or olga.State == Util.DogState.EATING
end

---@param olga EntityFamiliar
function Util:IsBusy(olga)
    return Util:IsFetching(olga) or Util:IsEating(olga)
end

---@param idxTable table
---@param bowl EntitySlot
function Util:RemoveBowlIndex(idxTable, bowl)
    for i, gridIdx in ipairs(idxTable) do
        if Mod.Room():GetGridIndex(bowl.Position) == gridIdx then
            table.remove(idxTable, i)
            break
        end
    end
end
--endregion