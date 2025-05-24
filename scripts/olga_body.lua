--#region Variables
local Mod = OlgaDog

local game = Mod.Game
local DOG_HEAD = Mod.OlgaHead
local DOG_BODY = Mod.OlgaBody

DOG_BODY.SWITCH_STANCE_CHANCE = 1 / 40
DOG_BODY.WALK_SPEED = 0.4

local ONE_TILE = 40
local ONE_SEC = 60
DOG_BODY.WANDER_RADIUS = ONE_TILE * 3
DOG_BODY.HAPPY_DISTANCE = ONE_TILE * 2.2
DOG_BODY.ROCK_RADIUS = ONE_TILE * 0.75

DOG_BODY.ANIM = {
    SIT = "Sit",
    SIT_WAGGING = "SitWagging",
    SIT_TO_STAND = "SitToStand",
    STAND_TO_SIT = "StandToSit",
    STAND = "Stand",
    WALKING = "Walking"
}

DOG_BODY.STATE = {
    SITTING = 0,
    STANDING = 1,
    OBTAIN = 2,
    RETRIEVE = 3,
    
}

--#endregion
--#region Olga Body State Functions

DOG_BODY.ANIM_FUNC = {
    ["Sit"] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if DOG_BODY:CanWag(data) then
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.SIT_WAGGING)
        end

        if rng:RandomFloat() < DOG_BODY.SWITCH_STANCE_CHANCE
        and frame % 30 == 0
        or data.isHolding then
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.SIT_TO_STAND)
        end
    end,

    ["SitWagging"] = function(olga)
        local sprite = olga:GetSprite()
        if  sprite:IsEventTriggered("TransitionHook") and
        not DOG_BODY:IsWithin(olga, DOG_BODY.HAPPY_DISTANCE) then
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.SIT)
        end
    end,

    ["SitToStand"] = function(olga)
        local sprite = olga:GetSprite()
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            local _, terminal = string.find(animName, "To")
            local result = string.upper(string.sub(animName, terminal + 1, #animName))
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM[result])
        end

        if sprite:IsPlaying(DOG_BODY.ANIM.STAND_TO_SIT) then
            olga.State = DOG_BODY.STATE.SITTING
        elseif sprite:IsPlaying(DOG_BODY.ANIM.SIT_TO_STAND) then
            olga.State = DOG_BODY.STATE.STANDING
        end
    end,

    ["Stand"] = function(olga)
        local pathfinder = olga:GetPathFinder()
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        local sprite = olga:GetSprite()
        local room = game:GetRoom()

        if data.wanderCooldown > -1 then data.wanderCooldown = data.wanderCooldown - 1 end

        if not data.isFetching then -- If there is an item that needs fetching
            
            if data.wanderCooldown <= 0 and not data.isHolding then

                data.randomPosition = olga.Position + RandomVector() * (DOG_BODY.WANDER_RADIUS / (math.random(100, 200) / 100))
                data.wanderCooldown = math.random(ONE_SEC * 2, ONE_SEC * 8)
                
                local projectedTile = room:GetGridIndex(data.randomPosition)
                if not data.randomPosition
                or not pathfinder:HasPathToPos(data.randomPosition, false) then
                    data.wanderCooldown = 0
                end

                -- if theres a gridEnt in that position then reset go create another position
                --local gridEnt = room:GetGridEntityFromPos(data.randomPosition)
                --if gridEnt and gridEnt.Position:Distance(data.randomPosition) < DOG_BODY.ROCK_RADIUS 
                --and gridEnt.CollisionClass ~= GridCollisionClass.COLLISION_NONE then
                    --print("theres a gridEnt here")
                    --data.wanderCooldown = 0
                --end
            end

            if data.isHolding then data.randomPosition = olga.Player.Position end -- if holding an item, go towards player instead

            if data.randomPosition then
                if data.randomPosition:Distance(olga.Position) > (ONE_TILE * 0.5) then
                    pathfinder:FindGridPath(data.randomPosition, DOG_BODY.WALK_SPEED * (data.isHolding and 1.5 or 1), 1, true)
                else --devay her speed when near the target
                    local walkSpeed = DOG_BODY.WALK_SPEED / 1.3
                    pathfinder:FindGridPath(data.randomPosition, walkSpeed, 1, true)
                end

                olga.FlipX = math.abs((data.randomPosition - olga.Position):GetAngleDegrees()) < 90
                
                if data.isHolding and olga.Position:Distance(olga.Player.Position) < ONE_TILE
                or not pathfinder:HasPathToPos(olga.Player.Position) then
                    Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.isHolding, olga.Position, Vector.Zero, nil)
                    data.isHolding = nil
                elseif olga.Velocity:Length() < 0.5
                or not pathfinder:HasPathToPos(data.randomPosition, false) then
                    olga.Velocity = Vector.Zero
                    olga.State = DOG_BODY.STATE.STANDING
                    data.randomPosition = nil
                    data.wanderCooldown = ONE_SEC * 5
                end
            end
        else
            local gridEnt = room:GetGridEntityFromPos(data.isFetching)
            if not pathfinder:HasPathToPos(data.isFetching) or gridEnt then
                data.isFetching = nil
                data.isHolding = nil
                olga.State = DOG_BODY.STATE.STANDING
                return
            end

            if olga.Position:Distance(data.isFetching) > ONE_TILE then
                pathfinder:FindGridPath(data.isFetching, DOG_BODY.WALK_SPEED * 1.5, 1, true)
                olga.FlipX = math.abs((data.isFetching - olga.Position):GetAngleDegrees()) < 90
                olga.State = DOG_BODY.STATE.OBTAIN
            else
                for _, item in ipairs(Isaac.FindInRadius(data.isFetching, ONE_TILE, EntityPartition.PICKUP)) do
                    if not item then
                        data.isFetching = nil 
                        data.isHolding = nil
                        olga.State = DOG_BODY.STATE.STANDING
                        break
                    end
                    -- how do i check if theres nothing in that area bro
                    local pickup = item:ToPickup()
                    if pickup.SubType == data.isHolding then
                        pickup:Remove()
                        data.isFetching = nil
                        olga.State = DOG_BODY.STATE.RETRIEVE
                        break
                    end
                end
            end
        end
        -- move towards the player
        --if playerDistance > DOG_BODY.HAPPY_DISTANCE then
            --pathfinder:FindGridPath(player.Position, DOG_BODY.WALK_SPEED, 1, true)
            --olga.FlipX = math.abs((player.Position - olga.Position):GetAngleDegrees()) < 90
        --else
            --local speedDecay = playerDistance / (12 / DOG_BODY.WALK_SPEED)
            --olga.Velocity = (player.Position - olga.Position):Normalized() * speedDecay
        --end

        if olga.Velocity:Length() > 0.1
        and data.isMoving == true then
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.WALKING)
            data.isMoving = false

        elseif data.isMoving == false
        and olga.Velocity:Length() < 0.1 then
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.STAND)
            data.isMoving = true
        end

        if sprite:IsEventTriggered("TransitionHook")
        and rng:RandomFloat() < DOG_BODY.SWITCH_STANCE_CHANCE
        and frame % 90 then
            olga.Velocity = Vector.Zero
            DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.STAND_TO_SIT)
        end
    end
}
DOG_BODY.ANIM_FUNC["StandToSit"] = DOG_BODY.ANIM_FUNC["SitToStand"]
DOG_BODY.ANIM_FUNC["Walking"] = DOG_BODY.ANIM_FUNC["Stand"]

