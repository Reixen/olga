--#region Variables
local Mod = OlgaMod

local FeedingBowl = {}
OlgaMod.FeedingBowl = FeedingBowl

local game = Mod.Game
local sfxMan = Mod.SfxMan
local Util = Mod.Util

FeedingBowl.BOWL_VARIANT = Isaac.GetEntityVariantByName("Feeding Bowl")
FeedingBowl.BOWL_SFX = Isaac.GetSoundIdByName("Olga Bark")
FeedingBowl.POUR_SFX = Isaac.GetSoundIdByName("Olga Bark")

FeedingBowl.CONSUMABLE_DINNER_ID = Isaac.GetNullItemIdByName("Consumable Dinner")
FeedingBowl.CONSUMABLE_DESSERT_ID = Isaac.GetNullItemIdByName("Consumable Dessert")
FeedingBowl.CONSUMABLE_SNACK_ID = Isaac.GetNullItemIdByName("Consumable Snack")
FeedingBowl.CONSUMABLE_GENERIC_ID = Isaac.GetNullItemIdByName("Consumable Generic")

FeedingBowl.CollectibleToNullFX = {
    [CollectibleType.COLLECTIBLE_NULL] = FeedingBowl.CONSUMABLE_GENERIC_ID,
    [CollectibleType.COLLECTIBLE_DINNER] = FeedingBowl.CONSUMABLE_DINNER_ID,
    [CollectibleType.COLLECTIBLE_DESSERT] = FeedingBowl.CONSUMABLE_DESSERT_ID,
    [CollectibleType.COLLECTIBLE_SNACK] = FeedingBowl.CONSUMABLE_SNACK_ID
}

FeedingBowl.PICKUP_CHANCE = 1 / 2

--#endregion
--#region Feeding Bowl Callbacks
function FeedingBowl:OnRoomClear()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local rng = familiar:ToFamiliar():GetDropRNG()

        if rng:RandomFloat() < FeedingBowl.PICKUP_CHANCE then
            local data = familiar:GetData() ---@cast data DogData

            if data.hasBowl == nil then
                local room = Mod.Room()
                local spawnPos = room:FindFreePickupSpawnPosition(room:GetCenterPos())
                Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Mod.Pickup.FEEDING_KIT_ID, spawnPos, Vector.Zero, nil)
                data.hasBowl = true
            end
            break
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, FeedingBowl.OnRoomClear)

---@param player EntityPlayer
function FeedingBowl:OnConsumableUse(_, player)
    local bowl = Isaac.Spawn(EntityType.ENTITY_SLOT, FeedingBowl.BOWL_VARIANT, 0,
        Mod.Room():FindFreePickupSpawnPosition(player.Position, 60, true), Vector.Zero, player):ToSlot()
    bowl:GetSprite():Play("Spawn")
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, bowl.Position, Vector.Zero, bowl)
    player:AddNullItemEffect(FeedingBowl.GENERIC_FOOD_ID, false)
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, FeedingBowl.OnConsumableUse, Mod.Pickup.FEEDING_KIT_ID)

---@param bowl EntitySlot
function FeedingBowl:OnBowlInit(bowl)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, FeedingBowl.OnBowlInit, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlUpdate(bowl)
    local sprite = bowl:GetSprite()

    if sprite:IsFinished() then
        sprite:Play("Idle")
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, FeedingBowl.OnBowlUpdate, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
---@param collider Entity
function FeedingBowl:OnBowlCollision(bowl, collider)
    if collider.Type ~= EntityType.ENTITY_PLAYER then return end

    local sprite = bowl:GetSprite()
    if not sprite:GetAnimation() == "Idle"
    or not sprite:IsFinished() then
        return
    end

    local player = collider:ToPlayer() ---@cast player EntityPlayer
    local tempFX = player:GetEffects()

    local yummers = FeedingBowl:HasFoodItems(tempFX)
    if not yummers then
        return
    end

    FeedingBowl:PlayFillAnimation(tempFX, sprite, yummers)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, FeedingBowl.OnBowlCollision, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlDeath(bowl)
    sfxMan:Play(SoundEffect.SOUND_POT_BREAK)
    bowl:Remove()
    return false
end
Mod:AddCallback(ModCallbacks.MC_PRE_SLOT_CREATE_EXPLOSION_DROPS, FeedingBowl.OnBowlDeath, FeedingBowl.BOWL_VARIANT)

---@param collType CollectibleType
---@param firstTime boolean
---@param player EntityPlayer
function FeedingBowl:OnCollectiblePickup(collType, _, firstTime, _, _, player)
    if firstTime then
        player:GetEffects():AddNullEffect(FeedingBowl.CollectibleToNullFX[collType])
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, FeedingBowl.OnCollectiblePickup, CollectibleType.COLLECTIBLE_DINNER)
Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, FeedingBowl.OnCollectiblePickup, CollectibleType.COLLECTIBLE_DESSERT)
Mod:AddCallback(ModCallbacks.MC_POST_ADD_COLLECTIBLE, FeedingBowl.OnCollectiblePickup, CollectibleType.COLLECTIBLE_SNACK)

--#endregion
--#region Feeding Bowl Helper Functions
---@return table[] | false
---@param tempFX TemporaryEffects
function FeedingBowl:HasFoodItems(tempFX)
    local yumYumTable = {}
    for _, nullFX in pairs(FeedingBowl.CollectibleToNullFX) do
        if tempFX:HasNullEffect(nullFX) then
            yumYumTable[#yumYumTable + 1] = nullFX
        end
    end
    return #yumYumTable > 0 and yumYumTable or false
end

---@param tempFX TemporaryEffects
---@param sprite Sprite
---@param foodItems table
function FeedingBowl:PlayFillAnimation(tempFX, sprite, foodItems)
    for _, nullFX in pairs(foodItems) do
        local name = Isaac.GetItemConfig():GetNullItem(nullFX).Name
        name = name:gsub("Consumable ", "")

        sprite:Play("Fill" .. name)
        tempFX:RemoveNullEffect(nullFX)
        return
    end
end
--#endregion