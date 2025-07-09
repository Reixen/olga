--#region Variables
local Mod = OlgaMod

local FeedingBowl = {}
OlgaMod.FeedingBowl = FeedingBowl

local sfxMan = Mod.SfxMan
local Util = Mod.Util
local saveMan = Mod.SaveManager

FeedingBowl.BOWL_VARIANT = Isaac.GetEntityVariantByName("Feeding Bowl")
FeedingBowl.FALL_SFX = Isaac.GetSoundIdByName("Feeding Bowl Fall")
FeedingBowl.POUR_SFX = Isaac.GetSoundIdByName("Feeding Bowl Pour")

FeedingBowl.CONSUMABLE_DINNER_ID = Isaac.GetNullItemIdByName("Consumable Dinner")
FeedingBowl.CONSUMABLE_DESSERT_ID = Isaac.GetNullItemIdByName("Consumable Dessert")
FeedingBowl.CONSUMABLE_SNACK_ID = Isaac.GetNullItemIdByName("Consumable Snack")
FeedingBowl.CONSUMABLE_GENERIC_ID = Isaac.GetNullItemIdByName("Consumable Generic")

FeedingBowl.FEEDING_KIT_ID = Mod.PickupHandler.Pickup[PickupVariant.PICKUP_TAROTCARD].FEEDING_KIT_ID

FeedingBowl.CollectibleToNullFX = {
    [CollectibleType.COLLECTIBLE_NULL] = FeedingBowl.CONSUMABLE_GENERIC_ID,
    [CollectibleType.COLLECTIBLE_DINNER] = FeedingBowl.CONSUMABLE_DINNER_ID,
    [CollectibleType.COLLECTIBLE_DESSERT] = FeedingBowl.CONSUMABLE_DESSERT_ID,
    [CollectibleType.COLLECTIBLE_SNACK] = FeedingBowl.CONSUMABLE_SNACK_ID
}

FeedingBowl.AnimToSfx = {
    ["FillGeneric"] = {Land = FeedingBowl.POUR_SFX,                 Drop = SoundEffect.SOUND_ROCK_CRUMBLE},
    ["FillDessert"] = {Land = FeedingBowl.POUR_SFX,                 Drop = SoundEffect.SOUND_ROCK_CRUMBLE},
    ["FillDinner"] =  {Land = SoundEffect.SOUND_MEAT_IMPACTS_OLD,   Drop = SoundEffect.SOUND_MEAT_IMPACTS},
    ["FillSnack"] =   {Land = FeedingBowl.FALL_SFX,                 Drop = SoundEffect.SOUND_1UP},
}
--#endregion
--#region EID Compatibility
if EID then
    EID:addIcon("Card" .. FeedingBowl.FEEDING_KIT_ID, "Feeding Kit", 0, 9, 9, 6, 6, Mod.EIDSprite)
    EID:addIcon("Feeding Bowl", "Feeding Bowl", 0, 9, 9, 5, 6, Mod.EIDSprite)
    EID:addIcon("Generic Food", "Generic Food", 0, 9, 9, 5, 6, Mod.EIDSprite)

    EID:addCard(FeedingBowl.FEEDING_KIT_ID,
        "{{Feeding Bowl}} Spawns a" ..
        "#{{Blank}} Feeding Bowl and grants Isaac 1 {{Generic Food}} Generic Food" ..
        "#{{Generic Food}} Feed {{Olga}} Olga to get Pup Points and unlock achievements"..
        "#Can be fed with {{Collectible" .. CollectibleType.COLLECTIBLE_DESSERT .. "}}, " ..
        "{{Collectible" .. CollectibleType.COLLECTIBLE_DINNER .. "}}, or {{Collectible" .. CollectibleType.COLLECTIBLE_SNACK.. "}} "..
        "and will not be removed from Isaac's inventory"
    )
end
--#endregion
--#region Feeding Bowl Callbacks
---@param player EntityPlayer
function FeedingBowl:OnConsumableUse(_, player)
    local bowl = Isaac.Spawn(EntityType.ENTITY_SLOT, FeedingBowl.BOWL_VARIANT, 0,
        Mod.Room():FindFreePickupSpawnPosition(player.Position, 60, true), Vector.Zero, player):ToSlot()
    bowl:GetSprite():Play("Spawn")
    sfxMan:Play(FeedingBowl.FALL_SFX, 0.6, 2, false, 1.4)
    Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, bowl.Position, Vector.Zero, bowl)
    player:AddNullItemEffect(FeedingBowl.CONSUMABLE_GENERIC_ID, false)
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, FeedingBowl.OnConsumableUse, FeedingBowl.FEEDING_KIT_ID)

