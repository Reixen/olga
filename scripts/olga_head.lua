--#region Variables
local Mod = OlgaMod

local DogHead = {}
OlgaMod.Dog.Head = DogHead

local game = Mod.Game
local sfxMan = Mod.SfxMan
local Util = OlgaMod.Util

DogHead.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DogHead.SOUND_BARK = Isaac.GetSoundIdByName("Olga Bark")

DogHead.ANIM_CHANCE = 1 / 30
DogHead.MINI_ANIM_CHANCE = 1 / 4
DogHead.REPEAT_CHANCE = 1 / 6

local ONE_TILE = 40
DogHead.HAPPY_DISTANCE = ONE_TILE * 2
DogHead.PETTING_DISTANCE = ONE_TILE * 1.2

DogHead.IdleAnim = {
    {Name = "Yawn",     BodyState = nil},
    {Name = "Bark",     BodyState = nil},
    {Name = "Playful",  BodyState = Util.DogState.STANDING},
}

DogHead.MiniIdleVariants = {
    {Name = "EarFlick",     Variants = {"Left", "Right", "Both"}},
    {Name = "EarRotate",    Variants = {"Left", "Right", "Both"}}
}

DogHead.MiniIdle = {}
for i, value in ipairs(DogHead.MiniIdleVariants) do
    DogHead.MiniIdle[value.Name] = i
end

--#endregion
--#region Olga Head State Functions
-- Space Complexity final boss
DogHead.ANIM_FUNC = {
    [Util.HeadAnim.IDLE] = function(olga, sprite, data)
        local frameCount = olga.FrameCount
        local rng = olga:GetDropRNG()

        DogHead:TryTurningGlad(olga, sprite, data)

        if not sprite:IsEventTriggered("TransitionHook")
        or not DogHead:CanIdleAnimation(olga)
        or data.animCD > frameCount then
            return
        end

        if rng:RandomFloat() < DogHead.ANIM_CHANCE then

            if rng:RandomFloat() < DogHead.MINI_ANIM_CHANCE then
                DogHead:DoMiniIdleAnim(data.headSprite)
            else
                DogHead:DoIdleAnimation(olga, data)
            end
            data.animCD = olga.FrameCount + Util.ANIM_COOLDOWN
        end
    end,

    [Util.HeadAnim.GLAD] = function(olga, sprite, data)
        if sprite:IsEventTriggered("TransitionHook") then
            local player = olga.Player

            if not player then return end --dpower12 inspired me to place this here

            if Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE) then
                Mod.PettingHand:UpdateHandColor(player, data.headSprite)
                sprite:Play(Util.HeadAnim.GLAD_TO_GLAD_PETTING, true)

            elseif not Util:IsWithin(olga, player.Position, DogHead.HAPPY_DISTANCE) then
                sprite:Play(Util.HeadAnim.GLAD_TO_IDLE, true)
            end
        end
    end,

    [Util.HeadAnim.GLAD_PETTING] = function(olga, sprite, data, animName)
        local player = olga.Player

        data.attentionCD = olga.FrameCount + Util.ATTENTION_COOLDOWN

        if not data.isPetting then
            player:AddCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE), false)
            data.isPetting = true
        end

        if not sprite:IsEventTriggered("TransitionHook")
        or Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE) then
            return
        end

        local pettingVariant, _ = string.find(animName, Util.HeadAnim.GLAD)
        local animTransition = pettingVariant and Util.HeadAnim.GLAD_PETTING_TO_GLAD or Util.HeadAnim.PETTING_TO_IDLE
        sprite:Play(animTransition, true)

        if data.isPetting and not player:HasCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE) then
            player:RemoveCostume(Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_NUMBER_ONE))
            data.isPetting = nil
        end
    end,

    -- Transitional animations
    [Util.HeadAnim.GLAD_TO_IDLE] = function(olga, sprite, _, animName)
        if sprite:IsFinished(animName) then
            local animToPlay = Util:FindAnimSubstring(animName)
            sprite:Play(Util.HeadAnim[animToPlay], true)
        end
    end,

    -- Standard idle animations
    [Util.HeadAnim.YAWN] = function(_, sprite, _, animName)
        if sprite:IsFinished(animName) then
            sprite:Play(Util.HeadAnim.IDLE, true)
        end

        if sprite:IsEventTriggered("Yawn") then
            sfxMan:Play(DogHead.SOUND_YAWN, 1, 2, false, math.random(9, 12)/10)
        end

        if sprite:IsEventTriggered("Bark") then
            sfxMan:Play(DogHead.SOUND_BARK, 2, 2, false, 1)
        end
    end,

    -- Mini idle animations
    [Util.HeadAnim.EAR_FLICK_L] = function (olga, sprite, data, animName) ---@param olga EntityFamiliar
        if sprite:IsFinished(animName) then
            local rng = olga:GetDropRNG()
            if rng:RandomFloat() < DogHead.REPEAT_CHANCE then
                local animToPlay = Util:FindAnimSubstring(animName, true)
                DogHead:DoMiniIdleAnim(sprite, DogHead.MiniIdle[animToPlay])
            else
                sprite:Play(Util.HeadAnim.IDLE, true)
            end
        end

        DogHead:TryTurningGlad(olga, sprite, data)
    end,

    [Util.HeadAnim.HOLD] = function(olga) ---@param olga EntityFamiliar
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

    if not data.headSprite or data.headRender == false or not olga.Visible then return end -- For Sac altar

    local renderMode = Mod.Room():GetRenderMode()

    -- Water reflections
    if renderMode ~= RenderMode.RENDER_WATER_ABOVE and renderMode ~= RenderMode.RENDER_NORMAL then
        local headReflectionOffset = olga.FlipX and Vector(11, 0) or Vector(-11, 0)
        data.headSprite:Render(Isaac.WorldToRenderPosition(olga.Position + olga.PositionOffset - olga:GetNullOffset("head") + headReflectionOffset) + offset)
        return
    end

    data.headSprite:Render(Isaac.WorldToRenderPosition(olga.Position + olga.PositionOffset + olga:GetNullOffset("head")) + offset)

    if not (Isaac.GetFrameCount() % 2 == 0) or game:IsPaused() then return end

    data.headSprite.FlipX = olga.FlipX
    data.headSprite.Scale = olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and Vector(1.25, 1.25) or Vector.One
    data.headSprite:Update()

    local animName = data.headSprite:GetAnimation()
    DogHead.ANIM_FUNC[animName](olga, data.headSprite, data, animName)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DogHead.OnHeadRender, Mod.Dog.VARIANT)
