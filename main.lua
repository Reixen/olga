local Mod = RegisterMod("Olga", 1)
local game = Game()
local OLGA = {}

OLGA.FAMILIAR = Isaac.GetEntityVariantByName("Olga")
local PETTING_HAND_VARIANT = Isaac.GetEntityVariantByName("Petting Hand")
local ONE_TILE = 40

local sfx = SFXManager()
OLGA.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")

OLGA.YAWN_CHANCE = 1 / 60
OLGA.WALK_SPEED = 2
OLGA.HAPPY_DISTANCE = ONE_TILE * 2.2
OLGA.PETTING_DISTANCE = ONE_TILE * 1.2

OLGA.MOVE_SIZE = ONE_TILE * 0.6

OLGA.ANIMATIONS = {
    IDLE = "Idle",
    HAPPY = "Happy",
    HAPPY_TO_IDLE = "HappyToIdle",
    IDLE_TO_HAPPY = "IdleToHappy",
    YAWN = "Yawn",
    PETTING = "Petting",
    HAPPY_TO_PETTING = "HappyToPetting",
    PETTING_TO_HAPPY = "PettingToHappy"
}

OLGA.STATES = {
    IDLE = 0,
    HAPPY = 1,
    HAPPY_TO_IDLE = 2,
    IDLE_TO_HAPPY = 3,
    YAWN = 4,
    PETTING = 5,
    HAPPY_TO_PETTING = 6,
    PETTING_TO_HAPPY = 7
}

OLGA.PETTING_HAND_COLOR = {
    PINK = -1,
    WHITE = 0,
    BLACK = 1,
    BLUE = 2,
    RED = 3,
    GREEN = 4,
    GREY = 5,
    SHADOW = 6
}

OLGA.PETTING_HAND_COMPATIBILITY = {
    "MAGDALENE",
    "EDEN",
    "BLUEBABY",
    "SAMSON",
    "KEEPER"
}

function OLGA:HandleOlgaInBedroom()
    local room = game:GetRoom()
    local roomtype = room:GetType()
    if roomtype  == RoomType.ROOM_ISAACS or roomtype == RoomType.ROOM_BARREN then
        if room:IsFirstVisit() then
            Isaac.Spawn(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR, 0, room:GetCenterPos(), Vector.Zero, nil)
        end
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, OLGA.HandleOlgaInBedroom)


function OLGA:GoodbyeOlga()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR)) do
        familiar:Remove()
    end
end

Mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, OLGA.GoodbyeOlga)


---@param olga EntityFamiliar
function OLGA:CheckMoveVelocity(olga, movementVector)
    local room = game:GetRoom()
    local player = olga.Player

    local vec = movementVector or olga.Position - player.Position
    if player.Position:Distance(olga.Position) < OLGA.MOVE_SIZE then
        if olga.Velocity:Length() < 1e-3 then
            -- prevent getting stuck in corners
            vec = player.Position - olga.Position

            if vec:Length() < 1e-3 then
                vec = RandomVector() -- make sure she doesn't stand still when entering rooms
                vec = vec:Rotated(olga:GetDropRNG():RandomInt(45) - (45 / 2))
            end
        else
            vec = olga.Position
        end
    end
    
    local velocityToAdd = (vec:Normalized() * OLGA.WALK_SPEED)
    local projectedPosition = olga.Position + velocityToAdd * 5 -- for extra "padding" so that you can go behind it and it doesnt get stuck on walls
    local projectedTile = room:GetGridIndex(projectedPosition)

    return (not room:GetGridEntity(projectedTile) or room:GetGridEntity(projectedTile).CollisionClass == GridCollisionClass.COLLISION_NONE), velocityToAdd
end

---@param olga EntityFamiliar
function OLGA:InitOlga(olga)
end

Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, OLGA.InitOlga, OLGA.FAMILIAR)




---@param olga EntityFamiliar
function OLGA:HandleLogic(olga)
    local player = olga.Player
    local rng = olga:GetDropRNG()
    local sprite = olga:GetSprite()
    local state = olga.State
    local game = Game()
    local room = game:GetRoom()
    local frame = game:GetFrameCount()
    local playerDistance = player.Position:Distance(olga.Position)

    if state == OLGA.STATES.IDLE then
        if playerDistance < OLGA.HAPPY_DISTANCE
        and sprite:IsEventTriggered("TransitionHook")
        and room:IsClear() then
            OLGA:SetState(olga, "IDLE_TO_HAPPY")
        
        elseif frame % 30 == 0 and rng:RandomFloat() < OLGA.YAWN_CHANCE then
            OLGA:SetState(olga, "YAWN")
        end
    end

    if state == OLGA.STATES.HAPPY then
        if sprite:IsEventTriggered("TransitionHook") then
            if playerDistance < OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "HAPPY_TO_PETTING")

            elseif playerDistance > OLGA.HAPPY_DISTANCE then
                OLGA:SetState(olga, "HAPPY_TO_IDLE")

            end
        end
    end
    
    if state == OLGA.STATES.PETTING then
        if sprite:IsEventTriggered("TransitionHook") then
            if playerDistance > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "PETTING_TO_HAPPY")

            end
        end
    end

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

    if state == OLGA.STATES.YAWN then
        if sprite:IsFinished(OLGA.ANIMATIONS.YAWN) then
            OLGA:SetState(olga, "IDLE")
        end
    end
    
    if sprite:IsEventTriggered("Yawn") then
        sfx:Play(OLGA.SOUND_YAWN, 2)
    end

    -- insert here additional state checks, for example if state == OLGA.STATES.WOOF then/if state == OLGA.STATES.SHITTING_AND_CRYING then
end

Mod:AddCallback(ModCallbacks.MC_FAMILIAR_UPDATE, OLGA.HandleLogic, OLGA.FAMILIAR)

function OLGA:SetState(olga, bepis)
    olga.State = OLGA.STATES[bepis]
    olga:GetSprite():Play(OLGA.ANIMATIONS[bepis], true)
end

function OLGA:ChangeFamilyMember()
    OLGA:UpdateHandColor()
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, OLGA.ChangeFamilyMember, CollectibleType.COLLECTIBLE_CLICKER)

function OLGA:OnCollectible()
    OLGA:UpdateHandColor()
end
Mod:AddCallback(ModCallbacks.MC_PRE_ADD_COLLECTIBLE, OLGA.OnCollectible)


function OLGA:UpdateHandColor()

    for _, doggy in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR)) do
        local olga = doggy:ToFamiliar()
        local player = olga.Player
        local sprite = olga:GetSprite()
        local skinColor = player:GetBodyColor()
        local playerType = player:GetPlayerType()

        for string, value in pairs(OLGA.PETTING_HAND_COLOR) do

            if skinColor == value then
                string:lower()
                sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_" .. string .. ".png")
                break

            end
        end

        if Epiphany then
            for _, moddedString in pairs(OLGA.PETTING_HAND_COMPATIBILITY) do
                local fileName = moddedString:lower()

                if playerType == Epiphany.PlayerType.JUDAS then
                    sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_shadow.png")
                    break
                    
                elseif playerType == Epiphany.PlayerType[moddedString] then

                    sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_tr_" .. fileName .. ".png")
                    break

                end
            end
        end

        sprite:LoadGraphics()
    end
end

