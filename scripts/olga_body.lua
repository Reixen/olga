--#region Variables
local Mod = OlgaMod
local Util = OlgaMod.Util

local DogBody = {}
OlgaMod.Dog.Body = DogBody

local game = Mod.Game

DogBody.SWITCH_STANCE_CHANCE = 1 / 40
DogBody.WALK_SPEED = 0.4

local ONE_TILE = 40
local ONE_SEC = 60
DogBody.WANDER_RADIUS = ONE_TILE * 3
DogBody.HAPPY_DISTANCE = ONE_TILE * 2.2
DogBody.ROCK_RADIUS = ONE_TILE * 0.75

--#endregion
--#region Olga Body State Functions

DogBody.ANIM_FUNC = {
    [Util.BodyAnim.SIT] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if Util:CanWag(data) then
            Util:SetAnimation(olga, Util.BodyAnim.SIT_WAGGING)
        end

        if rng:RandomFloat() < DogBody.SWITCH_STANCE_CHANCE
        and frame % 30 == 0
        or data.isHolding then
            Util:SetAnimation(olga, Util.BodyAnim.SIT_TO_STAND)
        end
    end,

    [Util.BodyAnim.SIT_WAGGING] = function(olga)
        local sprite = olga:GetSprite()
        if  sprite:IsEventTriggered("TransitionHook") and
        not Util:IsWithin(olga, DogBody.HAPPY_DISTANCE) then
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
        local pathfinder = olga:GetPathFinder()
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        local sprite = olga:GetSprite()
        local room = game:GetRoom()

        if data.wanderCooldown > -1 then data.wanderCooldown = data.wanderCooldown - 1 end

        if not data.isFetching then -- If there is an item that needs fetching

            if data.wanderCooldown <= 0 and not data.isHolding then

                data.randomPosition = olga.Position + RandomVector() * (DogBody.WANDER_RADIUS / (math.random(100, 200) / 100))
                data.wanderCooldown = math.random(ONE_SEC * 2, ONE_SEC * 8)

                local projectedTile = room:GetGridIndex(data.randomPosition)
                if not data.randomPosition
                or not pathfinder:HasPathToPos(data.randomPosition, false) then
                    data.wanderCooldown = 0
                end

                -- if theres a gridEnt in that position then reset go create another position
                --local gridEnt = room:GetGridEntityFromPos(data.randomPosition)
                --if gridEnt and gridEnt.Position:Distance(data.randomPosition) < DogBody.ROCK_RADIUS 
                --and gridEnt.CollisionClass ~= GridCollisionClass.COLLISION_NONE then
                    --print("theres a gridEnt here")
                    --data.wanderCooldown = 0
                --end
            end

            if data.isHolding then data.randomPosition = olga.Player.Position end -- if holding an item, go towards player instead

            if data.randomPosition then
                if data.randomPosition:Distance(olga.Position) > (ONE_TILE * 0.5) then
                    pathfinder:FindGridPath(data.randomPosition, DogBody.WALK_SPEED * (data.isHolding and 1.5 or 1), 1, true)
                else --devay her speed when near the target
                    local walkSpeed = DogBody.WALK_SPEED / 1.3
                    pathfinder:FindGridPath(data.randomPosition, walkSpeed, 1, true)
                end

                olga.FlipX = math.abs((data.randomPosition - olga.Position):GetAngleDegrees()) < 90

                if data.isHolding and olga.Position:Distance(olga.Player.Position) < ONE_TILE
                or not pathfinder:HasPathToPos(olga.Player.Position) and data.isHolding then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.isHolding, olga.Position, Vector.Zero, nil)
                    data.isHolding = nil
                elseif olga.Velocity:Length() < 0.5
                or not pathfinder:HasPathToPos(data.randomPosition, false) then
                    olga.Velocity = Vector.Zero
                    olga.State = Util.DogState.STANDING
                    data.randomPosition = nil
                    data.wanderCooldown = ONE_SEC * 5
                end
            end
        else
            local gridEnt = room:GetGridEntityFromPos(data.isFetching)
            if not pathfinder:HasPathToPos(data.isFetching) or gridEnt then
                data.isFetching = nil
                data.isHolding = nil
                olga.State = Util.DogState.STANDING
                return
            end

            if olga.Position:Distance(data.isFetching) > ONE_TILE then
                pathfinder:FindGridPath(data.isFetching, DogBody.WALK_SPEED * 1.5, 1, true)
                olga.FlipX = math.abs((data.isFetching - olga.Position):GetAngleDegrees()) < 90
                olga.State = Util.DogState.OBTAIN
            else
                for _, item in ipairs(Isaac.FindInRadius(data.isFetching, ONE_TILE, EntityPartition.PICKUP)) do
                    if not item then
                        data.isFetching = nil 
                        data.isHolding = nil
                        olga.State = Util.DogState.STANDING
                        break
                    end
                    -- how do i check if theres nothing in that area bro
                    local pickup = item:ToPickup()
                    if pickup.SubType == data.isHolding then
                        pickup:Remove()
                        data.isFetching = nil
                        olga.State = Util.DogState.RETRIEVE
                        break
                    end
                end
            end
        end
        -- move towards the player
        --if playerDistance > DogBody.HAPPY_DISTANCE then
            --pathfinder:FindGridPath(player.Position, DogBody.WALK_SPEED, 1, true)
            --olga.FlipX = math.abs((player.Position - olga.Position):GetAngleDegrees()) < 90
        --else
            --local speedDecay = playerDistance / (12 / DogBody.WALK_SPEED)
            --olga.Velocity = (player.Position - olga.Position):Normalized() * speedDecay
        --end

        if olga.Velocity:Length() > 0.1
        and data.isMoving == true then
            Util:SetAnimation(olga, Util.BodyAnim.WALKING)
            data.isMoving = false

        elseif data.isMoving == false
        and olga.Velocity:Length() < 0.1 then
            Util:SetAnimation(olga, Util.BodyAnim.STAND)
            data.isMoving = true
        end

        if sprite:IsEventTriggered("TransitionHook")
        and rng:RandomFloat() < DogBody.SWITCH_STANCE_CHANCE
        and frame % 90 then
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

    olga.Player:GetData().hasDoggy = true

    data.heldItemSprite = Sprite()
    data.wanderCooldown = 0
    data.isMoving = true
    data.isHolding = nil

    data.headSprite = Sprite()
    data.headSprite:Load("gfx/olga_head.anm2", true)
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
            data.wanderCooldown = 0
            data.randomPosition = nil
            data.canPet = false
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DogBody.HandleNewRoom)

function DogBody:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        familiar:ToFamiliar().Player:GetData().hasDoggy = false
        familiar:Remove()
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
            data.hasOwner = true
            olga.Player = nearestPlayer
            Mod.PettingHand:UpdateHandColor()
        end
        return
    end

    DogBody.ANIM_FUNC[olga:GetSprite():GetAnimation()](olga)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DogBody.HandleBodyLogic, Mod.Dog.VARIANT)

function DogBody:Pathfind()
end