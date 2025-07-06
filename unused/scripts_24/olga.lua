--#region Variables
local Mod = OlgaDog

local game = Mod.Game
local sfxMan = Mod.SfxMan

local OLGA = {}

OLGA.FAMILIAR = Mod.Familiar
OLGA.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")

OLGA.YAWN_CHANCE = 1 / 60
OLGA.SWITCH_STANCE_CHANCE = 1 / 30
OLGA.WALK_SPEED = 0.4

local ONE_TILE = 40
OLGA.HAPPY_DISTANCE = ONE_TILE * 2.2
OLGA.PETTING_DISTANCE = ONE_TILE * 1.2
OLGA.WANDER_RADIUS = ONE_TILE * 3
OLGA.MOVE_SIZE = ONE_TILE * 0.6

OLGA.ANIMATIONS = {
    IDLE = "Idle",
    HAPPY = "Happy",
    HAPPY_TO_IDLE = "HappyToIdle",
    IDLE_TO_HAPPY = "IdleToHappy",
    YAWN = "Yawn",
    PETTING = "Petting",
    HAPPY_TO_PETTING = "HappyToPetting",
    PETTING_TO_HAPPY = "PettingToHappy",
    STAND_IDLE = "StandIdle",
    IDLE_TO_STAND_IDLE = "IdleToStandIdle",
    STAND_IDLE_TO_IDLE = "StandIdleToIdle",
    WALKING = "Walking"
}

OLGA.STATES = {
    IDLE = 0,
    HAPPY = 1,
    HAPPY_TO_IDLE = 2,
    IDLE_TO_HAPPY = 3,
    YAWN = 4,
    PETTING = 5,
    HAPPY_TO_PETTING = 6,
    PETTING_TO_HAPPY = 7,
    STAND_IDLE = 8,
    IDLE_TO_STAND_IDLE = 9,
    STAND_IDLE_TO_IDLE = 10,
    WALKING = 11
}
--#endregion
--#region Olga Callbacks and Functions

function OLGA:SetState(olga, bepis)
    olga.State = OLGA.STATES[bepis]
    olga:GetSprite():Play(OLGA.ANIMATIONS[bepis], true)
end

function OLGA:HandleOlgaInBedroom()
    local room = game:GetRoom()
    local roomtype = room:GetType()
    if roomtype  == RoomType.ROOM_ISAACS or roomtype == RoomType.ROOM_BARREN then
        if room:IsFirstVisit() then
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR, 0, room:GetCenterPos(), Vector.Zero, nil)
        end
    end
    
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR)) do
        if room:IsInitialized() then
            familiar:ToFamiliar():GetData().wanderCooldown = 0
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OLGA.HandleOlgaInBedroom)

function OLGA:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR)) do
        familiar:Remove()
    end
end
--#endregion
--#region Olga Logic Callback