--#endregion
--#region Olga Callbacks and Functions

function DOG_BODY:SetAnimation(olga, anim)
    olga:GetData().bodyAnim = anim
    olga:GetSprite():Play(anim, true)
end

---@param olga EntityFamiliar
function DOG_BODY:OnInit(olga)
    local data = olga:GetData()
    olga.Player:GetData().hasDoggy = true
    
    data.heldItemSprite = Sprite()
    data.wanderCooldown = 0
    data.isMoving = true
    data.headAnim = DOG_HEAD.ANIM.IDLE
    data.bodyAnim = DOG_BODY.ANIM.SIT
    data.isHolding = nil

    data.headSprite = Sprite()
    data.headSprite:Load("gfx/olga_head.anm2", true)
    DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.IDLE)

    olga:AddEntityFlags(EntityFlag.FLAG_NO_KNOCKBACK | EntityFlag.FLAG_NO_PHYSICS_KNOCKBACK)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, DOG_BODY.OnInit, Mod.Familiar)

function DOG_BODY:HandleNewRoom()
    local room = game:GetRoom()
    local roomtype = room:GetType()
    if roomtype  == RoomType.ROOM_ISAACS or roomtype == RoomType.ROOM_BARREN then
        if room:IsFirstVisit() then
            Isaac.Spawn(
                EntityType.ENTITY_FAMILIAR,
                Mod.Familiar,
                0,
                room:GetCenterPos(room:GetCenterPos()),
                Vector.Zero,
                nil
            )
        end
    end
    
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Familiar)) do
        if room:IsInitialized() then
            local data = familiar:ToFamiliar():GetData()
            data.wanderCooldown = 0
            data.randomPosition = nil
            data.canPet = false
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DOG_BODY.HandleNewRoom)

function DOG_BODY:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Familiar)) do
        familiar:ToFamiliar().Player:GetData().hasDoggy = false
        familiar:Remove()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, DOG_BODY.GoodbyeOlga)
    
---@param olga EntityFamiliar
function DOG_BODY:HandleBodyLogic(olga)
    local data = olga:GetData()
    
    data.headSprite:Update()
    
    if not data.hasOwner then
        local nearestPlayer = game:GetNearestPlayer(olga.Position)
        if nearestPlayer.Position:Distance(olga.Position) < DOG_BODY.HAPPY_DISTANCE then
            olga.SpawnerEntity = nearestPlayer
            data.hasOwner = true
            olga.Player = nearestPlayer
            Mod.PettingHand:UpdateHandColor()
        end
        return
    end

    DOG_BODY.ANIM_FUNC[data.bodyAnim](olga)
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, DOG_BODY.HandleBodyLogic, Mod.Familiar)

function DOG_BODY:CanWag(data)
    return data.headAnim == DOG_HEAD.ANIM.HAPPY or data.headAnim == DOG_HEAD.ANIM.PETTING
end

---@param olga EntityFamiliar
---@param distance number
function DOG_BODY:IsWithin(olga, distance)
    return olga.Player.Position:DistanceSquared(olga.Position) < distance ^ 2
end

function DOG_BODY:FindFreeTile()

end
