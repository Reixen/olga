--#region Variables
local Mod = OlgaMod

local DogBody = {}
OlgaMod.Dog.Body = DogBody

local game = Mod.Game
local sfxMan = Mod.SfxMan
local Util = Mod.Util
local saveMan = Mod.SaveManager

DogBody.SOUND_BARK_SET1 = Isaac.GetSoundIdByName("Olga Bark Set 1")
DogBody.SOUND_SCRATCH = Isaac.GetSoundIdByName("Olga Scratch")
DogBody.EXPLOSION_VARIANT = Isaac.GetEntityVariantByName("Stock Explosion")
DogBody.EXPLOSION_SFX = Isaac.GetSoundIdByName("Stock Explosion")

DogBody.SWITCH_CHANCE = 1 / 40
DogBody.WANDER_CHANCE = 1 / 2
DogBody.WALK_SPEED = 0.4
DogBody.RUN_SPEED = 0.9
DogBody.RUN_LENGTH = 4

local ONE_TILE = 40
local ONE_SEC = 30
DogBody.FETCH_RADIUS = ONE_TILE / 2
DogBody.WANDER_RADIUS = 5
DogBody.HAPPY_DISTANCE = ONE_TILE * 2.2
DogBody.DECAY_STRENGTH = 0.75

DogBody.EVENT_COOLDOWN = ONE_SEC * 6
DogBody.FIRE_PLACE_GRID_VALUE = 950 -- Used to stop invalidate fireplaces as something she can reach

---@enum PathfindingResult
DogBody.PathfindingResult = {
    ERROR = -1,
    NO_PATH = 0,
    APPROACHING = 1,
    APPROACHING_NEAR = 2,
    SUCCESSFUL = 3,
    COLLIDING = 4
}
--#endregion
--#region Annotations
---@class DogData
---@field eventCD integer -- Time it takes for the next movement
---@field animCD integer -- Time it takes for the next idle animation
---@field attentionCD integer -- Time it takes for the dog to have a special headpat event
---@field eventWindow integer -- Not dependent on framecount, only starts counting down on specific scenarios
---@field headSprite Sprite
---@field headRender boolean | DogState? -- Used to stop the head for rendering when doing special idle animations
---@field targetPos Vector? -- Target position to move towards
---@field lowerBound number? -- Used in caching the lower bound for speed decay
---@field objectID integer? -- For saving the pickup ID for fetching
---@field feedingBowl EntitySlot?
---@field canPet boolean? -- Used for preventing the player from petting the dog in certain scenarios
---@field hasOwner boolean?
---@field hasStick boolean?
---@field hasBall boolean?
---@field hasBowl boolean?
---@field isMoving boolean?
---@field isRunning boolean?

