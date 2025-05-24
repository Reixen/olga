--#region Variables
local Mod = OlgaDog

local game = Mod.Game
local sfxMan = Mod.SfxMan

local DOG_HEAD = Mod.OlgaHead
local DOG_BODY = Mod.OlgaBody

DOG_HEAD.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DOG_HEAD.YAWN_CHANCE = 1 / 60

local ONE_TILE = 40
DOG_HEAD.HAPPY_DISTANCE = ONE_TILE * 2
DOG_HEAD.PETTING_DISTANCE = ONE_TILE * 1.2

DOG_HEAD.ANIM = {
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
DOG_HEAD.ANIM_FUNC = {
    ["Idle"] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if data.isHolding and not data.isFetching then
            DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.IDLE_TO_HOLD)
        end

        if DOG_BODY:IsWithin(olga, DOG_HEAD.HAPPY_DISTANCE) then
            local room = game:GetRoom()
            if  data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear()
            and data.canPet
            and not data.isHolding then
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.IDLE_TO_HAPPY)
            end
        else data.canPet = true end

        if frame % 30 == 0 and DOG_HEAD:CanIdleAnimation(olga) then
            if rng:RandomFloat() < DOG_HEAD.YAWN_CHANCE then
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.YAWN)
            end
        end
    end,

    ["Happy"] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if DOG_BODY:IsWithin(olga, DOG_HEAD.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor()
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.HAPPY_TO_PETTING)

            elseif not DOG_BODY:IsWithin(olga, DOG_HEAD.HAPPY_DISTANCE) then
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.HAPPY_TO_IDLE)
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
            DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM[result])
        end
    end,

    ["Yawn"] = function(olga) 
        local data = olga:GetData()
        local animName = data.headSprite:GetAnimation()
        if data.headSprite:IsFinished(animName) then
            DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.IDLE)
        end

        if data.headSprite:IsEventTriggered("Yawn") then
            sfxMan:Play(DOG_HEAD.SOUND_YAWN, 2)
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
            if not DOG_BODY:IsWithin(olga, DOG_HEAD.PETTING_DISTANCE) then
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.PETTING_TO_HAPPY)
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
            DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.HOLD_TO_IDLE)
        end
    end,
}
DOG_HEAD.ANIM_FUNC["IdleToHappy"] = DOG_HEAD.ANIM_FUNC["HappyToIdle"]
DOG_HEAD.ANIM_FUNC["HappyToPetting"] = DOG_HEAD.ANIM_FUNC["HappyToIdle"]
DOG_HEAD.ANIM_FUNC["PettingToHappy"] = DOG_HEAD.ANIM_FUNC["HappyToIdle"]
DOG_HEAD.ANIM_FUNC["IdleToHold"] = DOG_HEAD.ANIM_FUNC["HappyToIdle"]
DOG_HEAD.ANIM_FUNC["HoldToIdle"] = DOG_HEAD.ANIM_FUNC["HappyToIdle"]

--#endregion
--#region Olga Callbacks and Functions

function DOG_HEAD:SetAnimation(olga, anim)
    local data = olga:GetData()
    data.headAnim = anim
    data.headSprite:Play(anim, true)
end

---@param olga EntityFamiliar
function DOG_HEAD:HandleHeadLogic(olga, offset)
    local data = olga:GetData()

    if not data.headSprite then return end -- For Sac altar

    data.headSprite.FlipX = olga.FlipX
    data.headSprite:Render(Isaac.WorldToScreen(olga.Position + olga:GetNullOffset("head")))
    if olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        data.headSprite.Scale = Vector(1.25, 1.25)
    else
        data.headSprite.Scale = Vector.One
    end

    DOG_HEAD.ANIM_FUNC[data.headAnim](olga)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DOG_HEAD.HandleHeadLogic, Mod.Familiar)

function DOG_HEAD:CanIdleAnimation(olga)
    return olga.State ~= DOG_BODY.STATE.OBTAIN and olga.State ~= DOG_BODY.STATE.RETRIEVE
end
--#endregion