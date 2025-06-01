--#region Variables
local Mod = OlgaMod

local DogHead = {}
OlgaMod.Dog.Head = DogHead

local Util = OlgaMod.Util

local game = Mod.Game
local sfxMan = Mod.SfxMan

DogHead.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DogHead.SOUND_BARK = Isaac.GetSoundIdByName("Olga Bark")

DogHead.ANIM_CHANCE = 1 / 30
DogHead.MINI_ANIM_CHANCE = 1 / 4
DogHead.REPEAT_CHANCE = 1 / 6

local ONE_TILE = 40
DogHead.HAPPY_DISTANCE = ONE_TILE * 2
DogHead.PETTING_DISTANCE = ONE_TILE * 1.2

DogHead.IdleAnim = {
    "Yawn",
    "Bark"
}

DogHead.MiniIdleVariants = {
    {"EarFlick", {"Left", "Right", "Both"}},
    {"EarRotate", {"Left", "Right", "Both"}}
}

DogHead.MiniIdle = {}
for i, value in ipairs(DogHead.MiniIdleVariants) do
    DogHead.MiniIdle[value[1]] = i
end

--#endregion
--#region Olga Head State Functions
-- Space Complexity final boss
DogHead.ANIM_FUNC = {
    [Util.HeadAnim.IDLE] = function(olga)
        local data = olga:GetData()
        local frameCount = olga.FrameCount
        local rng = olga:GetDropRNG()

        if data.isHolding and not data.isFetching then
            data.headSprite:Play(Util.HeadAnim.IDLE_TO_HOLD, true)
        end

        DogHead:TryTurningGlad(olga, data)

        if not data.headSprite:IsEventTriggered("TransitionHook")
        or not DogHead:CanIdleAnimation(olga)
        or data.animCD > frameCount then
            return
        end

        if rng:RandomFloat() < DogHead.ANIM_CHANCE then

            if rng:RandomFloat() < DogHead.MINI_ANIM_CHANCE then
                DogHead:DoMiniIdleAnim(data.headSprite)
            else
                data.headSprite:Play(DogHead.IdleAnim[math.random(#DogHead.IdleAnim)], true)
            end
            data.animCD = olga.FrameCount + Util.ANIM_COOLDOWN
        end
    end,

    [Util.HeadAnim.GLAD] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsEventTriggered("TransitionHook") then
            if Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor()
                data.headSprite:Play(Util.HeadAnim.GLAD_TO_GLAD_PETTING, true)

            elseif not Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
                data.headSprite:Play(Util.HeadAnim.GLAD_TO_IDLE, true)
            end
        end
    end,

    [Util.HeadAnim.GLAD_PETTING] = function(olga)
        local data = olga:GetData()
        local player = olga.Player

        data.attentionCD = olga.FrameCount + Util.ATTENTION_COOLDOWN

        if not data.isPetting then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isPetting = true
        end

        if not data.headSprite:IsEventTriggered("TransitionHook")
        or Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE) then
            return
        end

        local pettingVariant, _ = string.find(data.headSprite:GetAnimation(), Util.HeadAnim.GLAD)
        local animTransition = pettingVariant and Util.HeadAnim.GLAD_PETTING_TO_GLAD or Util.HeadAnim.PETTING_TO_IDLE
        data.headSprite:Play(animTransition, true)

        if data.isPetting and not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
            player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
            data.isPetting = nil
        end
    end,

    -- Transitional animations
    [Util.HeadAnim.GLAD_TO_IDLE] = function(olga)
        local sprite = olga:GetData().headSprite
        local animName = sprite:GetAnimation()
        if sprite:IsFinished(animName) then
            local animToPlay = Util:FindAnimSubstring(animName)
            sprite:Play(Util.HeadAnim[animToPlay], true)
        end
    end,

    -- Standard idle animations
    [Util.HeadAnim.YAWN] = function(olga)
        local data = olga:GetData()
        if data.headSprite:IsFinished(data.headSprite:GetAnimation()) then
            data.headSprite:Play(Util.HeadAnim.IDLE, true)
        end

        if data.headSprite:IsEventTriggered("Yawn") then
            sfxMan:Play(DogHead.SOUND_YAWN, 1, 2, false, math.random(9, 12)/10)
        end

        if data.headSprite:IsEventTriggered("Bark") then
            sfxMan:Play(DogHead.SOUND_BARK, 1.5, 2, false, 1)
        end
    end,

    -- Mini idle animations
    [Util.HeadAnim.EAR_FLICK_L] = function (olga) ---@param olga EntityFamiliar
        local data = olga:GetData()
        local sprite = data.headSprite ---@cast sprite Sprite
        local animName = sprite:GetAnimation()

        if sprite:IsFinished(animName) then
            local rng = olga:GetDropRNG()
            if rng:RandomFloat() < DogHead.REPEAT_CHANCE then
                local animToPlay = Util:FindAnimSubstring(animName, true)
                DogHead:DoMiniIdleAnim(sprite, DogHead.MiniIdle[animToPlay])
            else
                sprite:Play(Util.HeadAnim.IDLE, true)
            end
        end

        DogHead:TryTurningGlad(olga, data)
    end,

    -- Unused
    [Util.HeadAnim.HOLD] = function(olga) ---@param olga EntityFamiliar
        local data = olga:GetData()

        if not data.isFetching and not data.isHolding then
            data.headSprite:Play(Util.HeadAnim.HOLD_TO_IDLE, true)
        end
    end,
}
DogHead.ANIM_FUNC[Util.HeadAnim.PETTING] = DogHead.ANIM_FUNC[Util.HeadAnim.GLAD_PETTING]

Util:FillEmptyAnimFunctions(
    Util.HeadAnim,
    DogHead.ANIM_FUNC,
    DogHead.ANIM_FUNC[Util.HeadAnim.GLAD_TO_IDLE],
    DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L],
    DogHead.ANIM_FUNC[Util.HeadAnim.YAWN]
)

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

    if not (Isaac.GetFrameCount() % 2 == 0) or game:IsPaused() then return end

    data.headSprite.FlipX = olga.FlipX
    data.headSprite.Scale = olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and Vector(1.25, 1.25) or Vector.One
    data.headSprite:Update()

    DogHead.ANIM_FUNC[data.headSprite:GetAnimation()](olga)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DogHead.OnHeadRender, Mod.Dog.VARIANT)