--#endregion
--#region Olga Body Animation Functions
DogBody.ANIM_FUNC = {
    [Util.BodyAnim.SIT] = function(olga, sprite, data)
        local rng = olga:GetDropRNG()

        if DogBody:CanWag(data.headSprite:GetAnimation())
        or Util:IsWithin(olga, olga.Player.Position, ONE_TILE * 2) then
            sprite:Play(Util.BodyAnim.SIT_WAGGING, true)
            return
        end

        local frameCount = olga.FrameCount
        if rng:RandomFloat() < DogBody.SWITCH_CHANCE and data.eventCD < frameCount
        or Util:IsBusy(olga) then
            data.eventCD = frameCount + DogBody.EVENT_COOLDOWN
            sprite:Play(Util.BodyAnim.SIT_TO_STAND, true)
        end
    end,

    [Util.BodyAnim.SIT_WAGGING] = function(olga, sprite)
        if  sprite:IsEventTriggered("TransitionHook") and
        not Util:IsWithin(olga, olga.Player.Position, DogBody.HAPPY_DISTANCE) then
            sprite:Play(Util.BodyAnim.SIT, true)
        end
    end,

    -- Movement animations
    ---@param olga EntityFamiliar
    ---@param sprite Sprite
    ---@param data DogData
    [Util.BodyAnim.STAND] = function(olga, sprite, data)
        local rng = olga:GetDropRNG()
        local frameCount = olga.FrameCount

        DogBody:PlayAnimation(olga.Velocity:Length(), sprite)

        if olga.State == Util.DogState.EATING then
            DogBody:TryEating(olga, data) -- Line 687
            return

        elseif olga.State == Util.DogState.APPROACH_BOWL then
            DogBody:TryApproachBowl(olga, data) -- Line 623
            return

        elseif olga.State == Util.DogState.RETURN then
            local pathfindingResult = DogBody:Pathfind(
                olga, olga.Player.Position, DogBody.RUN_SPEED, data, ONE_TILE, ONE_TILE, DogBody.DECAY_STRENGTH
            )

            -- Drop the stick when near the owner or when she cannot pathfind
            if (pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL or pathfindingResult == DogBody.PathfindingResult.NO_PATH)
            and not data.headSprite:IsPlaying(Util.HeadAnim.HOLD_TO_IDLE) then
                DogBody:EndFetch(olga, data)
                olga.State = Util.DogState.STANDING
            end
            return

        elseif olga.State == Util.DogState.FETCH then
            DogBody:TryFetching(olga, data) -- Line 537
            return
        end

        if data.eventCD < frameCount then
            -- Switching
            if sprite:IsEventTriggered("TransitionHook")
            and rng:RandomFloat() < DogBody.SWITCH_CHANCE then
                olga.Velocity = Vector.Zero
                data.targetPos = nil
                data.eventCD = frameCount + DogBody.EVENT_COOLDOWN
                sprite:Play(Util.BodyAnim.STAND_TO_SIT, true)
                olga.State = Util.DogState.SITTING
            end

            -- Prevent her from moving when an animation is playing
            -- Unsure
            --if data.animCD > frameCount then
                --olga.Velocity = Vector.Zero
                --DogBody:ReturnToDefault(olga, data, true)
                --return
            --end

            if data.targetPos then
                local pathfindingResult = DogBody:Pathfind(olga, data.targetPos, DogBody.WALK_SPEED, data)

                if pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL
                or pathfindingResult == DogBody.PathfindingResult.NO_PATH then
                    olga.Velocity = Vector.Zero
                    DogBody:ReturnToDefault(olga, data, true)
                end
                return
            end

            if rng:RandomFloat() < DogBody.WANDER_CHANCE
            and data.animCD < frameCount then
                data.targetPos = DogBody:ChooseRandomPosition(olga)
            end
        end
    end,

    -- Idle animations
    [Util.BodyAnim.PLAYFUL_1] = function(olga, sprite, data, name)
        if sprite:IsFinished() then
            sprite:Play(Util.BodyAnim.STAND, true)
            data.headRender = true
            sprite.PlaybackSpeed = 1
        end

        if sprite:IsEventTriggered("TransitionHook")
        and data.animCD < olga.FrameCount then
            sprite.PlaybackSpeed = 1
            sprite:Play(Util.BodyAnim.SCRATCHING_TO_SIT, true)
        end

        if sprite:IsEventTriggered("BarkSet") then
            sfxMan:Play(DogBody.SOUND_BARK_SET1, 2, 2, false)
        end

        if sprite:IsEventTriggered("Scratch") then
            sfxMan:Play(DogBody.SOUND_SCRATCH, 1.5, 1, false, math.random(9, 12)/10)
        end
        if name ~= Util.BodyAnim.SCRATCHING then
            sprite.PlaybackSpeed = 0.74
            return
        end

        sprite.PlaybackSpeed = 1.3
    end,

    -- Transitional animations
    [Util.BodyAnim.SIT_TO_STAND] = function(olga, sprite, data, name)
        if not sprite:IsFinished() then return end

        if name == Util.BodyAnim.SCRATCHING_TO_SIT then
            data.headRender = true
        end

        local animToPlay = Util:FindAnimSubstring(name)
        sprite:Play(Util.BodyAnim[animToPlay], true)

        if Util:IsBusy(olga) then return end

        if name == Util.BodyAnim.SIT_TO_STAND then
            olga.State = Util.DogState.STANDING
        else
            olga.State = Util.DogState.SITTING
        end
    end,
}
DogBody.ANIM_FUNC[Util.BodyAnim.WALKING] = DogBody.ANIM_FUNC[Util.BodyAnim.STAND]
DogBody.ANIM_FUNC[Util.BodyAnim.RUNNING] = DogBody.ANIM_FUNC[Util.BodyAnim.STAND]

