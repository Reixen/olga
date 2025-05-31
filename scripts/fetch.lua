--#region Variables
local Mod = OlgaMod

local Fetch = {}
OlgaMod.Fetch = Fetch

local sfxMan = Mod.SfxMan

local MARK_SPEED = 20
Fetch.FETCH_TARGET_SUBTYPE = Isaac.GetEntitySubTypeByName("Fetch Target")
Fetch.PICKUP_CHANCE = 1 / 6
local ONE_SEC = 30

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

---@param rng RNG
---@param spawnPos Vector
function Fetch:SpawnFetchPickup(rng, spawnPos)
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        if math.random() < Fetch.PICKUP_CHANCE then
            local data = familiar:ToFamiliar():GetData()
            local subType
            if not data.hasStick and not data.hasBall then
                if math.random() < 0.5 then
                    subType = Mod.Pickup.STICK_ID
                    data.hasStick = true
                else
                    subType = Mod.Pickup.TENNIS_BALL_ID
                    data.hasBall = true
                end
            elseif not data.hasStick then
                subType = Mod.Pickup.STICK_ID
                data.hasStick = true
            elseif not data.hasBall then
                subType = Mod.Pickup.TENNIS_BALL_ID
                data.hasBall = true
            end

            if not subType then break end

            Isaac.Spawn(
                EntityType.ENTITY_PICKUP,
                PickupVariant.PICKUP_TAROTCARD,
                subType,
                spawnPos,
                Vector.Zero,
                nil
            )
            break
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, Fetch.SpawnFetchPickup)

if true then return end

---@param player EntityPlayer
function Fetch:OnPickupUse(cardId, player)
    player:AnimateCard(cardId)
    player:AnimatePickup(player:GetHeldSprite(), false, "LiftItem")
end
---@param player EntityPlayer
function Fetch:OnUseBone(cardId, player, useFlags)
    local data = player:GetData()
    if not data.hasDoggy or not data.canFetch then return end

    data.cardId = cardId

    player:AnimateCard(cardId)
    player:AnimatePickup(player:GetHeldSprite(), false, "LiftItem")
    --local cardConfig = Isaac.GetItemConfig():GetCard(cardId)
    --player:AnimatePickup(sprite, false, "LiftItem")
    if not data.hasMark then
        local fetchMark = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.TARGET, 0, player.Position, Vector.Zero, player)
        local markData = fetchMark:GetData()
        markData.fetchMark = true
        markData.cooldown = ONE_SEC * 1.5
    end
    return true
end
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, Fetch.OnUseBone)

local thrownPickup
local lastPos

---@param effect EntityEffect
function Fetch:OnMarkRender(effect)
    local data = effect:GetData()
    if not data.fetchMark then return end

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        if not familiar then return end
        data.fam = familiar:ToFamiliar()
        data.player = data.fam.Player
        data.playerData = data.player:GetData()
    end

    data.cooldown = data.cooldown - 1
    if data.cooldown > ONE_SEC / 2 then
        if Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, 0) then
            effect.Velocity = Vector(0, MARK_SPEED)
        end
        if Input.IsActionPressed(ButtonAction.ACTION_SHOOTUP, 0) then
            effect.Velocity = Vector(0, -MARK_SPEED)
        end
        if Input.IsActionPressed(ButtonAction.ACTION_SHOOTRIGHT, 0) then
            effect.Velocity =  Vector(MARK_SPEED, 0)
        end
        if Input.IsActionPressed(ButtonAction.ACTION_SHOOTLEFT, 0) then
            effect.Velocity =  Vector(-MARK_SPEED, 0)
        end
    else
        -- tear needs to not have fixed time it takes to arrive atmarked
        -- data.thrownPickup
        if data.cooldown == ONE_SEC / 2 then
            lastPos = data.player.Position
            thrownPickup = Isaac.Spawn(
                            EntityType.ENTITY_TEAR,
                            TearVariant.BONE,
                            0,
                            lastPos,
                            Vector.Zero,
                            data.player):ToTear() ---@cast thrownPickup EntityTear
            sfxMan:Play(SoundEffect.SOUND_SHELLGAME)
            data.player:AnimatePickup(data.player:GetHeldSprite(), false, "HideItem")
        end

        if thrownPickup then
            thrownPickup.TearFlags = TearFlags.TEAR_PIERCING | TearFlags.TEAR_NO_GRID_DAMAGE | TearFlags.TEAR_SPECTRAL
            local distance = effect.Position:Distance(lastPos)

            -- sin wave, effect would be better
            thrownPickup.Velocity = (effect.Position - lastPos):Normalized() * (distance / 30)
            thrownPickup.FallingAcceleration = data.cooldown > 14 and -20 or 1
        end
    end
    if data.cooldown <= 0 then
        local bone = Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.playerData.cardId, effect.Position, Vector.Zero, nil)
        local famData = data.fam:GetData()
        famData.isHolding = data.playerData.cardId
        famData.isFetching = bone:ToPickup().Position
        effect:Remove()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, Fetch.OnMarkRender, EffectVariant.TARGET)