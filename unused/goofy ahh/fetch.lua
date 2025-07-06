--#region Variables
local Mod = OlgaMod

local Fetch = {}
OlgaMod.Fetch = Fetch

local sfxMan = Mod.SfxMan

Fetch.FETCH_TARGET_SUBTYPE = Isaac.GetEntitySubTypeByName("Fetch Target")
Fetch.FETCHING_OBJECT_VARIANT = Isaac.GetEntityVariantByName("Fetching Object")

Fetch.TARGET_SPEED = 15
Fetch.PICKUP_CHANCE = 1 / 6

local ONE_SEC = 30
Fetch.MARK_TIMEOUT = ONE_SEC * 2
Fetch.OBJECT_TIMEOUT = ONE_SEC * 5
-- Fetching duration if the distance equals to the base length
Fetch.DURATION = ONE_SEC
Fetch.TIMEOUT_INCREASE = 1.5

local ONE_TILE = 40
Fetch.BASE_LENGTH = ONE_TILE * 3
-- Amount of time to reduce/increase per tile
Fetch.UNITS_PER_TILE = ONE_SEC / 24
Fetch.SPIN_STRENGTH = 8
Fetch.ARC_HEIGHT = 46
Fetch.ARC_SHIFT = 6

--#endregion
--#region Callbacks

---@param pickup EntityPickup
function Fetch:PrePickupMorph(pickup)
    if pickup.Type ~= EntityType.ENTITY_PICKUP then return end

    if pickup.Variant == PickupVariant.PICKUP_TAROTCARD then
        if pickup.SubType == Mod.Pickup.STICK_ID
        or pickup.SubType == Mod.Pickup.FEEDING_BOWL_ID
        or pickup.SubType == Mod.Pickup.TENNIS_BALL_ID then
            return false
        end
    elseif pickup.Variant == PickupVariant.PICKUP_TRINKET
    and pickup.SubType == Mod.Pickup.CRUDE_DRAWING_ID then
        return false
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_PICKUP_MORPH, Fetch.PrePickupMorph)

---@param spawnPos Vector
function Fetch:SpawnFetchPickup(_, spawnPos)
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local rng = familiar:ToFamiliar():GetDropRNG()

        if rng:RandomFloat() < Fetch.PICKUP_CHANCE then
            local data = familiar:ToFamiliar():GetData()
            local subType

            -- el the goat
            if data.hasBall == nil then
                subType = Mod.Pickup.TENNIS_BALL_ID
                data.hasBall = true
            end

            if data.hasStick == nil then
                subType = Mod.Pickup.STICK_ID
                data.hasStick = true
            end

            if data.hasStick and data.hasBall then
                if rng:RandomFloat() < 0.5 then
                    subType = Mod.Pickup.TENNIS_BALL_ID
                    data.hasStick = false
                else
                    subType = Mod.Pickup.STICK_ID
                    data.hasBall = false
                end
            end

            Isaac.Spawn( EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, subType, spawnPos, Vector.Zero, nil)
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
    targetSprite:ReplaceSpritesheet(2, "gfx/items/pickups/" .. pickupName .. ".png", true)

end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Fetch.OnUsePickup, Mod.Pickup.STICK_ID)
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Fetch.OnUsePickup, Mod.Pickup.TENNIS_BALL_ID)

---@param target EntityEffect
function Fetch:OnTargetInit(target)
    if target.SubType ~= Fetch.FETCH_TARGET_SUBTYPE then
        return
    end

    target:GetSprite():PlayOverlay("Object", true)
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

---@param entity Entity
function Fetch:OnTargetRemove(entity)
    if entity.Variant ~= EffectVariant.TARGET or entity.SubType ~= Fetch.FETCH_TARGET_SUBTYPE then
        return
    end

    local data = entity:GetData()
    local player = entity.SpawnerEntity:ToPlayer() ---@cast player EntityPlayer
    player:AnimatePickup(data.objSprite, false, "HideItem")
    sfxMan:Play(SoundEffect.SOUND_SHELLGAME)

    local object = Isaac.Spawn(EntityType.ENTITY_EFFECT, Fetch.FETCHING_OBJECT_VARIANT, 0, player.Position, Vector.Zero, player):ToEffect() ---@cast object EntityEffect
    local objData = object:GetData()
    objData.pickupID = data.objID
    objData.endPoint = entity.Position
    objData.duration = Fetch:GetThrowDuration(entity.Position:Distance(player.Position))
    object:GetSprite():Play(data.objName, true)
    object.Color = Color(0, 0, 0, 0)
end
Mod:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE, Fetch.OnTargetRemove, EntityType.ENTITY_EFFECT)

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

    if not data.velocity then data.velocity = -(object.Position - data.endPoint) / (data.duration * ONE_SEC - Fetch.ARC_SHIFT * 1.2) end
    object.Velocity = data.velocity

    local endDuration = data.duration * ONE_SEC - Fetch.ARC_SHIFT
    if object.FrameCount > endDuration then
        object:Remove()
    elseif object.FrameCount > endDuration - 3 and object.FrameCount < endDuration - 2 then
        local player = object.SpawnerEntity:ToPlayer() ---@cast player EntityPlayer
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.pickupID, data.endPoint, Vector.Zero, player)
        player:GetData().timerT = player.FrameCount + (ONE_SEC * 10)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Fetch.OnObjectUpdate, Fetch.FETCHING_OBJECT_VARIANT)


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
--endregion

local e = Isaac.GetSoundIdByName("E")
local c = Isaac.GetSoundIdByName("C")
local ts = Sprite()
ts:Load("gfx/effect_came.anm2", true)

---@param pl EntityPlayer
function Fetch:p(pl)
    local d = pl:GetData()
    if not d.timerT then return end

    if pl.FrameCount < (d.timerT - (ONE_SEC * 8)) then return end

    local r = Mod.Room()
    ts:Render(Isaac.WorldToScreen(r:GetCenterPos() + Vector(0, 140)))
    ts:Play("Idle")

    if ts:IsEventTriggered("E") then
        Mod.SfxMan:Play(e)
    end

    if not Mod.SfxMan:IsPlaying(c) then
        Mod.SfxMan:Play(c)
    end

    if ts:IsFinished(ts:GetAnimation()) and pl.FrameCount > d.timerT then
        ts:Reset()
        Mod.SfxMan:Stop(c)
        d.timerT = nil
    end
    ts:Update()
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_RENDER, Fetch.p)