--#region Variables
local Mod = OlgaMod
local Util = OlgaMod.Util

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

DogBody.EVENT_COOLDOWN = ONE_SEC * 2

DogBody.PathfindingResult = {
    ERROR = -1,
    NO_PATH = 0,
    APPROACHING = 1,
    SUCCESSFUL = 2
}

--#endregion
--#region Olga Body State Functions

DogBody.ANIM_FUNC = {
    [Util.BodyAnim.SIT] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if DogBody:CanWag(data.headSprite:GetAnimation()) then
            Util:SetAnimation(olga, Util.BodyAnim.SIT_WAGGING)
        end

        if rng:RandomFloat() < DogBody.SWITCH_CHANCE
        and frame % 30 == 0
        or data.isHolding then
            Util:SetAnimation(olga, Util.BodyAnim.SIT_TO_STAND)
        end
    end,

    [Util.BodyAnim.SIT_WAGGING] = function(olga)
        local sprite = olga:GetSprite()
        if  sprite:IsEventTriggered("TransitionHook") and
        not Util:IsWithin(olga, olga.Player.Position, DogBody.HAPPY_DISTANCE) then
            Util:SetAnimation(olga, Util.BodyAnim.SIT)
        end
    end,

    [Util.BodyAnim.SIT_TO_STAND] = function(olga)
        local sprite = olga:GetSprite()
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            local _, terminal = string.find(animName, "To")
            local result = string.upper(string.sub(animName, terminal + 1, #animName))
            Util:SetAnimation(olga, Util.BodyAnim[result])
        end

        if sprite:IsPlaying(Util.BodyAnim.STAND_TO_SIT) then
            olga.State = Util.DogState.SITTING
        elseif sprite:IsPlaying(Util.BodyAnim.SIT_TO_STAND) then
            olga.State = Util.DogState.STANDING
        end
    end,

    [Util.BodyAnim.STAND] = function(olga)
        local data = olga:GetData()
        local rng = olga:GetDropRNG()
        local sprite = olga:GetSprite()

        if data.eventCD < olga.FrameCount then

            if not data.targetPos
            and (olga.FrameCount % ONE_SEC == 0 and rng:RandomFloat() < DogBody.WANDER_CHANCE) then
                data.targetPos = DogBody:ChooseRandomPosition(olga)
            elseif data.targetPos ~= nil then
                local pathfindingResult = DogBody:Pathfind(olga, data.targetPos, DogBody.WALK_SPEED, DogBody.DECAY_STRENGTH)

                print(pathfindingResult)
                if pathfindingResult == DogBody.PathfindingResult.SUCCESSFUL
                or pathfindingResult == DogBody.PathfindingResult.NO_PATH then
                    olga.Velocity = Vector.Zero
                    data.eventCD = olga.FrameCount + DogBody.EVENT_COOLDOWN
                    data.targetPos = nil
                end
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

        -- Animation
        if olga.Velocity:Length() > 0.1
        and data.isMoving == true then
            Util:SetAnimation(olga, Util.BodyAnim.WALKING)
            data.isMoving = false

        elseif data.isMoving == false
        and olga.Velocity:Length() < 0.1 then
            Util:SetAnimation(olga, Util.BodyAnim.STAND)
            data.isMoving = true
        end

        -- Switching
        if sprite:IsEventTriggered("TransitionHook")
        and rng:RandomFloat() < DogBody.SWITCH_CHANCE
        and olga.FrameCount % ONE_SEC == 0 then
            data.targetPos = nil
            olga.Velocity = Vector.Zero
            Util:SetAnimation(olga, Util.BodyAnim.STAND_TO_SIT)
        end
    end
}
DogBody.ANIM_FUNC[Util.BodyAnim.STAND_TO_SIT] = DogBody.ANIM_FUNC[Util.BodyAnim.SIT_TO_STAND]
DogBody.ANIM_FUNC[Util.BodyAnim.WALKING] = DogBody.ANIM_FUNC[Util.BodyAnim.STAND]

--#endregion
--#region Olga Callbacks and Functions
---@param olga EntityFamiliar
function DogBody:OnInit(olga)
    local data = olga:GetData()

    data.heldItemSprite = Sprite()
    data.eventCD = olga.FrameCount + DogBody.EVENT_COOLDOWN
    data.targetPos = nil
    data.isMoving = true
    data.isHolding = nil

    data.headSprite = Sprite()
    data.headSprite:Load("gfx/render_olga_head.anm2", true)
    Util:SetAnimation(olga, Util.HeadAnim.IDLE, true)

    olga:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DogBody.OnInit, Mod.Dog.VARIANT)

function DogBody:HandleNewRoom()
    local room = game:GetRoom()
    local roomtype = room:GetType()
    if roomtype  == RoomType.ROOM_ISAACS or roomtype == RoomType.ROOM_BARREN then
        if room:IsFirstVisit() then
            Isaac.Spawn(
                EntityType.ENTITY_FAMILIAR,
                Mod.Dog.VARIANT,
                0,
                room:GetCenterPos(),
                Vector.Zero,
                nil
            )
        end
    end

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        if room:IsInitialized() then
            local data = familiar:ToFamiliar():GetData()
            data.eventCD = 0
            data.targetPos = nil
            data.canPet = false
            familiar:ToFamiliar().Velocity = Vector.Zero
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DogBody.HandleNewRoom)

function DogBody:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local player = familiar:ToFamiliar().Player
        if player:HasTrinket(Mod.TRINKET_SUBTYPE, false) then return end

        local data = Util:GetData(player, "olgaMod")
        local room = game:GetRoom()
        local pos = room:FindFreePickupSpawnPosition(player.Position)
        data.hasDoggy = false
        familiar:Remove()
        Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TRINKET, Mod.TRINKET_SUBTYPE, pos, Vector.Zero, player)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DogBody.GoodbyeOlga)

---@param olga EntityFamiliar
function DogBody:HandleBodyLogic(olga)
    local data = olga:GetData()

    data.headSprite:Update()

    if not data.hasOwner then
        local nearestPlayer = game:GetNearestPlayer(olga.Position)
        if nearestPlayer.Position:Distance(olga.Position) < DogBody.HAPPY_DISTANCE then
            olga.SpawnerEntity = nearestPlayer
            olga.Player = nearestPlayer
            data.hasOwner = true

            local pData = Util:GetData(olga.Player, Util.ID)
            pData.hasDoggy = true

            Mod.PettingHand:UpdateHandColor()
        end
        return
    end

    DogBody.ANIM_FUNC[olga:GetSprite():GetAnimation()](olga)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DogBody.HandleBodyLogic, Mod.Dog.VARIANT)

---@param anim string
function DogBody:CanWag(anim)
    return anim == Util.HeadAnim.HAPPY or anim == Util.HeadAnim.PETTING
end

---@param olga EntityFamiliar
---@param target Vector
---@param speed number
---@param decay? number
function DogBody:Pathfind(olga, target, speed, decay)
    if not target then return DogBody.PathfindingResult.ERROR end

    local room = game:GetRoom()
    local pathfinder = olga:GetPathFinder()

    olga.FlipX = not (olga.Velocity.X < 0)

    if not pathfinder:HasPathToPos(target, true) then
        local gridIdx = room:GetGridIndex(olga.Position)
        if olga:CollidesWithGrid()
        and room:GetGridCollision(gridIdx) ~= GridCollisionClass.COLLISION_NONE then
            pathfinder:EvadeTarget(room:GetGridPosition(gridIdx))
        else
            return DogBody.PathfindingResult.NO_PATH
        end
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
    local room = game:GetRoom()
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