-- Use when there's more animations
Util:FillEmptyAnimFunctions(
    Util.BodyAnim,
    DogBody.ANIM_FUNC,
    DogBody.ANIM_FUNC[Util.BodyAnim.SIT_TO_STAND],
    DogBody.ANIM_FUNC[Util.BodyAnim.PLAYFUL_1],
    nil
)

--#endregion
--#region Olga Head Animation Functions
--#endregion
--#region Olga Callbacks
---@param olga EntityFamiliar
function DogBody:HandleBodyLogic(olga)
    local data = olga:GetData()
    local sprite = olga:GetSprite()

    -- Play her special idle animation
    if data.headRender == olga.State then
        sprite:Play(data.animToPlay, true)
        data.headRender = false
    end

    local animName = sprite:GetAnimation()
    DogBody.ANIM_FUNC[animName](olga, sprite, data, animName)

    if data.hasOwner then return end
    DogBody:FindDogOwner(olga, data)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DogBody.HandleBodyLogic, Mod.Dog.VARIANT)

---@param olga EntityFamiliar
function DogBody:OnInit(olga)
    local data = olga:GetData()

    data.eventCD = DogBody.EVENT_COOLDOWN
    data.animCD = DogBody.EVENT_COOLDOWN * 2
    data.attentionCD = 0
    data.headRender = true
    data.feedingBowl = nil

    data.headSprite = Sprite()
    data.headSprite:Load("gfx/render_olga_head.anm2", true)
    data.headSprite:Play(Util.HeadAnim.IDLE, true)

    olga:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
    olga.GridCollisionClass = EntityGridCollisionClass.GRIDCOLL_GROUND
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DogBody.OnInit, Mod.Dog.VARIANT)

function DogBody:HandleNewRoom()
    local room = Mod.Room()
    local roomType = room:GetType()

    --local olgacont = 0
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        local data = familiar:GetData() ---@cast data DogData
        data.targetPos = nil
        data.canPet = false
        familiar.Velocity = Vector.Zero

        if Util:IsEating(olga) then
            data.feedingBowl = nil
        elseif Util:IsFetching(olga) then
            DogBody:EndFetch(olga, data)
        end
        olga.State = Mod.Util.DogState.STANDING
        --olgacont = olgacont + 1
    end

    --print(olgacont)

    if (roomType ~= RoomType.ROOM_ISAACS and roomType ~= RoomType.ROOM_BARREN)
    or not room:IsFirstVisit() or Mod.Level():GetStage() == LevelStage.STAGE8 then
        return
    end

    --print(roomType ~= RoomType.ROOM_ISAACS)
    --print(roomType ~= RoomType.ROOM_BARREN)
    --print(room:IsFirstVisit())

    local spawnPos = room:FindFreePickupSpawnPosition(room:GetCenterPos())
    Isaac.Spawn(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT, 0, spawnPos, Vector.Zero, nil)
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DogBody.HandleNewRoom)

function DogBody:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar

        if not PlayerManager.AnyoneHasTrinket(Mod.Pickup.CRUDE_DRAWING_ID) then
            local pData = Util:GetData(olga.Player, Util.ID)
            pData.hasDoggy = false

            local pos = Mod.Room():FindFreePickupSpawnPosition(familiar.Position, 0, true)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, Mod.Pickup.CRUDE_DRAWING_ID, pos, Vector.Zero, nil)

            familiar:Remove()
            return
        end

        local data = olga:GetData() ---@cast data DogData
        data.hasStick = nil
        data.hasBall = nil
        data.hasBowl = nil
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DogBody.GoodbyeOlga)

