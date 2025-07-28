--#region Variables
local Mod = OlgaMod

local Cosmetics = {}
OlgaMod.Cosmetics = Cosmetics

local saveMan = Mod.SaveManager
local Util = Mod.Util
local game = Mod.Game

local ONE_TILE = 40
Cosmetics.SWAPPING_RADIUS = ONE_TILE * 2
Cosmetics.MAX_CHARGE = 60
Cosmetics.CHARGE_BAR_OFFSET = Vector(5, -20)
Cosmetics.SIGN_OFFSET = Vector(25, 8)

Cosmetics.Costumes = {}
Cosmetics.Costumes.HATS = {
    "none"
}
--#endregion
--#region Callbacks
---@param slot EntitySlot
function Cosmetics:OnUseDressingTable(slot)
    local touch = slot:GetTouch()
    local data = Util:GetData(slot, Util.DATA_IDENTIFIER)
    if not data.optionSprite
    or slot:GetState() ~= 1
    or (touch ~= 0 and touch % 15 ~= 0) then
        return
    end

    local persistentSave = saveMan.GetPersistentSave()
    if data.optionSprite:GetFrame() == 0 then
        persistentSave.furColor = persistentSave.furColor or 0 -- If it doesn't exist, set to default
        persistentSave.furColor = persistentSave.furColor >= 3 and 0 or persistentSave.furColor + 1

        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
            local sprite = olga:GetSprite()

            Util:ApplyColorPalette(sprite, "olga_shader", persistentSave.furColor)
            Util:ApplyColorPalette(olga:GetData().headSprite, "olga_shader", persistentSave.furColor, Util.HeadLayerId)
            Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, olga.Position, Vector.Zero, olga)
        end
        return
    end

    persistentSave.hatCostume = persistentSave.hatCostume or -1
    persistentSave.hatCostume = persistentSave.hatCostume >= #Cosmetics.Costumes.HATS and 0 or persistentSave + 1

end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, Cosmetics.OnUseDressingTable, SlotVariant.MOMS_DRESSING_TABLE)

---@param slot EntitySlot
function Cosmetics:OnDressingTableInit(slot)
    local gameData = Isaac.GetPersistentGameData()
    if not gameData:Unlocked(Util.Achievements.FUR_COLORS.ID) then
        return
    end

    local data = Util:GetData(slot, Util.DATA_IDENTIFIER)
    data.optionSprite = Sprite()
    data.optionSprite:Load("gfx/render_cosmetic_options.anm2", true)
    data.optionSprite:SetFrame("Sign", 0)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_INIT, Cosmetics.OnDressingTableInit, SlotVariant.MOMS_DRESSING_TABLE)

---@param slot EntitySlot
function Cosmetics:OnDressingTableRender(slot, offset)
    local data = Util:GetData(slot, Util.DATA_IDENTIFIER)
    if not data.optionSprite or slot:GetState() == 3 then
        return
    end

    local renderMode = Mod.Room():GetRenderMode()
    -- Water reflections
    if renderMode ~= RenderMode.RENDER_WATER_ABOVE and renderMode ~= RenderMode.RENDER_NORMAL then
        data.optionSprite:Render(Isaac.WorldToRenderPosition(slot.Position + slot.PositionOffset + Cosmetics.SIGN_OFFSET) + offset)
        return
    end
    data.optionSprite:Render(Isaac.WorldToRenderPosition(slot.Position + slot.PositionOffset + Cosmetics.SIGN_OFFSET) + offset)

    local charge = data.cosmeticCharge
    if not charge or charge == 0 then
        return
    end

    if not data.cosmeticChargeBar then
        data.cosmeticChargeBar = Sprite()
        data.cosmeticChargeBar:Load("gfx/chargebar.anm2", true)
    end

    local renderPos = Isaac.WorldToRenderPosition(slot.Position) + offset + Cosmetics.CHARGE_BAR_OFFSET + Cosmetics.SIGN_OFFSET
    Cosmetics:RenderChargeBar(data.cosmeticChargeBar, charge, Cosmetics.MAX_CHARGE, renderPos)
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_RENDER, Cosmetics.OnDressingTableRender, SlotVariant.MOMS_DRESSING_TABLE)

