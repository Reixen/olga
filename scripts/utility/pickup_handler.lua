--#region Pickup Handler Variables
local Mod = OlgaMod

local PickupHandler = {}
OlgaMod.PickupHandler = PickupHandler

local sfxMan = Mod.SfxMan
local Util = Mod.Util
local saveMan = Mod.SaveManager

PickupHandler.Pickup = {
    [PickupVariant.PICKUP_TAROTCARD] = {
        STICK_ID = Isaac.GetCardIdByName("Stick"),
        FEEDING_KIT_ID = Isaac.GetCardIdByName("Feeding Kit"),
        TENNIS_BALL_ID = Isaac.GetCardIdByName("Tennis Ball"),
        ROD_OF_THE_GODS_ID = Isaac.GetCardIdByName("Rod of the Gods"),
        WHISTLE_ID = Isaac.GetCardIdByName("Whistle")
    },
    [PickupVariant.PICKUP_TRINKET] = {
        CRUDE_DRAWING_ID = Isaac.GetTrinketIdByName("Crude Drawing"),
    }
}

local Consumables = PickupHandler.Pickup[PickupVariant.PICKUP_TAROTCARD]
PickupHandler.BaseDrops = {
    ["FetchingObject"] = {
        Consumables.STICK_ID
    },
    ["Progression"] = {
        Consumables.FEEDING_KIT_ID
    }
}

PickupHandler.UnlockableDrops = {
    ["FetchingObject"] = {
        {AchievementRequirement = Util.Achievements.TENNIS_BALL.ID, Drop = Consumables.TENNIS_BALL_ID}
    },
    ["Misc"] = {
        {AchievementRequirement = Util.Achievements.WHISTLE.ID,     Drop = Consumables.WHISTLE_ID}
    }
}

PickupHandler.PICKUP_CHANCE = 2 / 5
PickupHandler.ROTG_CHANCE = 1 / 20

--#endregion
--#region Pickup Handler Anti-Gameplay Callbacks
---@param pickup EntityPickup
function PickupHandler:PrePickupMorph(pickup)
    if PickupHandler:IsOlgaModPickup(pickup) then
        return false
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_MORPH, PickupHandler.PrePickupMorph)

Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COMPOSTED, PickupHandler.PrePickupMorph, PickupVariant.PICKUP_TAROTCARD)
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COMPOSTED, PickupHandler.PrePickupMorph, PickupVariant.PICKUP_TRINKET)

Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_VOIDED, PickupHandler.PrePickupMorph, PickupVariant.PICKUP_TAROTCARD)
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_VOIDED, PickupHandler.PrePickupMorph, PickupVariant.PICKUP_TRINKET)

---@param cardID Card
---@param player EntityPlayer
function PickupHandler:PreAceCardUse(cardID, player)
    local data = Util:GetData(player, Util.DATA_IDENTIFIER)
    data.olgaPickupData = {}
    for _, entity in ipairs(Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
        local pickup = entity:ToPickup() ---@cast pickup EntityPickup

        if PickupHandler:IsOlgaModPickup(pickup) then
            data.olgaPickupData[#data.olgaPickupData+1] = {
                Position = pickup.Position,
                Variant = pickup.Variant,
                Subtype = pickup.SubType
            }
            pickup:Remove()
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, PickupHandler.PreAceCardUse, Card.CARD_ACE_OF_CLUBS)
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, PickupHandler.PreAceCardUse, Card.CARD_ACE_OF_DIAMONDS)
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, PickupHandler.PreAceCardUse, Card.CARD_ACE_OF_HEARTS)
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, PickupHandler.PreAceCardUse, Card.CARD_ACE_OF_SPADES)

