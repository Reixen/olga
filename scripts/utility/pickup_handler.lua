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
local Trinket = PickupHandler.Pickup[PickupVariant.PICKUP_TRINKET]
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
PickupHandler.ROTG_CHANCE = 1 / 25

--#endregion
--#region Pickup Handler Anti-Gameplay Callbacks
---@param pickup EntityPickup
function PickupHandler:PrePickupMorph(pickup)
    if not PickupHandler:IsOlgaModPickup(pickup) then
        return
    end

    local rng = pickup:GetDropRNG()
    local potentialDrops = PickupHandler:EvaluatePotentialDrops()
    local validDrops = {}

    potentialDrops["Misc"] = potentialDrops["Misc"] or {}
    potentialDrops["Misc"][#potentialDrops["Misc"]+1] = Trinket.CRUDE_DRAWING_ID

    for dropType, _ in pairs(potentialDrops) do
        validDrops[#validDrops+1] = dropType
    end

    local dropType = validDrops[rng:RandomInt(#validDrops) + 1]
    local subtype = potentialDrops[dropType][rng:RandomInt(#potentialDrops[dropType]) + 1]
    local variant = (dropType == "Misc" and subtype == Trinket.CRUDE_DRAWING_ID) and PickupVariant.PICKUP_TRINKET or PickupVariant.PICKUP_TAROTCARD

    if subtype == Consumables.STICK_ID then
        subtype = rng:RandomFloat() < PickupHandler.ROTG_CHANCE and Consumables.ROD_OF_THE_GODS_ID or Consumables.STICK_ID
    end

    return {EntityType.ENTITY_PICKUP, variant, subtype}
end
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_MORPH, PickupHandler.PrePickupMorph)

---@param pickup EntityPickup
function PickupHandler:PrePickupConsumed(pickup)
    if PickupHandler:IsOlgaModPickup(pickup) then
        return false
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COMPOSTED, PickupHandler.PrePickupConsumed, PickupVariant.PICKUP_TAROTCARD)
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COMPOSTED, PickupHandler.PrePickupConsumed, PickupVariant.PICKUP_TRINKET)

Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_VOIDED, PickupHandler.PrePickupConsumed, PickupVariant.PICKUP_TAROTCARD)
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_VOIDED, PickupHandler.PrePickupConsumed, PickupVariant.PICKUP_TRINKET)

---@param player EntityPlayer
function PickupHandler:PreAceCardUse(_, player)
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

---@param player EntityPlayer
function PickupHandler:OnAceCardUse(_, player)
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
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.OnAceCardUse, Card.CARD_ACE_OF_CLUBS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.OnAceCardUse, Card.CARD_ACE_OF_DIAMONDS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.OnAceCardUse, Card.CARD_ACE_OF_HEARTS)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, PickupHandler.OnAceCardUse, Card.CARD_ACE_OF_SPADES)

---@param player EntityPlayer
function PickupHandler:PreD1Use(_, _, player)
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
Mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, PickupHandler.PreD1Use, CollectibleType.COLLECTIBLE_D1)

---@param player EntityPlayer
function PickupHandler:OnD1Use(_, _, player)
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
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, PickupHandler.OnD1Use, CollectibleType.COLLECTIBLE_D1)
--#endregion
--#region Pickup Handler Callbacks
function PickupHandler:OnPickupCollect()
    Isaac.CreateTimer(function()
        sfxMan:Stop(SoundEffect.SOUND_BOOK_PAGE_TURN_12)
    end, 1, 1, true)
    sfxMan:Play(SoundEffect.SOUND_SHELLGAME)
end
---@param modCallback ModCallbacks
---@param functionToUse function
---@param variant PickupVariant
function PickupHandler:RegisterCallbacks(modCallback, functionToUse, variant)
    for _, pickupId in pairs(PickupHandler.Pickup[variant]) do
        Mod:AddCallback(modCallback, functionToUse, pickupId)
    end
end
PickupHandler:RegisterCallbacks(ModCallbacks.MC_POST_PLAYER_COLLECT_CARD, PickupHandler.OnPickupCollect, PickupVariant.PICKUP_TAROTCARD)

function PickupHandler:SpawnPickup(rng)
    local pickupChance = PickupHandler.PICKUP_CHANCE / (PlayerManager.AnyoneHasTrinket(Trinket.CRUDE_DRAWING_ID) and 2 or 1)
    if rng:PhantomFloat() > pickupChance then
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
        local dropType = validDrops[rng:PhantomInt(#validDrops) + 1]
        local subtype = potentialDrops[dropType][rng:PhantomInt(#potentialDrops[dropType]) + 1]

        if subtype == Consumables.STICK_ID then
            subtype = rng:PhantomFloat() < PickupHandler.ROTG_CHANCE and Consumables.ROD_OF_THE_GODS_ID or Consumables.STICK_ID
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
    -- Copy the table
    for k, v in pairs(PickupHandler.BaseDrops) do
        for _, tableVal in ipairs(v) do
            if not potentialDrops[k] then
                potentialDrops[k] = {}
            end
            potentialDrops[k][#potentialDrops[k]+1] = tableVal
        end
        dropTypeAmount = dropTypeAmount + 1
    end

    -- Add drops that were unlocked by the player
    for string, unlockableDrops in pairs(PickupHandler.UnlockableDrops) do
        for _, table in ipairs(unlockableDrops) do
            local gameData = Isaac.GetPersistentGameData()
            if gameData:Unlocked(table.AchievementRequirement) then
                if not potentialDrops[string] then
                    potentialDrops[string] = {}
                    dropTypeAmount = dropTypeAmount + 1
                end
                potentialDrops[string][#potentialDrops[string]+1] = table.Drop
            end
        end
    end
    return potentialDrops, dropTypeAmount
end
--#endregion