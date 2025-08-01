--#region Variables
local Mod = OlgaMod

local DogHead = {}
OlgaMod.Dog.Head = DogHead

local game = Mod.Game
local sfxMan = Mod.SfxMan
local Util = Mod.Util
local saveMan = Mod.SaveManager

DogHead.SOUND_YAWN = Isaac.GetSoundIdByName("Olga Yawn")
DogHead.SOUND_BARK = Isaac.GetSoundIdByName("Olga Bark")
DogHead.SOUND_PANT = Isaac.GetSoundIdByName("Olga Pant")
DogHead.SOUND_CRUNCH = Isaac.GetSoundIdByName("Olga Crunch")
DogHead.SOUND_MINI_CRUNCH = Isaac.GetSoundIdByName("Olga Mini Crunch")
DogHead.SOUND_SNIFF = Isaac.GetSoundIdByName("Olga Sniff")
DogHead.SOUND_GULP = Isaac.GetSoundIdByName("Olga Gulp")

DogHead.ANIM_CHANCE = 1 / 40
DogHead.MINI_ANIM_CHANCE = 3 / 5
DogHead.REPEAT_CHANCE = 1 / 7
DogHead.PANT_CHANCE = 1 / 20

local ONE_SEC = 30
DogHead.MINI_IDLE_COOLDOWN = ONE_SEC * 2
DogHead.ANIM_COOLDOWN = ONE_SEC * 6
DogHead.ATTENTION_COOLDOWN = ONE_SEC * 30

local ONE_TILE = 40
DogHead.HAPPY_DISTANCE = Mod.Dog.Body.HAPPY_DISTANCE
DogHead.PETTING_DISTANCE = ONE_TILE * 1.2

DogHead.IdleAnim = {
    {Name = Util.HeadAnim.YAWN,                 BodyState = nil},
    {Name = Util.HeadAnim.BARK,                 BodyState = nil},
    {Name = Util.HeadAnim.SNIFF,                BodyState = nil},
    {Name = Util.BodyAnim.PLAYFUL_1,            BodyState = Util.DogState.STANDING},
    {Name = Util.BodyAnim.PLAYFUL_2,            BodyState = Util.DogState.STANDING},
    {Name = Util.BodyAnim.SIT_TO_SCRATCHING,    BodyState = Util.DogState.SITTING},
}

