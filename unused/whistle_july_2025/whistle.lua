--#region Variables
local Mod = OlgaMod

local Whistle = {}
OlgaMod.Whistle = Whistle

local sfxMan = Mod.SfxMan
local Util = Mod.Util
local Head = Mod.Dog.Head
local Body = Mod.Dog.Body

Whistle.WHISTLE_ID = Mod.PickupHandler.Pickup[PickupVariant.PICKUP_TAROTCARD].WHISTLE_ID
Whistle.WHISTLE_SFX = Isaac.GetSoundIdByName("Toy Whistle")

--#endregion
--#region Feeding Bowl Callbacks
---@param entity Entity
-----@param inputHook InputHook
---@param action ButtonAction
function Whistle:OnWhistleUse(entity, _, action)
    if not entity or entity.Type ~= EntityType.ENTITY_PLAYER
    or action ~= ButtonAction.ACTION_PILLCARD then
        return
    end
    local player = entity:ToPlayer()
    if not Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
    or player:GetCard(0) ~= Whistle.WHISTLE_ID then
        Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, player.ControllerIndex)
        return
    end

    if sfxMan:IsPlaying(Whistle.WHISTLE_SFX) then
        return false
    end

    player:AnimateCard(Whistle.WHISTLE_ID)
    sfxMan:Play(Whistle.WHISTLE_SFX, 1.4, 2, false, math.random(16, 20) / 20)

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        local data = olga:GetData() ---@cast data DogData

        if Util:IsBusy(olga) or not data.headRender or data.isUrgent == true then
            goto skip
        end

        if Util:IsWithin(olga, olga.Player.Position,Head.HAPPY_DISTANCE) then
            if olga.State == Util.DogState.SITTING then
                olga:GetSprite():Play(Util.BodyAnim.SIT_TO_STAND, true)
                data.eventCD = Body.EVENT_COOLDOWN + olga.FrameCount
            elseif olga.State == Util.DogState.STANDING then
                olga:GetSprite():Play(Util.BodyAnim.STAND_TO_SIT, true)
                olga.Velocity = Vector.Zero
                data.targetPos = nil
                data.isUrgent = false
            end
            goto skip
        end

        if olga.State == Util.DogState.SITTING then
            olga:GetSprite():Play(Util.BodyAnim.SIT_TO_STAND, true)
        end
        data.isUrgent = true
        ::skip::
    end
    return false
end
Mod:AddCallback(ModCallbacks.MC_INPUT_ACTION, Whistle.OnWhistleUse, InputHook.IS_ACTION_TRIGGERED)
--#endregion