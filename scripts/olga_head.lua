--#region Variables
local Mod = OlgaMod

local DogHead = {}
OlgaMod.Dog.Head = DogHead

local Util = OlgaMod.Util

local game = Mod.Game
local sfxMan = Mod.SfxMan

local ONE_SEC = 30
DogHead.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DogHead.ANIM_CHANCE = 1 / 30
DogHead.MINI_ANIM_CHANCE = 1 / 3
DogHead.REPEAT_CHANCE = 1 / 5

local ONE_TILE = 40
DogHead.HAPPY_DISTANCE = ONE_TILE * 2
DogHead.PETTING_DISTANCE = ONE_TILE * 1.2
--#endregion
--#region Olga Head State Functions
DogHead.ANIM_FUNC = {
    [Util.HeadAnim.IDLE] = function(olga)
        local data = olga:GetData()
        local frameCount = olga.FrameCount
        local rng = olga:GetDropRNG()

        if data.isHolding and not data.isFetching then
            Util:SetAnimation(olga, Util.HeadAnim.IDLE_TO_HOLD, true)
        end

        if Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
            local room = Mod.Room()
            if  data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear()
            and data.canPet
            and not data.isHolding then
                Util:SetAnimation(olga, Util.HeadAnim.IDLE_TO_HAPPY, true)
            end
        else data.canPet = true end

        if Util:CanIdleAnimation(olga)
        and data.animCD < frameCount
        and data.headSprite:IsEventTriggered("TransitionHook") then
            if rng:RandomFloat() < DogHead.ANIM_CHANCE then
                if rng:RandomFloat() < DogHead.MINI_ANIM_CHANCE then
                    Util:DoMiniIdleAnim(olga)
                else
                    Util:SetAnimation(olga, Util.HeadAnim.YAWN, true)
                end
                data.animCD = olga.FrameCount + Util.ANIM_COOLDOWN
            end
        end
    end,

    [Util.HeadAnim.HAPPY] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor()
                Util:SetAnimation(olga, Util.HeadAnim.HAPPY_TO_PETTING, true)

            elseif not Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
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
            sfxMan:Play(DogHead.SOUND_YAWN, 1, 2, false, math.random(9, 12)/10)
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
            if not Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE) then
                Util:SetAnimation(olga, Util.HeadAnim.PETTING_TO_HAPPY, true)
                if data.isHappy and
                not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
                    player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
                    data.isHappy = nil
                end
            end
        end
    end,

    [Util.HeadAnim.EAR_FLICK_L] = function (olga) ---@param olga EntityFamiliar
        local data = olga:GetData()
        local sprite = data.headSprite ---@cast sprite Sprite
        local rng = olga:GetDropRNG()
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            if rng:RandomFloat() < DogHead.REPEAT_CHANCE then
                local _, terminal = string.find(animName, "_")
                local result = string.sub(animName, 1, terminal - 1)
                Util:DoMiniIdleAnim(olga, Util.MiniAnim[result])
            else
                Util:SetAnimation(olga, Util.HeadAnim.IDLE, true)
            end
        end

        if Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
            local room = Mod.Room()
            if  data.headSprite:IsEventTriggered("TransitionHook")
            and room:IsClear()
            and data.canPet
            and not data.isHolding then
                Util:SetAnimation(olga, Util.HeadAnim.IDLE_TO_HAPPY, true)
            end
        else data.canPet = true end
    end,

    -- Unused
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
DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_R] = DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_BOTH] = DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
DogHead.ANIM_FUNC[Util.HeadAnim.EAR_ROTATE_L] = DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
DogHead.ANIM_FUNC[Util.HeadAnim.EAR_ROTATE_R] = DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
DogHead.ANIM_FUNC[Util.HeadAnim.EAR_ROTATE_BOTH] = DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
-- Unused
DogHead.ANIM_FUNC[Util.HeadAnim.IDLE_TO_HOLD] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]
DogHead.ANIM_FUNC[Util.HeadAnim.HOLD_TO_IDLE] = DogHead.ANIM_FUNC[Util.HeadAnim.HAPPY_TO_IDLE]

--#endregion
--#region Olga Callback
---@param olga EntityFamiliar
---@param offset Vector
function DogHead:OnHeadRender(olga, offset)
    local data = olga:GetData()

    if not data.headSprite then return end -- For Sac altar

    local renderMode = Mod.Room():GetRenderMode()

    -- Water reflections
    if renderMode ~= RenderMode.RENDER_WATER_ABOVE and renderMode ~= RenderMode.RENDER_NORMAL then
        return
    end

    data.headSprite:Render(Isaac.WorldToRenderPosition(olga.Position + olga.PositionOffset + olga:GetNullOffset("head")) + offset)

    if Isaac.GetFrameCount() % 2 == 0 and not game:IsPaused() then
        data.headSprite.FlipX = olga.FlipX
        data.headSprite.Scale = olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and Vector(1.25, 1.25) or Vector.One
        data.headSprite:Update()

        DogHead.ANIM_FUNC[data.headSprite:GetAnimation()](olga)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DogHead.OnHeadRender, Mod.Dog.VARIANT)