DogHead.MiniIdleVariants = {
    {Name = "EarFlick",     Variants = {"Left", "Right", "Both"}},
    {Name = "EarRotate",    Variants = {"Left", "Right", "Both"}},
    {Name = "Tilt",         Variants = {"Left", "Right"}},
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

        DogHead:TryFindingFood(olga, data) -- Line 335
        DogHead:TryTurningGlad(olga, sprite, data)

        if not sprite:IsEventTriggered("TransitionHook") or Util:IsBusy(olga)
        or data.animCD > frameCount or not data.hasOwner then
            return
        end

        local rng = olga:GetDropRNG()
        if rng:RandomFloat() < DogHead.ANIM_CHANCE then

            if math.random() < DogHead.MINI_ANIM_CHANCE then
                data.animCD = olga.FrameCount + DogHead.MINI_IDLE_COOLDOWN
                DogHead:DoMiniIdleAnim(data.headSprite)
            else
                data.animCD = olga.FrameCount + DogHead.ANIM_COOLDOWN
                DogHead:DoIdleAnimation(olga, data)
            end
        end
    end,

    [Util.HeadAnim.GLAD] = function(olga, sprite, data)
        DogHead:TryFindingFood(olga, data) -- Line 335

        if sprite:IsEventTriggered("TransitionHook") then
            local player = olga.Player

            if Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE)
            and not Util:IsBusy(olga) then
                Util:UpdateHandColor(player, data.headSprite, GetPtrHash(olga))
                sprite:Play(Util.HeadAnim.GLAD_TO_GLAD_PETTING, true)

            elseif not Util:IsWithin(olga, player.Position, DogHead.HAPPY_DISTANCE) then
                sprite:Play(Util.HeadAnim.GLAD_TO_IDLE, true)
            end
        end
    end,

    [Util.HeadAnim.GLAD_PETTING] = function(olga, sprite, data, animName)
        local player = olga.Player ---@cast player EntityPlayer

        DogHead:TryFindingFood(olga, data) -- Line 335

        if not player:HasCollectible(Util.HAPPY_COLLECTIBLE)
        and not player:IsCollectibleCostumeVisible(Util.HAPPY_COLLECTIBLE, "head")
        and not (Poglite and Poglite.WePoggin) then -- Prevent it from spamming when pogging
            local itemCfg = Isaac.GetItemConfig():GetCollectible(Util.HAPPY_COLLECTIBLE)
            player:AddCostume(itemCfg, false)
        end

        if not sprite:IsEventTriggered("TransitionHook")
        or Util:IsWithin(olga, player.Position, DogHead.PETTING_DISTANCE)
        and not Util:IsBusy(olga) then
            return
        end

        Util:EndPettingAnimation(sprite, olga.Player, animName)
        data.specialPettingCD = olga.FrameCount + DogHead.ATTENTION_COOLDOWN
    end,

    -- Transitional animations
    [Util.HeadAnim.GLAD_TO_IDLE] = function(olga, sprite, data, animName)
        if sprite:IsFinished() then
            local animToPlay = Util:FindAnimSubstring(animName)
            sprite:Play(Util.HeadAnim[animToPlay], true)
        end

        -- Returning the fetching object
        if sprite:IsEventTriggered("Pickup") then
            local room = Mod.Room()
            local spawnPos = room:FindFreePickupSpawnPosition(olga.Position, 0, true)
            Isaac.Spawn(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, data.objectID, spawnPos, Vector.Zero, olga)

            data.objectID = nil
        end
    end,

    -- Standard idle animations
    [Util.HeadAnim.YAWN] = function(_, sprite, _, animName)
        if sprite:IsFinished() and animName ~= Util.HeadAnim.HOLD then
            sprite:Play(Util.HeadAnim.IDLE, true)
        end

        if sprite:IsEventTriggered("Yawn") then
            sfxMan:Play(DogHead.SOUND_YAWN, 1, 2, false, math.random(9, 12)/10)

        elseif sprite:IsEventTriggered("Bark") then
            sfxMan:Play(DogHead.SOUND_BARK, 2, 2, false, 1)

        elseif sprite:IsEventTriggered("Sniff") then
            sfxMan:Play(DogHead.SOUND_SNIFF, 1.5, 2, false, math.random(10, 12)/10)

        elseif sprite:IsEventTriggered("Crunch") then
            sfxMan:Play(DogHead.SOUND_CRUNCH, 2.6, 2, false, math.random(9, 11)/10)

        elseif sprite:IsEventTriggered("MiniCrunch") then
            sfxMan:Play(DogHead.SOUND_MINI_CRUNCH, 2.6, 2, false, math.random(9, 11)/10)

        elseif sprite:IsEventTriggered("Gulp") then
            sfxMan:Play(DogHead.SOUND_GULP, 1.7, 2, false, math.random(10, 12)/10)

        elseif sprite:IsEventTriggered("Munch") then
            sfxMan:Play(SoundEffect.SOUND_MEAT_JUMPS, 0.8, 2, false, math.random(9, 11)/10)
        end
    end,

    -- Mini idle animations
    ---@param olga EntityFamiliar
    ---@param sprite Sprite
    ---@param data DogData
    ---@param animName string
    [Util.HeadAnim.EAR_FLICK_L] = function (olga, sprite, data, animName)
        if not sprite:IsFinished() then
            return
        end

        local rng = olga:GetDropRNG()

        -- If the animation playing is a head tilt animation
        if animName:match("Tilt") then
            DogHead:TryProlongTilt(olga, data, rng, sprite, animName)
            return
        end

        if rng:RandomFloat() < DogHead.REPEAT_CHANCE
        and not Util:IsBusy(olga) then
            local animToPlay = Util:FindAnimSubstring(animName, true)
            DogHead:DoMiniIdleAnim(sprite, DogHead.MiniIdle[animToPlay])
        else
            sprite:Play(Util.HeadAnim.IDLE, true)
        end

        DogHead:TryTurningGlad(olga, sprite, data)
    end,
}
DogHead.ANIM_FUNC[Util.HeadAnim.PETTING] = DogHead.ANIM_FUNC[Util.HeadAnim.GLAD_PETTING]

Util:FillEmptyAnimFunctions(
    Util.HeadAnim,
    DogHead.ANIM_FUNC,
    DogHead.ANIM_FUNC[Util.HeadAnim.GLAD_TO_IDLE],
    DogHead.ANIM_FUNC[Util.HeadAnim.YAWN],
    DogHead.ANIM_FUNC[Util.HeadAnim.EAR_FLICK_L]
)

