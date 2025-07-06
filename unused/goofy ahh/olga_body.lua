--#region Variables
local Mod = OlgaMod
local Util = Mod.Util

local DogBody = {}
OlgaMod.Dog.Body = DogBody

local game = Mod.Game

DogBody.SWITCH_CHANCE = 1 / 40
DogBody.WANDER_CHANCE = 1 / 2
DogBody.WALK_SPEED = 0.4
DogBody.DECAY_STRENGTH = 1.3

local ONE_TILE = 40
local ONE_SEC = 30
DogBody.WANDER_RADIUS = 5
DogBody.HAPPY_DISTANCE = ONE_TILE * 2.2

DogBody.EVENT_COOLDOWN = ONE_SEC * 3

DogBody.PathfindingResult = {
    ERROR = -1,
    NO_PATH = 0,
    COLLIDING = 1,
    APPROACHING = 2,
    SUCCESSFUL = 3
}

--#endregion
--#region Olga Body Animation Functions
DogBody.ANIM_FUNC = {
    [Util.BodyAnim.SIT] = function(olga)
        local data = olga:GetData()
        local frameCount = olga.FrameCount
        local rng = olga:GetDropRNG()
        local sprite = olga:GetSprite()

        if DogBody:CanWag(data.headSprite:GetAnimation())
        or Util:IsWithin(olga, olga.Player.Position, ONE_TILE * 2) then
            sprite:Play(Util.BodyAnim.SIT_WAGGING, true)
        end

        if (rng:RandomFloat() < DogBody.SWITCH_CHANCE and frameCount % 30 == 0 and data.eventCD < frameCount)
        or data.isHolding then
            olga.State = Util.DogState.STANDING
            sprite:Play(Util.BodyAnim.SIT_TO_STAND, true)
        end
    end,

    [Util.BodyAnim.SIT_WAGGING] = function(olga)
        local sprite = olga:GetSprite()
        if  sprite:IsEventTriggered("TransitionHook") and
        not Util:IsWithin(olga, olga.Player.Position, DogBody.HAPPY_DISTANCE) then
            sprite:Play(Util.BodyAnim.SIT, true)
        end
    end,

    -- Movement animations
    [Util.BodyAnim.STAND] = function(olga)
        local data = olga:GetData()
        local rng = olga:GetDropRNG()
        local sprite = olga:GetSprite()
        local frameCount = olga.FrameCount

        -- Animations
        if olga.Velocity:Length() > 0.1
        and data.isMoving then
            sprite:Play(Util.BodyAnim.WALKING, true)
            data.isMoving = false

        elseif olga.Velocity:Length() <= 0.1
        and not data.isMoving then
            sprite:Play(Util.BodyAnim.STAND, true)
            data.isMoving = true
        end

        if data.eventCD < frameCount then

            -- Switching
            if sprite:IsEventTriggered("TransitionHook")
            and rng:RandomFloat() < DogBody.SWITCH_CHANCE
            and olga.FrameCount % ONE_SEC == 0 then
                data.targetPos = nil
                olga.Velocity = Vector.Zero
                data.eventCD = frameCount + DogBody.EVENT_COOLDOWN
                sprite:Play(Util.BodyAnim.STAND_TO_SIT, true)
                olga.State = Util.DogState.SITTING
            end

            if data.targetPos then
                local pathfindingResult = DogBody:Pathfind(olga, data, data.targetPos, DogBody.WALK_SPEED, DogBody.DECAY_STRENGTH)

                if pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL
                or pathfindingResult == DogBody.PathfindingResult.NO_PATH then
                    olga.Velocity = Vector.Zero
                    data.eventCD = frameCount + DogBody.EVENT_COOLDOWN
                    data.targetPos = nil
                elseif pathfindingResult == DogBody.PathfindingResult.COLLIDING then
                    print("at frame " .. tostring(olga.FrameCount))
                end
                return
            end

            if rng:RandomFloat() < DogBody.WANDER_CHANCE then
                data.targetPos = DogBody:ChooseRandomPosition(olga)
            end
        end

        --if not data.isFetching then -- If there is an item that needs fetching

            --if data.isHolding then data.randomPosition = olga.Player.Position end -- if holding an item, go towards player instead
            -- insert normal algo

            ---- Fetchin Algo
        --else
            --local gridEnt = room:GetGridEntityFromPos(data.isFetching)
            --if not pathfinder:HasPathToPos(data.isFetching) or gridEnt then
                --data.isFetching = nil
                --data.isHolding = nil
                --olga.State = Util.DogState.STANDING
                --return
            --end

            --if olga.Position:Distance(data.isFetching) > ONE_TILE then
                --pathfinder:FindGridPath(data.isFetching, DogBody.WALK_SPEED * 1.5, 1, true)
                --olga.FlipX = math.abs((data.isFetching - olga.Position):GetAngleDegrees()) < 90
                --olga.State = Util.DogState.OBTAIN
            --else
                --for _, item in ipairs(Isaac.FindInRadius(data.isFetching, ONE_TILE, EntityPartition.PICKUP)) do
                    --if not item then
                        --data.isFetching = nil 
                        --data.isHolding = nil
                        --olga.State = Util.DogState.STANDING
                        --break
                    --end
                    ---- how do i check if theres nothing in that area bro
                    --local pickup = item:ToPickup()
                    --if pickup.SubType == data.isHolding then
                        --pickup:GetSprite():Play("Collect")
                        --pickup:Die()
                        --data.isFetching = nil
                        --Isaac.CreateTimer(function()
                            --olga.State = Util.DogState.RETRIEVE
                        --end, 6, 1, false)
                        --break
                    --end
                --end
            --end
        --end
        -- move towards the player
        --if playerDistance > DogBody.HAPPY_DISTANCE then
            --pathfinder:FindGridPath(player.Position, DogBody.WALK_SPEED, 1, true)
            --olga.FlipX = math.abs((player.Position - olga.Position):GetAngleDegrees()) < 90
        --else
            --local speedDecay = playerDistance / (12 / DogBody.WALK_SPEED)
            --olga.Velocity = (player.Position - olga.Position):Normalized() * speedDecay
        --end
    end,

    -- Transitional animations
    [Util.BodyAnim.SIT_TO_STAND] = function(olga)
        local sprite = olga:GetSprite()
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            local animToPlay = Util:FindAnimSubstring(animName)
            sprite:Play(Util.BodyAnim[animToPlay], true)
        end
    end,
}
DogBody.ANIM_FUNC[Util.BodyAnim.STAND_TO_SIT] = DogBody.ANIM_FUNC[Util.BodyAnim.SIT_TO_STAND]
DogBody.ANIM_FUNC[Util.BodyAnim.WALKING] = DogBody.ANIM_FUNC[Util.BodyAnim.STAND]

