--#region Variables
local Mod = OlgaMod

local Fetch = {}
OlgaMod.Fetch = Fetch

local sfxMan = Mod.SfxMan
local saveMan = Mod.SaveManager

Fetch.FETCH_TARGET_SUBTYPE = Isaac.GetEntitySubTypeByName("Fetch Target")
Fetch.FETCHING_OBJECT_VARIANT = Isaac.GetEntityVariantByName("Fetching Object")

Fetch.TARGET_SPEED = 10
Fetch.PICKUP_CHANCE = 1 / 8
Fetch.ROTG_CHANCE = 1 / 100

local ONE_SEC = 30
Fetch.MARK_TIMEOUT = ONE_SEC * 1.5
-- Fetching duration if the distance equals to the base length
Fetch.DURATION = ONE_SEC
Fetch.TIMEOUT_INCREASE = 1

local ONE_TILE = 40
Fetch.BASE_LENGTH = ONE_TILE * 3
-- Amount of time to reduce/increase per tile
Fetch.UNITS_PER_TILE = ONE_SEC / 12
Fetch.SPIN_STRENGTH = 8
Fetch.ARC_HEIGHT = 46
Fetch.ARC_SHIFT = 6

--#endregion
--#region Fetch Callbacks
function Fetch:SpawnFetchPickup()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local rng = familiar:ToFamiliar():GetDropRNG()

        if rng:RandomFloat() < Fetch.PICKUP_CHANCE then
            local data = familiar:ToFamiliar():GetData() ---@cast data DogData
            local subType

            -- el the goat
            if data.hasBall == nil then
                subType = Mod.Pickup.TENNIS_BALL_ID
                data.hasBall = true
            end

            if data.hasStick == nil then
                subType = rng:RandomFloat() < Fetch.ROTG_CHANCE and Mod.Pickup.ROD_OF_THE_GODS_ID or Mod.Pickup.STICK_ID
                data.hasStick = true
            end

            if data.hasStick and data.hasBall then
                if rng:RandomFloat() < 0.5 then
                    data.hasStick = false
                else
                    data.hasBall = false
                end
            end

            if subType == nil then return end

            local room = Mod.Room()
            local spawnPos = room:FindFreePickupSpawnPosition(room:GetCenterPos())
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, subType, spawnPos, Vector.Zero, nil)
            break
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, Fetch.SpawnFetchPickup)

---@param cardId Card
---@param player EntityPlayer
function Fetch:OnUsePickup(cardId, player)
    local objectSprite = player:GetHeldSprite()
    player:AnimatePickup(objectSprite, false, "LiftItem")

    local pickupName = Isaac.GetItemConfig():GetCard(cardId).Name
    pickupName = pickupName:gsub(" ", "_")

    local data = Mod.Util:GetData(player, Mod.Util.ID)
    data.isUsingPickup = cardId

    local target = Isaac.Spawn(
        EntityType.ENTITY_EFFECT, EffectVariant.TARGET, Fetch.FETCH_TARGET_SUBTYPE,
        player.Position, Vector.Zero, player):ToEffect() ---@cast target EntityEffect
    target.Timeout = Fetch.MARK_TIMEOUT

    local targetData = target:GetData()
    targetData.controllerIdx = player.ControllerIndex
    targetData.objSprite = objectSprite
    targetData.objID = cardId
    targetData.objName = pickupName

    local targetSprite = target:GetSprite()
    if cardId == Mod.Pickup.ROD_OF_THE_GODS_ID then
        targetSprite:PlayOverlay("ObjectROTG", true)
        return
    end

    targetSprite:ReplaceSpritesheet(2, "gfx/items/pickups/" .. pickupName .. ".png", true)
    target:GetSprite():PlayOverlay("Object", true)
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Fetch.OnUsePickup, Mod.Pickup.STICK_ID)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Fetch.OnUsePickup, Mod.Pickup.TENNIS_BALL_ID)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Fetch.OnUsePickup, Mod.Pickup.ROD_OF_THE_GODS_ID)

