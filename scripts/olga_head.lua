--#region Variables
local Mod = OlgaMod

local DogHead = {}
OlgaMod.Dog.Head = DogHead

local Util = OlgaMod.Util

local game = Mod.Game
local sfxMan = Mod.SfxMan

DogHead.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DogHead.YAWN_CHANCE = 1 / 60

local ONE_TILE = 40
DogHead.HAPPY_DISTANCE = ONE_TILE * 2
DogHead.PETTING_DISTANCE = ONE_TILE * 1.2
--#endregion
--#region Olga Head State Functions
DogHead.ANIM_FUNC = {
    [Util.HeadAnim.IDLE] = function(olga)
        local data = olga:GetData()
        local frame = game:GetFrameCount()
        local rng = olga:GetDropRNG()

        if data.isHolding and not data.isFetching then
            DogHead:SetAnimation(olga, Util.HeadAnim.IDLE_TO_HOLD)
        end

        if Util:IsWithin(olga, DogHead.HAPPY_DISTANCE) then
            local room = game:GetRoom()
            if  data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear()
            and data.canPet
            and not data.isHolding then
                Util:SetAnimation(olga, Util.HeadAnim.IDLE_TO_HAPPY, true)
            end
        else data.canPet = true end

        if frame % 30 == 0 and Util:CanIdleAnimation(olga) then
            if rng:RandomFloat() < DogHead.YAWN_CHANCE then
                Util:SetAnimation(olga, Util.HeadAnim.YAWN, true)
            end
        end
    end,

    [Util.HeadAnim.HAPPY] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if Util:IsWithin(olga, DogHead.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor()
                Util:SetAnimation(olga, Util.HeadAnim.HAPPY_TO_PETTING, true)

            elseif not Util:IsWithin(olga, DogHead.HAPPY_DISTANCE) then
                Util:SetAnimation(olga, Util.HeadAnim.HAPPY_TO_IDLE, true)
            end
        end
    end,

    [Util.HeadAnim.HAPPY_TO_IDLE] = function(olga)
        local sprite = olga:GetData().headSprite
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            local _, terminal = string.find(animName, "To")
            local result = string.upper(string.sub(animName, terminal + 1, #animName))
            Util:SetAnimation(olga, Util.HeadAnim[result], true)
        end
    end,

    [Util.HeadAnim.YAWN] = function(olga)
        local data = olga:GetData()
        local animName = data.headSprite:GetAnimation()
        if data.headSprite:IsFinished(animName) then
            Util:SetAnimation(olga, Util.HeadAnim.IDLE, true)
        end

        if data.headSprite:IsEventTriggered("Yawn") then
            sfxMan:Play(DogHead.SOUND_YAWN, 2)
        end
    end,

    [Util.HeadAnim.PETTING] = function(olga)
        local data = olga:GetData()
        local player = olga.Player

        if not data.isHappy then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isHappy = true
        end

        if data.headSprite:IsEventTriggered("TransitionHook") then
            if not Util:IsWithin(olga, DogHead.PETTING_DISTANCE) then
                Util:SetAnimation(olga, Util.HeadAnim.PETTING_TO_HAPPY, true)
                if data.isHappy and
                not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
                    player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
                    data.isHappy = nil
                end
            end
        end
    end,

    [Util.HeadAnim.HOLD] = function(olga) ---@param olga EntityFamiliar
        local data = olga:GetData()

        if not data.isFetching and not data.isHolding then
            Util:SetAnimation(olga, Util.HeadAnim.HOLD_TO_IDLE, true)
        end
    end,
}
DogHead.ANIM_FUNC[Util.HeadAnim.IDLE_TO_HAPPY] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]
DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_PETTING] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]
DogHead.ANIM_FUNC[Util.HeadAnim.PETTING_TO_HAPPY] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]
DogHead.ANIM_FUNC[Util.HeadAnim.IDLE_TO_HOLD] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]
DogHead.ANIM_FUNC[Util.HeadAnim.HOLD_TO_IDLE] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]

--#endregion
--#region Olga Callback
---@param olga EntityFamiliar
function DogHead:HandleHeadLogic(olga)
    local data = olga:GetData()

    if not data.headSprite then return end -- For Sac altar

    data.headSprite.FlipX = olga.FlipX
    data.headSprite:Render(Isaac.WorldToScreen(olga.Position + olga:GetNullOffset("head")))
    if olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) then
        data.headSprite.Scale = Vector(1.25, 1.25)
    else
        data.headSprite.Scale = Vector.One
    end

    DogHead.ANIM_FUNC[data.headSprite:GetAnimation()](olga)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DogHead.HandleHeadLogic, Mod.Dog.VARIANT)