-- Use when there's more animations
--Util:FillEmptyAnimFunctions(
    --Util.BodyAnim,
    --DogBody.ANIM_FUNC,
    --DogBody.ANIM_FUNC[Util.BodyAnim.SIT_TO_STAND]
--)

--#endregion
--#region Olga Head Animation Functions
--#endregion
--#region Olga Callbacks
---@param olga EntityFamiliar
function DogBody:OnInit(olga)
    local data = olga:GetData()

    data.heldItemSprite = Sprite()
    data.eventCD = DogBody.EVENT_COOLDOWN
    data.animCD = Util.ANIM_COOLDOWN
    data.attentionCD = 0
    data.targetPos = nil
    data.isHolding = nil

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

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local data = familiar:GetData()
        data.targetPos = nil
        data.canPet = false
        familiar.Velocity = Vector.Zero
    end

    if roomType == RoomType.ROOM_TREASURE then
        Isaac.Spawn(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT, 0, room:GetCenterPos(), Vector.Zero, nil)
        Isaac.Spawn( EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Mod.Pickup.STICK_ID, room:GetCenterPos() + Vector(0, 40), Vector.Zero, nil)
    end
    if (roomType ~= RoomType.ROOM_ISAACS and roomType ~= RoomType.ROOM_BARREN)
    or not room:IsFirstVisit() then
        return
    end

    Isaac.Spawn(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT, 0, room:GetCenterPos(), Vector.Zero, nil)
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DogBody.HandleNewRoom)

