--#region Variables
local Mod = OlgaDog

local game = Mod.Game
local sfxMan = Mod.SfxMan

local OLGA_HEAD = Mod.OlgaHead
local OLGA_BODY = Mod.OlgaBody

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
    IDLE_TO_HOLD = "IdleToHold",
    HOLD = "Hold",
    HOLD_TO_IDLE = "HoldToIdle"
}

--#endregion
--#region Olga Head State Functions
OLGA_HEAD.ANIM_FUNC = {
    ["Idle"] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if data.isHolding and not data.isFetching then
            OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.IDLE_TO_HOLD)
        end

        if OLGA_BODY:IsWithin(olga, OLGA_HEAD.HAPPY_DISTANCE) then
            local room = game:GetRoom()
            if  data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear()
            and data.canPet
            and not data.isHolding then
                OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.IDLE_TO_HAPPY)
            end
        else data.canPet = true end

        if frame % 30 == 0 and OLGA_HEAD:CanIdleAnimation(olga) then
            if rng:RandomFloat() < OLGA_HEAD.YAWN_CHANCE then
                OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.YAWN)
            end
        end
    end,

    ["Happy"] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if OLGA_BODY:IsWithin(olga, OLGA_HEAD.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor()
                OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.HAPPY_TO_PETTING)

            elseif not OLGA_BODY:IsWithin(olga, OLGA_HEAD.HAPPY_DISTANCE) then
                OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.HAPPY_TO_IDLE)
            end
        end
    end,

    ["HappyToIdle"] = function(olga) -- HAPPY_TO_IDLE
        local sprite = olga:GetData().headSprite
        local animName = sprite:GetAnimation()
        local data = olga:GetData()
        if sprite:IsFinished(animName) then
            local _, terminal = string.find(animName, "To")
            local result = string.upper(string.sub(animName, terminal + 1, #animName))
            OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM[result])
        end
    end,

    ["Yawn"] = function(olga) 
        local data = olga:GetData()
        local animName = data.headSprite:GetAnimation()
        if data.headSprite:IsFinished(animName) then
            OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.IDLE)
        end

        if data.headSprite:IsEventTriggered("Yawn") then
            sfxMan:Play(OLGA_HEAD.SOUND_YAWN, 2)
        end
    end,

    ["Petting"] = function(olga)
        local data = olga:GetData()
        local player = olga.Player

        if not data.isHappy then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isHappy = true
        end

        if data.headSprite:IsEventTriggered("TransitionHook") then
            if not OLGA_BODY:IsWithin(olga, OLGA_HEAD.PETTING_DISTANCE) then
                OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.PETTING_TO_HAPPY)
                if data.isHappy and
                not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
                    player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
                    data.isHappy = nil
                end
            end
        end
    end,

    ["Hold"] = function(olga) ---@param olga EntityFamiliar
        local data = olga:GetData()

        if not data.isFetching and not data.isHolding then
            OLGA_HEAD:SetAnimation(olga, OLGA_HEAD.ANIM.HOLD_TO_IDLE)
        end
    end,
}
OLGA_HEAD.ANIM_FUNC["IdleToHappy"] = OLGA_HEAD.ANIM_FUNC["HappyToIdle"]
OLGA_HEAD.ANIM_FUNC["HappyToPetting"] = OLGA_HEAD.ANIM_FUNC["HappyToIdle"]
OLGA_HEAD.ANIM_FUNC["PettingToHappy"] = OLGA_HEAD.ANIM_FUNC["HappyToIdle"]
OLGA_HEAD.ANIM_FUNC["IdleToHold"] = OLGA_HEAD.ANIM_FUNC["HappyToIdle"]
OLGA_HEAD.ANIM_FUNC["HoldToIdle"] = OLGA_HEAD.ANIM_FUNC["HappyToIdle"]

--#endregion
--#region Olga Callbacks and Functions

function OLGA_HEAD:SetAnimation(olga, anim)
    local data = olga:GetData()
    data.headAnim = anim
    data.headSprite:Play(anim, true)
end

---@param olga EntityFamiliar
function OLGA_HEAD:HandleHeadLogic(olga, offset)
    local data = olga:GetData()

    if not data.headSprite then return end -- For Sac altar

    data.headSprite.FlipX = olga.FlipX
    data.headSprite:Render(Isaac.WorldToScreen(olga.Position + olga:GetNullOffset("head")))
    if olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        data.headSprite.Scale = Vector(1.25, 1.25)
    else
        data.headSprite.Scale = Vector.One
    end

    OLGA_HEAD.ANIM_FUNC[data.headAnim](olga)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, OLGA_HEAD.HandleHeadLogic, Mod.Familiar)

function OLGA_HEAD:CanIdleAnimation(olga)
    return olga.State ~= OLGA_BODY.STATE.OBTAIN and olga.State ~= OLGA_BODY.STATE.RETRIEVE
end
--#endregion