---@param target EntityEffect
function Fetch:OnTargetInit(target)
    if target.SubType ~= Fetch.FETCH_TARGET_SUBTYPE then
        return
    end

    target.Color = Color(1, 1, 1, 1, 0, 0, 0)
    target.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_WALLS
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, Fetch.OnTargetInit, EffectVariant.TARGET)

---@param target EntityEffect
function Fetch:OnTargetUpdate(target)
    if target.SubType ~= Fetch.FETCH_TARGET_SUBTYPE then
        return
    end

    local data = target:GetData()
    if not data.controllerIdx then
        return
    end

    local timeToAdd = 0

    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, data.controllerIdx) then
        local actionValDown = Input.GetActionValue(ButtonAction.ACTION_SHOOTDOWN, data.controllerIdx)
        timeToAdd = timeToAdd + actionValDown
        target.Velocity = Vector(target.Velocity.X, target.Velocity.Y + Fetch.TARGET_SPEED * actionValDown)
    end

    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, data.controllerIdx) then
        local actionValUp = Input.GetActionValue(ButtonAction.ACTION_SHOOTUP, data.controllerIdx)
        timeToAdd = timeToAdd + actionValUp
        target.Velocity = Vector(target.Velocity.X, target.Velocity.Y - Fetch.TARGET_SPEED * actionValUp)
    end

    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, data.controllerIdx) then
        local actionValLeft = Input.GetActionValue(ButtonAction.ACTION_SHOOTLEFT, data.controllerIdx)
        timeToAdd = timeToAdd + actionValLeft
        target.Velocity = Vector(target.Velocity.X - Fetch.TARGET_SPEED * actionValLeft, target.Velocity.Y)
    end

    if Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, data.controllerIdx) then
        local actionValRight = Input.GetActionValue(ButtonAction.ACTION_SHOOTRIGHT, data.controllerIdx)
        timeToAdd = timeToAdd + actionValRight
        target.Velocity = Vector(target.Velocity.X + Fetch.TARGET_SPEED * actionValRight, target.Velocity.Y)
    end

    target.Timeout = target.Timeout + math.floor(timeToAdd * Fetch.TIMEOUT_INCREASE)
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Fetch.OnTargetUpdate, EffectVariant.TARGET)

---@param object EntityEffect
function Fetch:OnObjectUpdate(object)
    local data = object:GetData()
    object.Color = Color(1, 1, 1, 1)

    local arcHeight = Fetch.ARC_HEIGHT + (Fetch.ARC_HEIGHT / 6) * data.duration
    local arcLength = math.pi / (data.duration * ONE_SEC)

    --          Amplitude     --      Period   --       Input      --    Left/Right
    local arc = arcHeight * math.sin(arcLength * (object.FrameCount + Fetch.ARC_SHIFT))
    object.SpriteOffset = Vector(0, -arc)
    object.SpriteRotation = object.FrameCount * Fetch.SPIN_STRENGTH

    local endDuration = data.duration * ONE_SEC - Fetch.ARC_SHIFT
    if object.FrameCount > endDuration then
        object:Remove()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Fetch.OnObjectUpdate, Fetch.FETCHING_OBJECT_VARIANT)

