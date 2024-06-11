local Mod = RegisterMod("Olga", 1)
local game = Game()
local OLGA = {}

OLGA.FAMILIAR = Isaac.GetEntityVariantByName("Olga")
local PETTING_HAND_VARIANT = Isaac.GetEntityVariantByName("Petting Hand")
local ONE_TILE = 40

local sfx = SFXManager()
OLGA.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
OLGA.YAWN_CHANCE = 1 / 400
OLGA.WALK_SPEED = 2
OLGA.HAPPY_DISTANCE = 2 * ONE_TILE
OLGA.PETTING_DISTANCE = 1.1 * ONE_TILE

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

end

---@param olga EntityFamiliar
function OLGA:InitOlga(olga)
    -- Separate hand code
    --local hand = Isaac.Spawn(EntityType.ENTITY_EFFECT, PETTING_HAND_VARIANT, 0, olga.Position, Vector.Zero, olga)
    --hand.FollowParent(olga)
    --hand.Visible = false

end

Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, OLGA.InitOlga, OLGA.FAMILIAR)




---@param olga EntityFamiliar
function OLGA:HandleLogic(olga)
    local player = olga.Player
    local rng = olga:GetDropRNG()
    local sprite = olga:GetSprite()
    local state = olga.State

    if state == OLGA.STATES.IDLE then
        if player.Position:Distance(olga.Position) < OLGA.HAPPY_DISTANCE
        and sprite:IsEventTriggered("TransitionHook") then
            OLGA:SetState(olga, "IDLE_TO_HAPPY")
        else
            if rng:RandomFloat() < OLGA.YAWN_CHANCE then
                OLGA:SetState(olga, "YAWN")
            end
        end
    end

    if state == OLGA.STATES.HAPPY then
        if sprite:IsEventTriggered("TransitionHook") then
            if player.Position:Distance(olga.Position) < OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "HAPPY_TO_PETTING")
            elseif player.Position:Distance(olga.Position) > OLGA.HAPPY_DISTANCE then
                OLGA:SetState(olga, "HAPPY_TO_IDLE")
            end
        end
    end
    
    if state == OLGA.STATES.PETTING then
        if sprite:IsEventTriggered("TransitionHook") then
            if player.Position:Distance(olga.Position) > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "PETTING_TO_HAPPY")
            end
        end
    end

    if state == OLGA.STATES.HAPPY_TO_PETTING then
        if sprite:IsFinished(OLGA.ANIMATIONS.HAPPY_TO_PETTING) then
            if player.Position:Distance(olga.Position) > OLGA.PETTING_DISTANCE then
                OLGA:SetState(olga, "PETTING_TO_HAPPY")
            else
                OLGA:SetState(olga, "PETTING")
            end
        end
    end

    if state == OLGA.STATES.PETTING_TO_HAPPY then
        if sprite:IsFinished(OLGA.ANIMATIONS.PETTING_TO_HAPPY) then
            if player.Position:Distance(olga.Position) > OLGA.PETTING_DISTANCE then
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


--function OLGA:PettingHandUpdate(hand)
    --player = Isaac.GetPlayer(0)
    --hand.Visible = false

    --for _, doggy in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA.FAMILIAR)) do
        --if player.Position:Distance(doggy.Position) < OLGA.PETTING_DISTANCE then
            --hand.Visible = true
        --end
    --end
--end


--Mod:AddCallback(ModCallbacks.MC_POST_EFFECT_UPDATE, OLGA.PettingHandUpdate, PETTING_HAND_VARIANT)