function DogBody:OnSacrifice()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar

        if not olga:GetSprite():IsPlaying(Util.BodyAnim.PLAYFUL_1) then
            Mod.Dog.Head:DoIdleAnimation(olga, olga:GetData(), Mod.Dog.Head.IdleAnim[4])

            local explosion = Isaac.Spawn(EntityType.ENTITY_EFFECT, DogBody.EXPLOSION_VARIANT, 0, olga.Position, Vector.Zero, nil):ToEffect()
            explosion.Timeout = 30
            explosion.DepthOffset = 30
            sfxMan:Play(DogBody.EXPLOSION_SFX)
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, DogBody.OnSacrifice, CollectibleType.COLLECTIBLE_SACRIFICIAL_ALTAR)
--#endregion
--#region Olga Helper Functions
---@param anim string
function DogBody:CanWag(anim)
    return anim == Util.HeadAnim.GLAD or anim == Util.HeadAnim.GLAD_PETTING
end

-- Special thanks to minds3t
---@return PathfindingResult
---@param olga EntityFamiliar
---@param target Vector
---@param speed number
---@param data DogData
---@param endRadius? number -- The distance from the target at which the entity stops. Default is 1
---@param decayRadius? number -- When should the decay start? Default is one tile.
---@param decayStrength? number -- Minimum speed before it stops. Base is 1.2 (60%)
-- Pseudo Enum for decay: 0.55 = ~14% , 0.75 = ~33.6%, 1 = ~50%, 2 = ~75%
function DogBody:Pathfind(olga, target, speed, data, endRadius, decayRadius, decayStrength)
    if not target then return DogBody.PathfindingResult.ERROR end

    local pathfinder = olga:GetPathFinder()

    if not pathfinder:HasDirectPath() then
        olga.FlipX = not (olga.Velocity.X < 0)
    else
        olga.FlipX = math.abs((olga.Position - target):GetAngleDegrees()) > 90
    end

    local room = Mod.Room()
    local gridIdx = room:GetGridIndex(olga.Position)
    if not pathfinder:HasPathToPos(target, true) then
        if not olga:CollidesWithGrid() and room:GetGridCollision(gridIdx) == GridCollisionClass.COLLISION_NONE then
            return DogBody.PathfindingResult.NO_PATH
        end

        return DogBody.PathfindingResult.COLLIDING
    end

    local sprite = olga:GetSprite()
    local endDistance = (endRadius and endRadius > 1) and endRadius or 1
    local decayDistance = decayRadius or ONE_TILE
    if not Util:IsWithin(olga, target, endDistance + decayDistance) then
        sprite.PlaybackSpeed = 1
        pathfinder:FindGridPath(target, speed, 1, true)
        data.lowerBound = nil
        return DogBody.PathfindingResult.APPROACHING

    elseif not Util:IsWithin(olga, target, endDistance) then

        -- Get the Vector from the distance at which the entity stops
        local resizedVec = (olga.Position - target):Resized(endDistance) + target
        local distance = olga.Position:DistanceSquared(resizedVec)

        -- Get the decay progression 
        local decayStrn = decayStrength or 2
        local decayValue = 1 - (distance / ((distance + (decayDistance ^ 2)) * decayStrn))
        if not data.lowerBound then
            data.lowerBound = decayValue
        end
        local input = math.abs(decayValue - (1 + data.lowerBound))

        local walkSpeed = speed * input
        sprite.PlaybackSpeed = 1 * input
        --print("decayval: " .. tostring(decayValue) .. ". minSpd: " .. tostring(data.lowerBound))
        --print("Playback speed: " .. tostring(sprite.PlaybackSpeed))

        pathfinder:FindGridPath(target, walkSpeed, 1, true)
        return DogBody.PathfindingResult.APPROACHING_NEAR

    else
        data.lowerBound = nil
        sprite.PlaybackSpeed = 1
        return DogBody.PathfindingResult.SUCCESSFUL
    end