function DogBody:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do ---@cast familiar EntityFamiliar
        local data = familiar:GetData()
        data.hasStick = nil
        data.hasBall = nil

        if PlayerManager.AnyoneHasTrinket(Mod.Pickup.CRUDE_DRAWING_ID) then break end

        local pData = Util:GetData(familiar.Player, Mod.Util.ID)
        local room = Mod.Room()
        local pos = room:FindFreePickupSpawnPosition(room:GetCenterPos())
        pData.hasDoggy = false
        familiar:Remove()
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, Mod.Pickup.CRUDE_DRAWING_ID, pos, Vector.Zero, nil)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DogBody.GoodbyeOlga)

---@param olga EntityFamiliar
function DogBody:HandleBodyLogic(olga)
    local data = olga:GetData()

    DogBody.ANIM_FUNC[olga:GetSprite():GetAnimation()](olga)

    if data.hasOwner then return end
    DogBody:FindDogOwner(olga, data)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DogBody.HandleBodyLogic, Mod.Dog.VARIANT)
--#endregion
--#region Olga Helper Functions
---@param anim string
function DogBody:CanWag(anim)
    return anim == Util.HeadAnim.GLAD or anim == Util.HeadAnim.GLAD_PETTING
end

---@param olga EntityFamiliar
---@param data table
---@param target Vector
---@param speed number
---@param decay? number
function DogBody:Pathfind(olga, data, target, speed, decay)
    if not target then return DogBody.PathfindingResult.ERROR end

    local room = Mod.Room()
    local pathfinder = olga:GetPathFinder()
    local gridIdx = room:GetGridIndex(olga.Position)

    olga.FlipX = not (olga.Velocity.X < 0)

    if not pathfinder:HasPathToPos(target, true) then
        if not olga:CollidesWithGrid() and room:GetGridCollision(gridIdx) == GridCollisionClass.COLLISION_NONE then
            return DogBody.PathfindingResult.NO_PATH
        end

        --TODO: Give her a split second to pathfind out, then Vector.Zero to her Velocity
        if room:GetGridCollision(gridIdx) ~= GridCollisionClass.COLLISION_NONE then
            pathfinder:EvadeTarget(room:GetGridPosition(gridIdx))
            return DogBody.PathfindingResult.COLLIDING
        end

        -- Her last chance of escaping if it's an open position
        olga.Velocity = (room:GetGridPosition(gridIdx) - olga.Position):Resized(speed * 5)
        return DogBody.PathfindingResult.COLLIDING
    end

    if not Util:IsWithin(olga, target, ONE_TILE / 2) then
        pathfinder:FindGridPath(target, speed, 1, true)
        return DogBody.PathfindingResult.APPROACHING

    elseif not Util:IsWithin(olga, target, 1) then
        local input = math.ceil(olga.Position:Distance(target)) / 100
        local walkSpeed = decay and speed - decay * (speed * input) or speed
        olga:GetSprite().PlaybackSpeed = 1 * (1 - input)
        pathfinder:FindGridPath(target, walkSpeed, 1, true)
        return DogBody.PathfindingResult.APPROACHING

    else
        olga:GetSprite().PlaybackSpeed = 1
        return DogBody.PathfindingResult.SUCCESSFUL
    end
end

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

    local posVariance = math.random() < 0.5 and -15 or 15
    return chosenPos + (RandomVector() * posVariance)
end

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
---@param data table
function DogBody:FindDogOwner(olga, data)
    local nearestPlayer = game:GetNearestPlayer(olga.Position)

    if not Util:IsWithin(olga, nearestPlayer.Position, DogBody.HAPPY_DISTANCE) then
        return
    end

    olga.SpawnerEntity = nearestPlayer
    olga.Player = nearestPlayer
    data.hasOwner = true

    local pData = Util:GetData(olga.Player, "olgaMod")
    pData.hasDoggy = olga

    Mod.PettingHand:UpdateHandColor()
end
--#endregion