---@param cardID Card
---@param player EntityPlayer
function PickupHandler:PostAceCardUse(cardID, player)
    local data = Util:GetData(player, Util.DATA_IDENTIFIER)
    if not data.olgaPickupData or #data.olgaPickupData < 1 then
        return
    end

    local idleFrame = 40
    for _, pickupData in ipairs(data.olgaPickupData) do
        local olgaModPickup = Isaac.Spawn(EntityType.ENTITY_PICKUP, pickupData.Variant, pickupData.Subtype, pickupData.Position, Vector.Zero, nil):ToPickup()
        local sprite = olgaModPickup:GetSprite()
        sprite:SetFrame(idleFrame)
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.PostAceCardUse, Card.CARD_ACE_OF_CLUBS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.PostAceCardUse, Card.CARD_ACE_OF_DIAMONDS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.PostAceCardUse, Card.CARD_ACE_OF_HEARTS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.PostAceCardUse, Card.CARD_ACE_OF_SPADES)
--#endregion
--#region Pickup Handler Callbacks
function PickupHandler:OnPickupCollect()
    Isaac.CreateTimer(function()
        sfxMan:Stop(SoundEffect.SOUND_BOOK_PAGE_TURN_12)
    end, 1, 1, true)
    sfxMan:Play(SoundEffect.SOUND_SHELLGAME)
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, Consumables.STICK_ID)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, Consumables.TENNIS_BALL_ID)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, Consumables.FEEDING_KIT_ID)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, Consumables.ROD_OF_THE_GODS_ID)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, Consumables.WHISTLE_ID)

---@param roomRNG RNG
function PickupHandler:SpawnPickup(roomRNG)
    local rng = RNG()
    rng:SetSeed(roomRNG:GetSeed())
    if rng:RandomFloat() > PickupHandler.PICKUP_CHANCE then
        return
    end

    local floorSave = saveMan.TryGetFloorSave()
    if not floorSave or not floorSave.obtainedDrops then
        return
    end

    -- End it early when theres no valid drops
    local potentialDrops, dropTypeAmount = PickupHandler:EvaluatePotentialDrops()
    if dropTypeAmount == #floorSave.obtainedDrops then
        return
    end

    -- Create a new table for determining if the pickup can be spawned
    local validDrops = {}
    for dropType, _ in pairs(potentialDrops) do
        validDrops[#validDrops+1] = dropType
    end

    local typeCounter = dropTypeAmount
    while 0 < typeCounter do
        local dropType = validDrops[typeCounter]
        for _, invalidDrop in ipairs(floorSave.obtainedDrops) do
            if invalidDrop == dropType then
                table.remove(validDrops, typeCounter) -- Removes valid drop at that position
                break
            end
        end
        typeCounter = typeCounter - 1
    end

    if #Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT) > 0 then
        local dropType = validDrops[rng:RandomInt(#validDrops) + 1]
        local subtype = potentialDrops[dropType][rng:RandomInt(#potentialDrops[dropType]) + 1]

        if subtype == Consumables.STICK_ID then
            subtype = rng:RandomFloat() < PickupHandler.ROTG_CHANCE and Consumables.ROD_OF_THE_GODS_ID or Consumables.STICK_ID
        end

        floorSave.obtainedDrops[#floorSave.obtainedDrops+1] = dropType

        local room = Mod.Room()
        local spawnPos = room:FindFreePickupSpawnPosition(room:GetCenterPos())
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, subtype, spawnPos, Vector.Zero, nil)
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, PickupHandler.SpawnPickup)

--#endregion
--#region Pickup Handler Helper Functions
---@param pickup EntityPickup
function PickupHandler:IsOlgaModPickup(pickup)
    for pickupVariant, pickups in pairs(PickupHandler.Pickup) do
        for _, id in pairs(pickups) do
            if pickup.Variant == pickupVariant and pickup.SubType == id then
                return true
            end
        end
    end
    return false
end

---@return table, integer
function PickupHandler:EvaluatePotentialDrops()
    local potentialDrops = {}
    local dropTypeAmount = 0
    for k, v in pairs(PickupHandler.BaseDrops) do
        potentialDrops[k] = v
        dropTypeAmount = dropTypeAmount + 1
    end

    for string, unlockableDrops in pairs(PickupHandler.UnlockableDrops) do
        local gameData = Isaac.GetPersistentGameData()
        if not potentialDrops[string] then
            potentialDrops[string] = {}
            dropTypeAmount = dropTypeAmount + 1
        end
        for _, table in ipairs(unlockableDrops) do
            if gameData:Unlocked(table.AchievementRequirement) then
                potentialDrops[string][#potentialDrops[string]+1] = table.Drop
            end
        end
    end

    return potentialDrops, dropTypeAmount
end
--#endregion