end

---@return Vector | nil
---@param olga EntityFamiliar
function DogBody:ChooseRandomPosition(olga)
    local room = Mod.Room()
    local validPos = DogBody:FindValidPositions(
        DogBody.WANDER_RADIUS,
        room:GetGridIndex(olga.Position),
        room
    )
    if #validPos == 0 then return nil end

    local theGamble = math.random(#validPos)
    local chosenPos = room:GetGridPosition(validPos[theGamble])

    --table.remove(validPos, theGamble)
    --for _, val in pairs(validPos) do
        --Isaac.Spawn(EntityType.ENTITY_EFFECT, 507, 2, room:GetGridPosition(val), Vector.Zero, nil):ToEffect():GetSprite():Play("Quality-1")
    --end
    --Isaac.Spawn(EntityType.ENTITY_EFFECT, 507, 2, chosenPos, Vector.Zero, nil):ToEffect():GetSprite():Play("Quality3")

    local posVariance = math.random() < 0.5 and -12 or 12
    return chosenPos + (RandomVector() * posVariance)
end

---@return table
---@param gridlength integer
---@param gridIdx integer
function DogBody:FindValidPositions(gridlength, gridIdx, room)
    local idxTable = {}
    local queueSize = {}
    local finishedIdx = 0
    queueSize[1] = {gridIdx, 0}

    -- Breadth-first search my beloved
    while finishedIdx < #queueSize do
        local queuePos = finishedIdx + 1
        local gridIdxPos = room:GetGridPosition(queueSize[queuePos][1])
        local gridDistance = queueSize[queuePos][2] + 1

        -- Check four adjacent tiles
        for i = 1, 4 do
            local potentialPos = gridIdxPos + Vector(40, 0):Rotated(i * 90)
            local potentialIdx = room:GetGridIndex(potentialPos)

            -- If it's not in the idxTable and it's something she can walk towards, cache it
            if not idxTable[potentialIdx]
            and gridDistance <= gridlength
            and room:GetGridCollision(potentialIdx) == GridCollisionClass.COLLISION_NONE
            and potentialIdx ~= gridIdx then
                idxTable[potentialIdx] = gridDistance
                queueSize[#queueSize+1] = {potentialIdx, gridDistance}
            end
        end

        finishedIdx = queuePos
    end

    queueSize = idxTable
    idxTable = {}
    for v, _ in pairs(queueSize) do
        idxTable[#idxTable+1] = v
    end

    return idxTable
end

---@param olga EntityFamiliar
---@param data DogData
function DogBody:FindDogOwner(olga, data)
    local nearestPlayer = game:GetNearestPlayer(olga.Position)

    if not Util:IsWithin(olga, nearestPlayer.Position, DogBody.HAPPY_DISTANCE) then
        return
    end

    olga.SpawnerEntity = nearestPlayer
    olga.Player = nearestPlayer
    data.hasOwner = true

    local pData = Util:GetData(olga.Player, Util.ID)
    pData.hasDoggy = true

    Util:UpdateHandColor(nearestPlayer, olga:GetData().headSprite)
end

-- From Epiphany's Epiphany:PickupKill()
---@param pickup EntityPickup
function DogBody:KillPickup(pickup)
	sfxMan:Play(SoundEffect.SOUND_SHELLGAME)

	local effect = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pickup.Position, Vector.Zero, nil)
		:ToEffect() ---@cast effect EntityEffect
	effect.Timeout = pickup.Timeout

	local sprite = effect:GetSprite()
	sprite:Load(pickup:GetSprite():GetFilename(), true)
	sprite:Play("Collect", true)

	pickup.Velocity = Vector.Zero
	pickup.EntityCollisionClass = 0
	pickup:Remove()
end

-- Returns a boolean if the player object matches with the spawner entity of the pickup
---@param pickup EntityPickup
---@param objectID integer
---@param olga EntityFamiliar
function DogBody:DoesPickupMatch(pickup, objectID, olga)
    return pickup and pickup.Variant == PickupVariant.PICKUP_TAROTCARD and pickup.SubType == objectID
    and pickup.SpawnerEntity and pickup.SpawnerEntity:ToPlayer() and olga.Player
    and GetPtrHash(pickup.SpawnerEntity:ToPlayer()) == GetPtrHash(olga.Player)
end

---@param olga EntityFamiliar
---@param data DogData
function DogBody:TryFetching(olga, data)
    if not data.targetPos then
        olga.State = Util.DogState.STANDING
        return
    end

    local pathfindingResult = DogBody:Pathfind(
        olga, data.targetPos, DogBody.RUN_SPEED, data, DogBody.FETCH_RADIUS, ONE_TILE, DogBody.DECAY_STRENGTH
    )

    if pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL then
        olga.Velocity = Vector.Zero

        -- Used to make her stop staying at the area when the object does not exist
        if data.eventWindow <= 0 then
            DogBody:ReturnToDefault(olga, data)
        else
            data.eventWindow = data.eventWindow - 1
        end

        -- If the object does exist then...
        for _, item in ipairs(Isaac.FindInRadius(olga.Position, ONE_TILE * 1.5, EntityPartition.PICKUP)) do
            local pickup = item:ToPickup() ---@cast pickup EntityPickup

            if DogBody:DoesPickupMatch(pickup, data.objectID, olga) then
                if data.headSprite:IsEventTriggered("Pickup") then
                    data.headSprite:Play(Util.HeadAnim.HOLD)
                    DogBody:KillPickup(pickup)
                    data.targetPos = nil
                    olga.State = Util.DogState.RETURN
                    return
                end

                if not data.headSprite:IsPlaying(Util.HeadAnim.GRAB) then
                    data.headSprite:Play(Util.HeadAnim.GRAB)
                end
            end
        end

    elseif pathfindingResult == DogBody.PathfindingResult.NO_PATH then
        DogBody:EndFetch(olga, data)
        olga.State = Util.DogState.STANDING
    end
end

---@param olga EntityFamiliar
function DogBody:EndFetch(olga, data)
    olga.Velocity = Vector.Zero
    data.targetPos = nil
    data.eventCD = olga.FrameCount + DogBody.EVENT_COOLDOWN

    if olga.State == Util.DogState.RETURN
    and data.headSprite then
        data.headSprite:Play(Util.HeadAnim.HOLD_TO_IDLE)
        return
    end

    data.objectID = nil
end

---@return Vector?
---@param idxTable table
---@param startingPos Vector
function DogBody:FindNearestPosition(idxTable, startingPos)
    local nearestPos
    local shortestDistance

    if not idxTable then
        return nil
    end

    for _, gridIdx in ipairs(idxTable) do
        local room = Mod.Room()
        local position = room:GetGridPosition(gridIdx)
        local distance = startingPos:DistanceSquared(position)

        if not shortestDistance or distance < shortestDistance then
            shortestDistance = distance
            nearestPos = position
        end
    end

    return nearestPos
end

---@param olga EntityFamiliar
---@param data DogData
function DogBody:TryApproachBowl(olga, data)
    if not data.targetPos then
        olga.State = Util.DogState.STANDING
        return
    end

    local pathfindingResult = DogBody:Pathfind(
        olga, data.targetPos, DogBody.RUN_SPEED, data, ONE_TILE * 0.5, ONE_TILE, DogBody.DECAY_STRENGTH
    )

    if pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL then
        olga.Velocity = Vector.Zero

        local feedingBowl
        for _, entity in pairs(Isaac.FindInRadius(data.targetPos, 20)) do
            -- If it's a bowl and its not empty
            if entity.Type == EntityType.ENTITY_SLOT
            and entity.Variant == Mod.FeedingBowl.BOWL_VARIANT
            and not entity:ToSlot():GetSprite():IsFinished("Idle") then
                data.feedingBowl = entity:ToSlot()
                data.targetPos = nil
                olga.State = Util.DogState.EATING
                return
            end
        end

        if not feedingBowl then
            Util:RemoveBowlIndex(saveMan.GetRoomSave().filledBowls, data.targetPos)
            DogBody:ReturnToDefault(olga, data)
        end

    elseif pathfindingResult == DogBody.PathfindingResult.NO_PATH then
        olga.Velocity = Vector.Zero
        DogBody:ReturnToDefault(olga, data)
    end
end

---@param olga EntityFamiliar
---@param data DogData
---@param resetEventCD boolean?
function DogBody:ReturnToDefault(olga, data, resetEventCD)
    data.targetPos = nil
    olga.State = Util.DogState.STANDING
    if resetEventCD then
        data.eventCD = olga.FrameCount + DogBody.EVENT_COOLDOWN
    end
end

---@param length number
---@param sprite Sprite
function DogBody:PlayAnimation(length, sprite)
    if length > DogBody.RUN_LENGTH then
        sprite:Play(Util.BodyAnim.RUNNING)

    elseif length <= DogBody.RUN_LENGTH
    and length > 0.1 then
        sprite:Play(Util.BodyAnim.WALKING)

    elseif length <= 0.1 then
        sprite:Play(Util.BodyAnim.STAND)
    end
end

---@param olga EntityFamiliar
---@param data DogData
function DogBody:TryEating(olga, data)
    local bowlSprite = data.feedingBowl:GetSprite()
    local bowlAnimName = bowlSprite:GetAnimation()

    -- If the bowl is empty
    if bowlSprite:IsFinished("Idle")
    or bowlAnimName:find("ToIdle") then
        data.feedingBowl = nil
        DogBody:ReturnToDefault(olga, data, true)
        return
    end

    -- If the fill animation is finished
    if not data.headSprite:IsPlaying(Util.HeadAnim.GRAB)
    and bowlSprite:IsFinished() then
        data.headSprite:Play(Util.HeadAnim.GRAB)
    end

    -- Empty/Progress to the next capacity when she munches
    if not data.headSprite:IsEventTriggered("Pickup")
    or not bowlSprite:IsFinished() then
        return
    end

    local foodString
    if bowlAnimName:find("Capacity") then
        local capacityStart, capacityEnd = bowlAnimName:find("Capacity")
        foodString = bowlAnimName:sub(1, capacityStart - 1)

        -- If it's the last animation before it empties
        if bowlSprite:WasEventTriggered("Empty") then
            bowlSprite:Play(foodString .. "ToIdle")
            DogBody:EmptyBowl(olga, data)
            return
        end

        -- Otherwise, progress to the next capacity animation
        local capacityNumber = tonumber(bowlAnimName:sub(capacityEnd + 1))
        bowlSprite:Play(foodString .. "Capacity" .. tostring(capacityNumber + 1))
        local runSave = saveMan.GetRunSave()
        runSave.pupPoints = runSave.pupPoints and runSave.pupPoints + 1 or 1
        return
    end

    -- If it's the last animation before it empties
    if bowlSprite:WasEventTriggered("Empty") then
        bowlSprite:Play("Idle")
        DogBody:EmptyBowl(olga, data)
        return
    end

    foodString = bowlAnimName:sub(5)
    bowlSprite:Play(foodString .. "Capacity1")
end

---@param olga EntityFamiliar
---@param data DogData
function DogBody:EmptyBowl(olga, data)
    Util:RemoveBowlIndex(saveMan.GetRoomSave().filledBowls, data.feedingBowl)
    DogBody:ReturnToDefault(olga, data, true)
    data.feedingBowl = nil

    local runSave = saveMan.GetRunSave()
    runSave.pupPoints = runSave.pupPoints and runSave.pupPoints + 1 or 1
end
--#endregion