--#region Variables
local Mod = OlgaDog

local game = Mod.Game

local OLGA_BODY = Mod.OlgaBody

OLGA_BODY.FAMILIAR = Mod.Familiar
OLGA_BODY.SWITCH_STANCE_CHANCE = 1 / 20
OLGA_BODY.WALK_SPEED = 0.4

local ONE_TILE = 40
OLGA_BODY.WANDER_RADIUS = ONE_TILE * 3
OLGA_BODY.HAPPY_DISTANCE = ONE_TILE * 2.2

OLGA_BODY.ANIM = {
    SIT = "Sit",
    SIT_WAGGING = "SitWagging",
    SIT_TO_STAND = "SitToStand",
    STAND_TO_SIT = "StandToSit",
    STAND = "Stand",
    WALKING = "Walking"
}

OLGA_BODY.STATES = {
    SIT = 0,
    SIT_WAGGING = 1,
    SIT_TO_STAND = 2,
    STAND_TO_SIT = 3,
    STAND = 4,
    WALKING = 5
}

--#endregion
--#region Olga Callbacks and Functions

function OLGA_BODY:SetState(olga, bepis)
    olga.State = OLGA_BODY.STATES[bepis]
    olga:GetSprite():Play(OLGA_BODY.ANIM[bepis], true)
end

function OLGA_BODY:HandleNewRoom()
    local room = game:GetRoom()
    local roomtype = room:GetType()
    local player = Isaac.GetPlayer()
    if roomtype  == RoomType.ROOM_ISAACS or roomtype == RoomType.ROOM_BARREN then
        if room:IsFirstVisit() then
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, OLGA_BODY.FAMILIAR, 0, room:GetCenterPos(), Vector.Zero, nil)
        end
    end
    
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA_BODY.FAMILIAR)) do
        if room:IsInitialized() then
            familiar:ToFamiliar():GetData().wanderCooldown = 0
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OLGA_BODY.HandleNewRoom)

function OLGA_BODY:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA_BODY.FAMILIAR)) do
        familiar:Remove()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, OLGA_BODY.GoodbyeOlga)
    
--#endregion
--#region Olga Logic Callback
---@param olga EntityFamiliar
function OLGA_BODY:HandleBodyLogic(olga)
    local player = olga.Player
    local sprite = olga:GetSprite()
    local state = olga.State
    local playerDistance = player.Position:Distance(olga.Position)
    local pathfinder = olga:GetPathFinder()
    local data = olga:GetData()
    
    data.headSprite:Update()
    
    if not data.hasOwner then
        local nearestPlayer = game:GetNearestPlayer(olga.Position)
        if nearestPlayer.Position:Distance(olga.Position) < OLGA_BODY.HAPPY_DISTANCE then
            olga.SpawnerEntity = nearestPlayer
            data.hasOwner = true
            olga.Player = nearestPlayer
            OlgaDog:UpdateHandColor()
        end
        return
    end

    if state == OLGA_BODY.STATES.SIT then
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if  data.headState == Mod.OlgaHead.STATES.HAPPY or
            data.headState == Mod.OlgaHead.STATES.PETTING then
            OLGA_BODY:SetState(olga, "SIT_WAGGING")
        end

        if rng:RandomFloat() < OLGA_BODY.SWITCH_STANCE_CHANCE 
        and frame % 30 == 0 then
            OLGA_BODY:SetState(olga, "SIT_TO_STAND")
        end
    end

    --movement when standing up

    if state == OLGA_BODY.STATES.STAND 
    or state == OLGA_BODY.STATES.WALKING then
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        
        if not data.wanderCooldown then 
            data.wanderCooldown = 0
            data.isMoving = true
        end

        if data.wanderCooldown <= 0 then 
            data.randomPosition = olga.Position + RandomVector() * (OLGA_BODY.WANDER_RADIUS / (math.random(100, 200) / 100))
            data.wanderCooldown = math.random(90, 300)
            if not data.randomPosition 
            or not pathfinder:HasPathToPos(data.randomPosition, false) then
                data.wanderCooldown = 0
            end
        end
        data.wanderCooldown = data.wanderCooldown - 1

        if data.randomPosition then 
            if data.randomPosition:Distance(olga.Position) > 20 then
                pathfinder:FindGridPath(data.randomPosition, OLGA_BODY.WALK_SPEED, 1, true)
            else --devay her speed when near the target
                local walkSpeed = OLGA_BODY.WALK_SPEED / 1.3
                pathfinder:FindGridPath(data.randomPosition, walkSpeed, 1, true)
            end

            olga.FlipX = math.abs((data.randomPosition - olga.Position):GetAngleDegrees()) < 90
            
            if olga.Velocity:Length() < 0.1 
            or not pathfinder:HasPathToPos(data.randomPosition, false) then
                olga.Velocity = Vector.Zero
                data.randomPosition = nil
            end
        end

        -- move towards the player
        --if playerDistance > OLGA_BODY.HAPPY_DISTANCE then
            --pathfinder:FindGridPath(player.Position, OLGA_BODY.WALK_SPEED, 1, true)
            --olga.FlipX = math.abs((player.Position - olga.Position):GetAngleDegrees()) < 90
        --else
            --local speedDecay = playerDistance / (12 / OLGA_BODY.WALK_SPEED)
            --olga.Velocity = (player.Position - olga.Position):Normalized() * speedDecay
        --end
        

        if olga.Velocity:Length() > 0.1
        and data.isMoving == true then
            OLGA_BODY:SetState(olga, "WALKING")
            data.isMoving = false

        elseif data.isMoving == false 
        and olga.Velocity:Length() < 0.1 then 
            OLGA_BODY:SetState(olga, "STAND")
            data.isMoving = true
        end

        if sprite:IsEventTriggered("TransitionHook")
        and rng:RandomFloat() < OLGA_BODY.SWITCH_STANCE_CHANCE 
        and frame % 90 then
            olga.Velocity = Vector.Zero
            OLGA_BODY:SetState(olga, "STAND_TO_SIT")
        end

    end

    ---- stand idle/idle
    if state == OLGA_BODY.STATES.SIT_TO_STAND then
        if sprite:IsFinished(OLGA_BODY.ANIM.SIT_TO_STAND) then
            OLGA_BODY:SetState(olga, "STAND")
        end
    end

    if state == OLGA_BODY.STATES.STAND_TO_SIT then
        if sprite:IsFinished(OLGA_BODY.ANIM.STAND_TO_SIT) then
            OLGA_BODY:SetState(olga, "SIT")
        end
    end

    if state == OLGA_BODY.STATES.SIT_WAGGING then
        if  sprite:IsEventTriggered("TransitionHook") and
            playerDistance > OLGA_BODY.HAPPY_DISTANCE then
            OLGA_BODY:SetState(olga, "SIT")
        end
    end
    -- insert here additional state checks, for example if state == OLGA_BODY.STATES.WOOF then/if state == OLGA_BODY.STATES.SHITTING_AND_CRYING then
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, OLGA_BODY.HandleBodyLogic, OLGA_BODY.FAMILIAR)
--#endregion