---@param entity Entity
function Fetch:OnEffectRemove(entity)
    if entity.Variant ~= Fetch.FETCHING_OBJECT_VARIANT
    and (entity.Variant ~= EffectVariant.TARGET or entity.SubType ~= Fetch.FETCH_TARGET_SUBTYPE) then
        return
    end

    local data = entity:GetData()
    local player = entity.SpawnerEntity and entity.SpawnerEntity:ToPlayer() or nil ---@cast player EntityPlayer

    -- This is needed in case they exit the run
    if not player then return end

    if entity.Variant == EffectVariant.TARGET and entity.SubType == Fetch.FETCH_TARGET_SUBTYPE then
        player:AnimatePickup(data.objSprite, false, "HideItem")

        local room = Mod.Room()
        if room:GetGridCollisionAtPos(entity.Position) ~= GridCollisionClass.COLLISION_NONE then
            sfxMan:Play(SoundEffect.SOUND_BOSS2INTRO_ERRORBUZZ)
            player:AddCard(data.objID)
            return
        end

        sfxMan:Play(SoundEffect.SOUND_SHELLGAME)

        local object = Isaac.Spawn(EntityType.ENTITY_EFFECT, Fetch.FETCHING_OBJECT_VARIANT, 0, player.Position, Vector.Zero, player):ToEffect() ---@cast object EntityEffect
        local objData = object:GetData()
        objData.pickupID = data.objID
        objData.duration = Fetch:GetThrowDuration(entity.Position:Distance(player.Position))
        object:GetSprite():Play(data.objName, true)
        object.Color = Color(0, 0, 0, 0)
        object.Velocity = -(object.Position - entity.Position) / (objData.duration * ONE_SEC - (Fetch.ARC_SHIFT / 1.2)) -- shift closer to mark

        local olga = Fetch:FindNearestDog(entity.Position) ---@cast olga EntityFamiliar

        if not olga then return end
        local dogData = olga:GetData() ---@cast dogData DogData

        dogData.headSprite:ReplaceSpritesheet(4, "gfx/familiar/held_object_" .. data.objName .. ".png", true)
        dogData.targetPos = entity.Position
        dogData.objectID = data.objID
        dogData.eventWindow = objData.duration + ONE_SEC * 2
        olga.State = Mod.Util.DogState.FETCH
        return
    end

    -- If it's a fetching object instead
    local pickup = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.pickupID, entity.Position, Vector.Zero, player)
    local sprite = pickup:GetSprite()
    sprite:SetFrame(4)

    local pData = Mod.Util:GetData(player, Mod.Util.ID)
    pData.isUsingPickup = false
end
Mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, Fetch.OnEffectRemove, EntityType.ENTITY_EFFECT)

-- When they exit mid-fetch
function Fetch:OnFetchInterrupt()
    for _, entity in pairs(PlayerManager.GetPlayers()) do
        local player = entity:ToPlayer()---@cast player EntityPlayer
        local data = Mod.Util:GetData(player, Mod.Util.ID)
        if data.isUsingPickup then
            player:AddCard(data.isUsingPickup)
            data.isUsingPickup = nil
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Fetch.OnFetchInterrupt)
Mod:AddCallback(ModCallbacks.MC_PRE_CHANGE_ROOM, Fetch.OnFetchInterrupt)
Mod:AddCallback(ModCallbacks.MC_PRE_LEVEL_INIT, Fetch.OnFetchInterrupt)

function Fetch:OnDogFetchInterrupt()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar()
        local data = olga:GetData()

        if olga.State == Mod.Util.DogState.RETURN then
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.objectID, olga.Position, Vector.Zero, olga)
            olga.State = Mod.Util.DogState.SITTING
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, Fetch.OnDogFetchInterrupt)

--#endregion
--#region Fetch Helper Functions
-- Returns the amount of time (seconds) needed to finish the travel
---@param distance number
function Fetch:GetThrowDuration(distance)
    if distance < Fetch.BASE_LENGTH then
        local tiles = distance / ONE_TILE
        local frames = Fetch.DURATION - tiles * Fetch.UNITS_PER_TILE
        return frames / ONE_SEC
    end

    local tiles = (distance - Fetch.BASE_LENGTH) / ONE_TILE
    local frames = Fetch.UNITS_PER_TILE * tiles + Fetch.DURATION
    return frames / ONE_SEC
end

---@return EntityFamiliar | nil
---@param position Vector
function Fetch:FindNearestDog(position)
    local nearestDoggy
    local shortestDistance

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar()
        local distance = position:DistanceSquared(olga.Position)

        if not Mod.Util:IsFetching(olga)
        and (not shortestDistance or distance < shortestDistance) then
            shortestDistance = distance
            nearestDoggy = olga
        end
    end

    return nearestDoggy
end
--endregion