---@param olga EntityFamiliar
function OLGA:HandleLogic(olga)
    local player = olga.Player
    local sprite = olga:GetSprite()
    local state = olga.State
    local playerDistance = player.Position:Distance(olga.Position)
    local pathfinder = olga:GetPathFinder()
    local data = olga:GetData()
    
    if state == OLGA.STATES.IDLE then
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        if playerDistance < OLGA.HAPPY_DISTANCE then
            local room = game:GetRoom()
            if sprite:IsEventTriggered("TransitionHook")
            and room:IsClear() then
                OLGA:SetState(olga, "IDLE_TO_HAPPY")
            end
        elseif rng:RandomFloat() < OLGA.SWITCH_STANCE_CHANCE 
        and frame % 30 == 0 then
            OLGA:SetState(olga, "IDLE_TO_STAND_IDLE")
        end

        if frame % 30 == 0 then
            if rng:RandomFloat() < OLGA.YAWN_CHANCE then
                OLGA:SetState(olga, "YAWN")
            end
        end
    end

    if state == OLGA.STATES.HAPPY then
        if sprite:IsEventTriggered("TransitionHook") then
            if playerDistance < OLGA.PETTING_DISTANCE then
                OlgaDog:UpdateHandColor()
                OLGA:SetState(olga, "HAPPY_TO_PETTING")

            elseif playerDistance > OLGA.HAPPY_DISTANCE then
                OLGA:SetState(olga, "HAPPY_TO_IDLE")

            end
        end
    end
    
    if state == OLGA.STATES.PETTING then
        if data.isHappy == nil then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isHappy = true
        end

        if sprite:IsEventTriggered("TransitionHook") then
            if playerDistance > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "PETTING_TO_HAPPY")
                if data.isHappy == true 
                and not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
                    player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
                    data.isHappy = nil
                end
            end
        end
    end
    
    --movement when standing up

    if state == OLGA.STATES.STAND_IDLE
    or state == OLGA.STATES.WALKING then
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        
        if not data.wanderCooldown then 
            data.wanderCooldown = 0 
            data.isMoving = true
        end

        if data.wanderCooldown <= 0 then 
            data.randomPosition = olga.Position + RandomVector() * (OLGA.WANDER_RADIUS / (math.random(100, 200) / 100))
            data.wanderCooldown = math.random(150, 600)
            if not data.randomPosition 
            or not pathfinder:HasPathToPos(data.randomPosition, false) then
                print("no path dummy")
                data.wanderCooldown = 0
            end
        end
        data.wanderCooldown = data.wanderCooldown - 1

        if data.randomPosition then 
            if data.randomPosition:Distance(olga.Position) > 20 then
                pathfinder:FindGridPath(data.randomPosition, OLGA.WALK_SPEED, 1, true)
            else --devay her speed when near the target
                local walkSpeed = OLGA.WALK_SPEED / 1.3
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
        --if playerDistance > OLGA.HAPPY_DISTANCE then
            --pathfinder:FindGridPath(player.Position, OLGA.WALK_SPEED, 1, true)
            --olga.FlipX = math.abs((player.Position - olga.Position):GetAngleDegrees()) < 90
        --else
            --local speedDecay = playerDistance / (12 / OLGA.WALK_SPEED)
            --olga.Velocity = (player.Position - olga.Position):Normalized() * speedDecay
        --end
        
        if olga.Velocity:Length() > 0.1 
        and data.isMoving == true then
            OLGA:SetState(olga, "WALKING")
            data.isMoving = false

        elseif data.isMoving == false 
        and olga.Velocity:Length() < 0.1 then 
            OLGA:SetState(olga, "STAND_IDLE")
            data.isMoving = true
        end

        if sprite:IsEventTriggered("TransitionHook")
        and rng:RandomFloat() < OLGA.SWITCH_STANCE_CHANCE 
        and frame % 90 then
            olga.Velocity = Vector.Zero
            OLGA:SetState(olga, "STAND_IDLE_TO_IDLE")
        end

    end

    -- stand idle/idle
    if state == OLGA.STATES.IDLE_TO_STAND_IDLE then
        if sprite:IsFinished(OLGA.ANIMATIONS.IDLE_TO_STAND_IDLE) then
            OLGA:SetState(olga, "STAND_IDLE")
        end
    end

    if state == OLGA.STATES.STAND_IDLE_TO_IDLE then
        if sprite:IsFinished(OLGA.ANIMATIONS.STAND_IDLE_TO_IDLE) then
            OLGA:SetState(olga, "IDLE")
        end
    end
    
    -- petting/happy
    if state == OLGA.STATES.HAPPY_TO_PETTING then
        if sprite:IsFinished(OLGA.ANIMATIONS.HAPPY_TO_PETTING) then
            if playerDistance > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "PETTING_TO_HAPPY")

            else
                OLGA:SetState(olga, "PETTING")

            end
        end
    end

    if state == OLGA.STATES.PETTING_TO_HAPPY then
        if sprite:IsFinished(OLGA.ANIMATIONS.PETTING_TO_HAPPY) then
            if playerDistance > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "HAPPY")

            else
                OLGA:SetState(olga, "HAPPY_TO_PETTING")

            end
        end
    end

    if state == OLGA.STATES.IDLE_TO_HAPPY then
        if sprite:IsFinished(OLGA.ANIMATIONS.IDLE_TO_HAPPY) then
            OLGA:SetState(olga, "HAPPY")
        end
    end

    if state == OLGA.STATES.HAPPY_TO_IDLE then
        if sprite:IsFinished(OLGA.ANIMATIONS.HAPPY_TO_IDLE) then
            OLGA:SetState(olga, "IDLE")
        end
    end

    -- random events
    if state == OLGA.STATES.YAWN then
        if sprite:IsFinished(OLGA.ANIMATIONS.YAWN) then
            OLGA:SetState(olga, "IDLE")
        end
    end
    
    if sprite:IsEventTriggered("Yawn") then
        sfxMan:Play(OLGA.SOUND_YAWN, 2)
    end
    -- insert here additional state checks, for example if state == OLGA.STATES.WOOF then/if state == OLGA.STATES.SHITTING_AND_CRYING then
end
Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, OLGA.HandleLogic, OLGA.FAMILIAR)
--#endregion