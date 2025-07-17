--#region Variables
local Mod = OlgaMod

local Util = {}
OlgaMod.Util = Util

local saveMan = Mod.SaveManager
Util.DATA_IDENTIFIER = "olgaMod"

Util.HAPPY_COLLECTIBLE = CollectibleType.COLLECTIBLE_NUMBER_ONE
Util.SPRITESHEET_SUBSTRING_IDX = 6

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
    TILT_LEFT_TO_IDLE = "TiltLeftToIdle",
    TILT_RIGHT_TO_IDLE = "TiltRightToIdle",
    -- Mini Idle Animations
    EAR_FLICK_L = "EarFlick_Left",
    EAR_FLICK_R = "EarFlick_Right",
    EAR_FLICK_BOTH = "EarFlick_Both",
    EAR_ROTATE_L = "EarRotate_Left",
    EAR_ROTATE_R = "EarRotate_Right",
    EAR_ROTATE_BOTH = "EarRotate_Both",
    TILT_LEFT = "Tilt_Left",
    TILT_SWITCH_LEFT = "TiltSwitch_Left",
    TILT_RIGHT = "Tilt_Right",
    TILT_SWITCH_RIGHT = "TiltSwitch_Right",
    -- Idle Animations
    BARK = "Bark",
    YAWN = "Yawn",
    SNIFF = "Sniff",
    EAT_1 = "Eat1",
    EAT_2 = "Eat2",
    EAT_3 = "Eat3",
    EAT_DINNER = "EatDinner"
}

Util.BodyAnim = {
    SIT = "Sit",
    SIT_WAGGING = "SitWagging",
    STAND = "Stand",
    WALKING = "Walking",
    RUNNING = "Running",
    RIDING = "Riding",
    -- Transitionals
    SIT_TO_STAND = "SitToStand",
    STAND_TO_SIT = "StandToSit",
    SIT_TO_SCRATCHING = "SitToScratching",
    SCRATCHING_TO_SIT = "ScratchingToSit",
    RUNNING_TO_RIDING = "RunningToRiding",
    -- Idle Animations
    PLAYFUL_1 = "Playful1",
    PLAYFUL_2 = "Playful2",
    SCRATCHING = "Scratching",
}

---@enum DogState
Util.DogState = {
    SITTING = 0,
    STANDING = 1,
    FETCH = 2,
    RETURN = 3,
    WHISTLED = 4,
    PRONE = 5, --Unused
    APPROACH_BOWL = 6,
    EATING = 7,
}

Util.ModdedHands = {} -- See patches

-- Used for shaders
Util.HeadLayerId = {
    1, -- Head
    2, -- HeadPart1
    3, -- HeadPart2
    4, -- HeldObject (Head)
}

Util.Achievements = {
    TENNIS_BALL =       {ID = Isaac.GetAchievementIdByName("Tennis Ball"),      Requirement = 5},
    WHISTLE =           {ID = Isaac.GetAchievementIdByName("Whistle"),          Requirement = 10},
    FUR_COLORS =        {ID = Isaac.GetAchievementIdByName("Fur Colors"),       Requirement = 20}
}

--#endregion
--#region Callbacks
function Util:OnReviveOrClicker()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        Util:UpdateHandColor(olga.Player, olga:GetData().headSprite, GetPtrHash(olga))
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, Util.OnReviveOrClicker, CollectibleType.COLLECTIBLE_CLICKER)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, Util.OnReviveOrClicker)

---@param slot EntitySlot
function Util:OnDressingTable(slot)
    local touch = slot:GetTouch()
    local gameData = Isaac.GetPersistentGameData()
    if not gameData:Unlocked(Util.Achievements.FUR_COLORS.ID)
    or (touch ~= 0 and touch % 15 ~= 0) then
        return
    end

    local persistentSave = saveMan.GetPersistentSave()
    persistentSave.furColor = persistentSave.furColor or 0 -- If it doesn't exist, set to default
    persistentSave.furColor = persistentSave.furColor >= 3 and 0 or persistentSave.furColor + 1

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        local sprite = olga:GetSprite()

        Util:ApplyColorPalette(sprite, "olga_shader", persistentSave.furColor)
        Util:ApplyColorPalette(olga:GetData().headSprite, "olga_shader", persistentSave.furColor, Util.HeadLayerId)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, olga.Position, Vector.Zero, olga)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, Util.OnDressingTable, SlotVariant.MOMS_DRESSING_TABLE)