---@param player EntityPlayer
function Cosmetics:PostPlayerUpdate(player)
    for _, slot in ipairs(Isaac.FindByType(EntityType.ENTITY_SLOT, SlotVariant.MOMS_DRESSING_TABLE)) do
        local data = Util:GetData(slot, Util.DATA_IDENTIFIER)
        local charge = data.cosmeticCharge or 0

        if not Util:IsWithin(player, slot.Position, Cosmetics.SWAPPING_RADIUS)
        or not data.optionSprite or slot:ToSlot():GetState() == 3 then
            charge = 0
            goto skip
        end

        local persistentSave = Isaac.GetPersistentGameData()
        if not persistentSave:Unlocked(Util.Achievements.HAT_COSTUMES.ID)
        or not persistentSave:Unlocked(Util.Achievements.PARTY_HAT.ID) then
            return
        end

        if Input.IsActionPressed(ButtonAction.ACTION_DROP, player.ControllerIndex) then
            if charge >= Cosmetics.MAX_CHARGE then
                local endFrame = data.optionSprite:GetCurrentAnimationData():GetLength() - 1
                local currentFrame = data.optionSprite:GetFrame()
                local nextFrame = currentFrame < endFrame and currentFrame + 1 or 0
                data.optionSprite:SetFrame(nextFrame)

                Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 1, slot.Position + Cosmetics.SIGN_OFFSET, Vector.Zero, slot)

                charge = 0
            else
                charge = math.min(charge + 1, Cosmetics.MAX_CHARGE)
            end
        else
            charge = 0
        end

        ::skip::
        data.cosmeticCharge = charge
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, Cosmetics.PostPlayerUpdate)

--#endregion
--#region Helper Functions
-- Obtained from HudHelper, thanks Benny
function Cosmetics:ShouldHideHUD()
    if ModConfigMenu and ModConfigMenu.IsVisible
        or not game:GetHUD():IsVisible() and not (TheFuture or {}).HiddenHUD
        or game:GetSeeds():HasSeedEffect(SeedEffect.SEED_NO_HUD)
    then
        return true
    end

    -- Benny told me to not worry about this
    --local callbacks = HudHelper.Callbacks.RegisteredCallbacks[HudHelper.Callbacks.ID.CHECK_HUD_HIDDEN]
    --for i = 1, #callbacks do
        --if callbacks[i].Function() then
            --return true
        --end
    --end

    return false
end

-- Obtained from HudHelper, thanks Benny
---@param HUDSprite Sprite
---@param charge number
---@param maxCharge number
---@param position Vector
---@function
function Cosmetics:RenderChargeBar(HUDSprite, charge, maxCharge, position)
    if Cosmetics:ShouldHideHUD() or not Options.ChargeBars then
        return
    end

    if game:GetRoom():GetRenderMode() == RenderMode.RENDER_WATER_REFLECT then
        return
    end

    local chargePercent = math.min(charge / maxCharge, 1)

    if chargePercent == 1 then
        -- ChargedHUD:IsPlaying("StartCharged") and not
        if HUDSprite:IsFinished("Charged") or HUDSprite:IsFinished("StartCharged") then
            if not HUDSprite:IsPlaying("Charged") then
                HUDSprite:Play("Charged", true)
            end
        elseif not HUDSprite:IsPlaying("Charged") then
            if not HUDSprite:IsPlaying("StartCharged") then
                HUDSprite:Play("StartCharged", true)
            end
        end
    elseif chargePercent > 0 and chargePercent < 1 then
        if not HUDSprite:IsPlaying("Charging") then
            HUDSprite:Play("Charging")
        end
        local frame = (chargePercent * 100) // 1
        HUDSprite:SetFrame("Charging", frame)
    elseif chargePercent == 0 and not HUDSprite:IsPlaying("Disappear") and not HUDSprite:IsFinished("Disappear") then
        HUDSprite:Play("Disappear", true)
    end

    HUDSprite:Render(position)
    if Isaac.GetFrameCount() % 2 == 0 and not game:IsPaused() then
        HUDSprite:Update()
    end
end

--#endregion