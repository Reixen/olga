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

FeedingBowl.CONSUMED_DINNER_ID = Isaac.GetNullItemIdByName("Consumed Dinner")
FeedingBowl.CONSUMED_DESSERT_ID = Isaac.GetNullItemIdByName("Consumed Dessert")
FeedingBowl.CONSUMED_SNACK_ID = Isaac.GetNullItemIdByName("Consumed Snack")
FeedingBowl.GENERIC_FOOD_ID = Isaac.GetNullItemIdByName("Generic Food")

FeedingBowl.PICKUP_CHANCE = 1 / 2

--#endregion
--#region Feeding Bowl Callbacks
function FeedingBowl:SpawnBowlPickup()
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
Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, FeedingBowl.SpawnBowlPickup)

---@param player EntityPlayer
function FeedingBowl:OnUsePickup(_, player)
    local room = Mod.Room()
    Isaac.Spawn(EntityType.ENTITY_SLOT, FeedingBowl.BOWL_VARIANT, 0,
        room:FindFreePickupSpawnPosition(player.Position), Vector.Zero, player)
    player:AddNullItemEffect(FeedingBowl.GENERIC_FOOD_ID, false)
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, FeedingBowl.OnUsePickup, Mod.Pickup.FEEDING_KIT_ID)

---@param bowl EntitySlot
function FeedingBowl:OnBowlInit(bowl)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, FeedingBowl.OnBowlInit, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlUpdate(bowl)
    local sprite = bowl:GetSprite()

    if sprite:IsFinished("Spawn") then
        sprite:Play("Idle")
    end

    local animName = sprite:GetAnimation()
    if not animName:find("Fill") then
        return
    end

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
    if not sprite:IsPlaying("Idle") then
        return
    end

    local player = collider:ToPlayer() ---@cast player EntityPlayer

    if not FeedingBowl:HasFoodItems(player) then
        return
    end

    local tempFX = player:GetEffects()
    if sprite:IsPlaying("Idle")
    and tempFX:HasNullEffect(FeedingBowl.GENERIC_FOOD_ID) then
        sprite:Play("FillGeneric")
        tempFX:RemoveNullEffect(FeedingBowl.GENERIC_FOOD_ID)
        return
    end

    local dinnerCount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DINNER, true, true)
    local dessertCount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_DESSERT, true, true)
    local snackCount = player:GetCollectibleNum(CollectibleType.COLLECTIBLE_SNACK, true, true)

    local consumedDinner = tempFX:GetNullEffectNum(FeedingBowl.CONSUMED_DINNER_ID)
    local consumedDessert = tempFX:GetNullEffectNum(FeedingBowl.CONSUMED_DESSERT_ID)
    local consumedSnack = tempFX:GetNullEffectNum(FeedingBowl.CONSUMED_SNACK_ID)

    if dinnerCount > consumedDinner then
        sprite:Play("FillDinner")
        tempFX:AddNullEffect(FeedingBowl.CONSUMED_DINNER_ID)
    elseif dessertCount > consumedDessert then
        sprite:Play("FillDessert")
        tempFX:AddNullEffect(FeedingBowl.CONSUMED_DESSERT_ID)
    elseif snackCount > consumedSnack then
        sprite:Play("FillSnack")
        tempFX:AddNullEffect(FeedingBowl.CONSUMED_SNACK_ID)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, FeedingBowl.OnBowlCollision, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlDeath(bowl)
    bowl:Remove()
    return false
end
Mod:AddCallback(ModCallbacks.MC_PRE_SLOT_CREATE_EXPLOSION_DROPS, FeedingBowl.OnBowlDeath, FeedingBowl.BOWL_VARIANT)
--#endregion
--#region Feeding Bowl Helper Functions
---@return boolean
---@param player EntityPlayer
function FeedingBowl:HasFoodItems(player)
    return player:HasCollectible(CollectibleType.COLLECTIBLE_DINNER)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_DESSERT)
    or player:HasCollectible(CollectibleType.COLLECTIBLE_SNACK)
    or player:GetEffects():HasNullEffect(FeedingBowl.GENERIC_FOOD_ID)
end
--#endregion