--#endregion
--#region Olga Helper Functions

---@param olga EntityFamiliar
function DogHead:CanIdleAnimation(olga)
    return olga.State ~= Util.DogState.FETCH and olga.State ~= Util.DogState.RETURN
end

---@param sprite Sprite
---@param anim integer?
function DogHead:DoMiniIdleAnim(sprite, anim)
    local animGamble = not anim and DogHead.MiniIdleVariants[math.random(#DogHead.MiniIdleVariants)] or DogHead.MiniIdleVariants[anim]
    sprite:Play(animGamble.Name .. "_" .. animGamble.Variants[math.random(#animGamble.Variants)], true)
end

---@param olga EntityFamiliar
---@param sprite Sprite
---@param data table
function DogHead:TryTurningGlad(olga, sprite, data)
    local room = Mod.Room()
    if not sprite:IsEventTriggered("TransitionHook") or not room:IsClear()
    or not data.canPet or data.isHolding then
        data.canPet = true
        return
    end

    -- If shes not due for an alternate petting animation
    if data.attentionCD > olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
        data.attentionCD = olga.FrameCount + Util.ATTENTION_COOLDOWN
        Mod.PettingHand:UpdateHandColor(olga.Player, sprite)
        sprite:Play(Util.HeadAnim.IDLE_TO_PETTING, true)
    elseif data.attentionCD < olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
        sprite:Play(Util.HeadAnim.IDLE_TO_GLAD, true)
    end
end

---@param olga EntityFamiliar
---@param data table
function DogHead:DoIdleAnimation(olga, data)
    local chosenAnim = DogHead.IdleAnim[math.random(#DogHead.IdleAnim)]

    -- If the animation does not require a certain stance, play it
    if not chosenAnim.BodyState then
        data.headSprite:Play(chosenAnim.Name, true)
        return
    end

    local sprite = olga:GetSprite()
    olga.Velocity = Vector.Zero
    data.targetPos = nil

    -- Play the animation if olga is already on that stance.
    if chosenAnim.BodyState == olga.State then
        sprite:Play(chosenAnim.Name, true)
        data.headRender = false
        return
    end

    -- Make her do the switcheroo otherwise
    if chosenAnim.BodyState == Util.DogState.STANDING then
        sprite:Play(Util.BodyAnim.SIT_TO_STAND, true)
        data.headRender = chosenAnim.BodyState
    elseif chosenAnim.BodyState == Util.DogState.SITTING then
        sprite:Play(Util.BodyAnim.STAND_TO_SIT, true)
        data.headRender = chosenAnim.BodyState
    end

    data.animToPlay = chosenAnim.Name
end
--#endregion
