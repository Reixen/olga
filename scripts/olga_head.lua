--#region Variables
local Mod = OlgaDog

local game = Mod.Game
local sfxMan = Mod.SfxMan
local OLGA_HEAD = Mod.OlgaHead

OLGA_HEAD.FAMILIAR = Mod.Familiar

OLGA_HEAD.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")

OLGA_HEAD.YAWN_CHANCE = 1 / 60

local ONE_TILE = 40
OLGA_HEAD.HAPPY_DISTANCE = ONE_TILE * 2
OLGA_HEAD.PETTING_DISTANCE = ONE_TILE * 1.2

OLGA_HEAD.ANIM = {
    IDLE = "Idle",
    HAPPY = "Happy",
    HAPPY_TO_IDLE = "HappyToIdle",
    IDLE_TO_HAPPY = "IdleToHappy",
    YAWN = "Yawn",
    PETTING = "Petting",
    HAPPY_TO_PETTING = "HappyToPetting",
    PETTING_TO_HAPPY = "PettingToHappy",
}

OLGA_HEAD.STATES = {
    IDLE = 0,
    HAPPY = 1,
    HAPPY_TO_IDLE = 2,
    IDLE_TO_HAPPY = 3,
    YAWN = 4,
    PETTING = 5,
    HAPPY_TO_PETTING = 6,
    PETTING_TO_HAPPY = 7,
}

--#endregion
--#region Olga Callbacks and Functions

function OLGA_HEAD:SetState(olga, bepis)
    local data = olga:GetData()
    data.headState = OLGA_HEAD.STATES[bepis]
    data.headSprite:Play(OLGA_HEAD.ANIM[bepis], true)
end

--#endregion
--#region Olga Logic Callback

---@param olga EntityFamiliar
function OLGA_HEAD:OnInit(olga)
    local data = olga:GetData()
    data.headSprite = Sprite()
    data.headSprite:Load("gfx/olga_head.anm2", true)
    OLGA_HEAD:SetState(olga, "IDLE")
end

Mod:AddCallback(ModCallbacks.MC_FAMILIAR_INIT, OLGA_HEAD.OnInit, OLGA_HEAD.FAMILIAR)

---@param olga EntityFamiliar
function OLGA_HEAD:HandleHeadLogic(olga, offset)
    local player = olga.Player
    local playerDistance = player.Position:Distance(olga.Position)
    local data = olga:GetData()
    local headOffset = olga:GetNullOffset("head") 
    local worldPos = Isaac.WorldToScreen(olga.Position + headOffset)

    data.headSprite.FlipX = olga.FlipX
    data.headSprite:Render(worldPos)
    
    if data.headState == OLGA_HEAD.STATES.IDLE then
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()
        if playerDistance < OLGA_HEAD.HAPPY_DISTANCE then
            local room = game:GetRoom()
            if data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear() then
                OLGA_HEAD:SetState(olga, "IDLE_TO_HAPPY")
            end
        end

        if frame % 30 == 0 then
            if rng:RandomFloat() < OLGA_HEAD.YAWN_CHANCE then
                OLGA_HEAD:SetState(olga, "YAWN")
            end
        end
    end

    if data.headState == OLGA_HEAD.STATES.HAPPY then
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if playerDistance < OLGA_HEAD.PETTING_DISTANCE then
                OlgaDog:UpdateHandColor()
                OLGA_HEAD:SetState(olga, "HAPPY_TO_PETTING")

            elseif playerDistance > OLGA_HEAD.HAPPY_DISTANCE then
                OLGA_HEAD:SetState(olga, "HAPPY_TO_IDLE")

            end
        end
    end
    
    if data.headState == OLGA_HEAD.STATES.PETTING then
        if not data.isHappy then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isHappy = true
        end

        if data.headSprite:IsEventTriggered("TransitionHook") then
            if playerDistance > OLGA_HEAD.PETTING_DISTANCE then
                OLGA_HEAD:SetState(olga, "PETTING_TO_HAPPY")
                if data.isHappy and
                not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
                    player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
                    data.isHappy = nil
                end
            end
        end
    end

    -- petting/happy
    if data.headState == OLGA_HEAD.STATES.HAPPY_TO_PETTING then
        if data.headSprite:IsFinished(OLGA_HEAD.ANIM.HAPPY_TO_PETTING) then
            if playerDistance > OLGA_HEAD.PETTING_DISTANCE then
                OLGA_HEAD:SetState(olga, "PETTING_TO_HAPPY")

            else
                OLGA_HEAD:SetState(olga, "PETTING")

            end
        end
    end

    if data.headState == OLGA_HEAD.STATES.PETTING_TO_HAPPY then
        if data.headSprite:IsFinished(OLGA_HEAD.ANIM.PETTING_TO_HAPPY) then
            if playerDistance > OLGA_HEAD.PETTING_DISTANCE then
                OLGA_HEAD:SetState(olga, "HAPPY")

            else
                OLGA_HEAD:SetState(olga, "HAPPY_TO_PETTING")

            end
        end
    end

    if data.headState == OLGA_HEAD.STATES.IDLE_TO_HAPPY then
        if data.headSprite:IsFinished(OLGA_HEAD.ANIM.IDLE_TO_HAPPY) then
            OLGA_HEAD:SetState(olga, "HAPPY")
        end
    end

    if data.headState == OLGA_HEAD.STATES.HAPPY_TO_IDLE then
        if data.headSprite:IsFinished(OLGA_HEAD.ANIM.HAPPY_TO_IDLE) then
            OLGA_HEAD:SetState(olga, "IDLE")
        end
    end

    -- random events
    if data.headState == OLGA_HEAD.STATES.YAWN then
        if data.headSprite:IsFinished(OLGA_HEAD.ANIM.YAWN) then
            OLGA_HEAD:SetState(olga, "IDLE")
        end
    end
    
    if data.headSprite:IsEventTriggered("Yawn") then
        sfxMan:Play(OLGA_HEAD.SOUND_YAWN, 2)
    end
    
    -- insert here additional state checks, for example if state == OLGA_HEAD.STATES.WOOF then/if state == OLGA_HEAD.STATES.SHITTING_AND_CRYING then
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, OLGA_HEAD.HandleHeadLogic, OLGA_HEAD.FAMILIAR)
--#endregion