---@param bowl EntitySlot
function FeedingBowl:OnBowlInit(bowl)
    local data = saveMan.TryGetRoomSave(bowl)

    if not data then
        return
    end

    local sprite = bowl:GetSprite()
    sprite:Play(data.animName)
    sprite:SetLastFrame()
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, FeedingBowl.OnBowlInit, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlUpdate(bowl)
    local sprite = bowl:GetSprite()

    local data = saveMan.GetRoomSave(bowl)
    data.animName = sprite:GetAnimation()

    if sprite:IsFinished()
    and data.animName:find("ToIdle")
    or sprite:IsFinished("Spawn") then
        sprite:Play("Idle")
    end

    local sfxPack = FeedingBowl.AnimToSfx[data.animName]

    if not sfxPack then
        return
    end

    if sprite:IsEventTriggered("Drop") then
        sfxMan:Play(sfxPack.Drop, 1, 2, false, math.random(9, 11) / 10)
    elseif sprite:IsEventTriggered("Land") then
        sfxMan:Play(sfxPack.Land, 1, 2, false, math.random(9, 11) / 10)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_UPDATE, FeedingBowl.OnBowlUpdate, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
---@param collider Entity
function FeedingBowl:OnBowlCollision(bowl, collider)
    local touch = bowl:GetTouch()
    if collider.Type ~= EntityType.ENTITY_PLAYER or touch ~= 0 then
        return
    end

    local sprite = bowl:GetSprite()
    if not sprite:IsFinished("Idle") then
        return
    end

    local player = collider:ToPlayer() ---@cast player EntityPlayer
    local tempFX = player:GetEffects()

    local yummers = FeedingBowl:HasFoodItems(tempFX)
    if not yummers then
        return
    end

    FeedingBowl:PlayFillAnimation(bowl, tempFX, sprite, yummers)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, FeedingBowl.OnBowlCollision, FeedingBowl.BOWL_VARIANT)

---@param bowl EntitySlot
function FeedingBowl:OnBowlDeath(bowl)
    sfxMan:Play(SoundEffect.SOUND_POT_BREAK)
    bowl:Remove()

    for _ = 1, (math.random(1, 3)) do
        Isaac.Spawn(
            EntityType.ENTITY_EFFECT, EffectVariant.CHAIN_GIB, math.random(0, 3),
            bowl.Position, RandomVector() * math.random(1, 6), bowl
        ):ToEffect().Rotation = math.random(0, 7) * 45 -- Degrees
    end

    if not saveMan.TryGetRoomSave() then return false end
    local roomSave = saveMan.GetRoomSave()

    Util:RemoveBowlIndex(roomSave.filledBowls, bowl)

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

-- For future use my ASS
function FeedingBowl:SavePupPoints()
    local runSave = saveMan.GetRunSave()
    local persistentSave = saveMan.GetPersistentSave()

    persistentSave.pupPoints = runSave.pupPoints or persistentSave.pupPoints or 0
end
Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, FeedingBowl.SavePupPoints)

function FeedingBowl:GetPupPoints()
    local runSave = saveMan.GetRunSave()
    local persistentSave = saveMan.GetPersistentSave()

    runSave.pupPoints = persistentSave.pupPoints or runSave.pupPoints or 0
end
Mod:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, FeedingBowl.GetPupPoints)
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

---@param bowl EntitySlot
---@param tempFX TemporaryEffects
---@param sprite Sprite
---@param foodItems table
function FeedingBowl:PlayFillAnimation(bowl, tempFX, sprite, foodItems)
    for _, nullFX in pairs(foodItems) do
        local name = Isaac.GetItemConfig():GetNullItem(nullFX).Name
        name = name:gsub("Consumable ", "")

        sprite:Play("Fill" .. name)
        tempFX:RemoveNullEffect(nullFX, 1)
        --sfxMan:Play(FeedingBowl.POUR_SFX, 0.3)

        local roomSave = saveMan.GetRoomSave()
        if not roomSave.filledBowls then
            roomSave.filledBowls = {}
        end

        roomSave.filledBowls[#roomSave.filledBowls + 1] = Mod.Room():GetGridIndex(bowl.Position)
        break
    end
end

--#endregion