--#endregion
--#region Olga Helper Functions

---@param olga EntityFamiliar
function DogHead:CanIdleAnimation(olga)
    return olga.State ~= Util.DogState.OBTAIN and olga.State ~= Util.DogState.RETRIEVE
end

---@param sprite Sprite
---@param anim integer?
function DogHead:DoMiniIdleAnim(sprite, anim)
    local animGamble = not anim and DogHead.MiniIdleVariants[math.random(#DogHead.MiniIdleVariants)] or DogHead.MiniIdleVariants[anim]
    local name, variants = table.unpack(animGamble)
    sprite:Play(name .. "_" .. variants[math.random(#variants)], true)
end

---@param olga EntityFamiliar
---@param data table
function DogHead:TryTurningGlad(olga, data)
    local room = Mod.Room()
    if not data.headSprite:IsEventTriggered("TransitionHook") or not room:IsClear()
    or not data.canPet or data.isHolding then
        data.canPet = true
        return
    end

    -- If shes not due for an alternate petting animation
    if data.attentionCD > olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
        data.attentionCD = olga.FrameCount + Util.ATTENTION_COOLDOWN
        Mod.PettingHand:UpdateHandColor()
        data.headSprite:Play(Util.HeadAnim.IDLE_TO_PETTING, true)
    elseif data.attentionCD < olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
        data.headSprite:Play(Util.HeadAnim.IDLE_TO_GLAD, true)
    end
end
--#endregion