--#endregion
--#region Olga Callback
---@param olga EntityFamiliar
---@param offset Vector
function DogHead:OnHeadRender(olga, offset)
    local data = olga:GetData() ---@cast data DogData

    -- Sac Altar / GH          Special Idle Animations       When spawning
    if not data.headSprite or data.headRender == false or not olga.Visible then
        return
    end

    local renderMode = Mod.Room():GetRenderMode()

    -- Water reflections
    if renderMode ~= RenderMode.RENDER_WATER_ABOVE and renderMode ~= RenderMode.RENDER_NORMAL then
        local headReflectionOffset = olga.FlipX and Vector(11, 0) or Vector(-11, 0)
        data.headSprite:Render(Isaac.WorldToRenderPosition(olga.Position + olga.PositionOffset - olga:GetNullOffset("head") + headReflectionOffset) + offset)
        return
    end
    data.headSprite:Render(Isaac.WorldToRenderPosition(olga.Position + olga.PositionOffset + olga:GetNullOffset("head")) + offset)

    if not (Isaac.GetFrameCount() % 2 == 0) or game:IsPaused() then
        return
    end

    data.headSprite.FlipX = olga.FlipX
    data.headSprite.Scale = olga.Player:HasCollectible(CollectibleType.COLLECTIBLE_BFFS) and Vector(1.25, 1.25) or Vector.One
    data.headSprite:Update()

    if data.headSprite:IsEventTriggered("Pant")
    and math.random() < DogHead.PANT_CHANCE then
        sfxMan:Play(DogHead.SOUND_PANT, 3, 2, false, math.random(9, 11)/10)
    end

    local animName = data.headSprite:GetAnimation()
    DogHead.ANIM_FUNC[animName](olga, data.headSprite, data, animName)
end
Mod:AddCallback(ModCallbacks.MC_POST_FAMILIAR_RENDER, DogHead.OnHeadRender, Mod.Dog.VARIANT)
--#endregion
--#region Olga Helper Functions
---@param sprite Sprite
---@param anim integer?
function DogHead:DoMiniIdleAnim(sprite, anim)
    local animGamble = not anim and DogHead.MiniIdleVariants[math.random(#DogHead.MiniIdleVariants)] or DogHead.MiniIdleVariants[anim]
    if animGamble.Variants then
        sprite:Play(animGamble.Name .. "_" .. animGamble.Variants[math.random(#animGamble.Variants)], true)
    else
        sprite:Play(animGamble.Name)
    end
end

---@param olga EntityFamiliar
---@param sprite Sprite
---@param data table
function DogHead:TryTurningGlad(olga, sprite, data)
    local room = Mod.Room()
    if not sprite:IsEventTriggered("TransitionHook") or not room:IsClear()
    or Util:IsBusy(olga) or not data.canPet then
        if not Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
            data.canPet = true
        end
        return
    end

    -- If shes not due for an alternate petting animation
    if data.specialPettingCD > olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.PETTING_DISTANCE) then
        Util:UpdateHandColor(olga.Player, sprite, GetPtrHash(olga))
        sprite:Play(Util.HeadAnim.IDLE_TO_PETTING, true)
    elseif data.specialPettingCD < olga.FrameCount
    and Util:IsWithin(olga, olga.Player.Position, DogHead.HAPPY_DISTANCE) then
        sprite:Play(Util.HeadAnim.IDLE_TO_GLAD, true)
    end
end

---@param olga EntityFamiliar
---@param data table
---@param anim table?
function DogHead:DoIdleAnimation(olga, data, anim)
    local chosenAnim = anim or DogHead.IdleAnim[math.random(#DogHead.IdleAnim)]

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

---@param olga EntityFamiliar
---@param data DogData
---@param rng RNG
---@param sprite Sprite
---@param animName string
function DogHead:TryProlongTilt(olga, data, rng, sprite, animName)
    if data.animCD > olga.FrameCount then
        return
    end

    local directionStringStart = animName:find("_")
    local tiltDirection = animName:sub(directionStringStart + 1)

    if sprite:IsFinished(Util.HeadAnim.TILT_SWITCH_LEFT) then
        sprite:SetFrame(Util.HeadAnim.TILT_RIGHT, 7)
        tiltDirection = "Right"
    elseif sprite:IsFinished(Util.HeadAnim.TILT_SWITCH_RIGHT) then
        sprite:SetFrame(Util.HeadAnim.TILT_LEFT, 7)
        tiltDirection = "Left"
    end

    -- Repeat or nah
    if rng:RandomFloat() < DogHead.REPEAT_CHANCE then
        -- Decide if it should prolong the tilt or switch
        if rng:RandomFloat() < 0.5 then
            sprite:Play("TiltSwitch_" .. tiltDirection, true)
            data.animCD = olga.FrameCount + DogHead.MINI_IDLE_COOLDOWN
        else
            data.animCD = olga.FrameCount + (DogHead.MINI_IDLE_COOLDOWN / 2)
        end
    else
        sprite:Play("Tilt" .. tiltDirection .. "ToIdle", true)
    end
end

---@param olga EntityFamiliar
---@param data DogData
function DogHead:TryFindingFood(olga, data)
    if data.feedingBowl
    or Util:IsEating(olga)
    or not saveMan.TryGetRoomSave() then
        return
    end
    local roomSave = saveMan.GetRoomSave()
    if roomSave.filledBowls and #roomSave.filledBowls > 0 then
        local nearestBowl = Mod.Dog.Body:FindNearestPosition(roomSave.filledBowls, olga.Position)
        Mod.Dog.Body:TryEndingBusyState(olga, data)

        olga.State = Util.DogState.APPROACH_BOWL
        data.targetPos = nearestBowl
    end
end
--#endregion