--#endregion
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
--#endregion
--#region Helper Functions
-- Update the petting hand color based on the player's skin
---@param player EntityPlayer
---@param sprite Sprite
---@param ptrHash integer
function Util:UpdateHandColor(player, sprite, ptrHash)
    local playerColor = player:GetBodyColor()
    local playerType = player:GetPlayerType()
    local data = Mod.Util:GetData(player, Mod.Util.DATA_IDENTIFIER)
    data[ptrHash] = data[ptrHash] or {}
    local handData = data[ptrHash]

    if handData.pColor and handData.pColor == playerColor
    and handData.pType and handData.pType == playerType then
        return
    end

    for string, value in pairs(SkinColor) do
        local colorStr = string:sub(Util.SPRITESHEET_SUBSTRING_IDX, -1)

        if playerColor == value then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/hand_" .. colorStr .. ".png")
            break
        end
    end

    for _, modTable in ipairs(Util.ModdedHands) do
        if not modTable.PlayerTypeTable then
            goto skip
        end

        for _, pTypeString in ipairs(modTable.PlayerTypes) do
            if playerType == modTable.PlayerTypeTable[pTypeString]
            or GIMP and modTable.PlayerTypeTable == GIMP.CHARACTER and playerType == modTable.PlayerTypeTable[pTypeString].ID then
                sprite:ReplaceSpritesheet(0, "gfx/petting_hands/".. modTable.FileString .."/hand_" .. pTypeString .. ".png")
                goto finish
            end
        end
        ::skip::
    end

    ::finish::
    sprite:LoadGraphics()
    if playerType == PlayerType.PLAYER_THESOUL
    or playerType == PlayerType.PLAYER_THESOUL_B then
        local handLayer = sprite:GetLayer(0) -- Petting hand layer
        handLayer:SetColor(player.Color)
    end
    handData.pColor = playerColor
    handData.pType = playerType
end

---@param sprite Sprite
---@param paletteName string
---@param colorPalette integer
---@param layerIDs table?
function Util:ApplyColorPalette(sprite, paletteName, colorPalette, layerIDs)
    local palettePath = "shaders/" .. paletteName .. "/" .. paletteName .. colorPalette

    local applyShader = function(spriteToUse)
        if not spriteToUse:HasCustomShader(palettePath) and colorPalette > 0 then
            spriteToUse:SetCustomShader(palettePath)
        elseif colorPalette <= 0 then
            spriteToUse:ClearCustomShader()
        end
    end

    if layerIDs then
        for _, layerID in ipairs(layerIDs) do
            local spriteToApply = sprite:GetLayer(layerID)
            applyShader(spriteToApply)
        end
        return
    end
    applyShader(sprite)
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
---@param idleAnim function?
---@param miniIdleAnim function?
function Util:FillEmptyAnimFunctions(enums, animFunc, transitionAnim, idleAnim, miniIdleAnim)
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
    return Util:IsFetching(olga) or Util:IsEating(olga) or olga.State == Util.DogState.WHISTLED
end

---@param idxTable table
---@param bowl EntitySlot | Vector
function Util:RemoveBowlIndex(idxTable, bowl)
    if not bowl then
        return
    end
    for i, gridIdx in ipairs(idxTable) do
        if Mod.Room():GetGridIndex(bowl.Position or bowl) == gridIdx then
            table.remove(idxTable, i)
            break
        end
    end
end

---@param sprite Sprite
---@param player EntityPlayer
---@param animName string
function Util:EndPettingAnimation(sprite, player, animName)
    local pettingVariant, _ = string.find(animName, Util.HeadAnim.GLAD)
    local animTransition = pettingVariant and Util.HeadAnim.GLAD_PETTING_TO_GLAD or Util.HeadAnim.PETTING_TO_IDLE
    sprite:Play(animTransition, true)

    Util:TryTurningPlayerSad(player)
end

---@param player EntityPlayer
function Util:TryTurningPlayerSad(player)
    if not player:HasCollectible(Util.HAPPY_COLLECTIBLE)
    and player:IsCollectibleCostumeVisible(Util.HAPPY_COLLECTIBLE, "head") then
        local itemCfg = Isaac.GetItemConfig():GetCollectible(Util.HAPPY_COLLECTIBLE)
        player:RemoveCostume(itemCfg)
    end
end

---@param points integer
function Util:EvaluatePoints(points)
    for _, ach in pairs(Util.Achievements) do
        local gameData = Isaac.GetPersistentGameData()
        if not gameData:Unlocked(ach.ID)
        and points >= ach.Requirement then
            gameData:TryUnlock(ach.ID)
        end
    end
end

---@param saveTable table
---@param hash integer
---@param remove boolean?
function Util:DoesSeedExist(saveTable, hash, remove)
    if not saveTable then
        return false
    end
    for pos, hashVal in ipairs(saveTable) do
        if hash == hashVal then
            if remove == true then
                table.remove(saveTable, pos)
            end
            return true
        end
    end
    return false
end
--endregion