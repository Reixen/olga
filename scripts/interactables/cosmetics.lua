--#region Variables
local Mod = OlgaMod

local Cosmetics = {}
OlgaMod.Cosmetics = Cosmetics

local saveMan = Mod.SaveManager
local Util = Mod.Util
--#endregion
--#region Callbacks
---@param slot EntitySlot
function Cosmetics:OnUseDressingTable(slot)
    local touch = slot:GetTouch()
    local gameData = Isaac.GetPersistentGameData()
    if not gameData:Unlocked(Util.Achievements.FUR_COLORS.ID)
    or slot:GetState() ~= 1
    or (touch ~= 0 and touch % 15 ~= 0) then
        return
    end

    local persistentSave = saveMan.GetPersistentSave()
    persistentSave.furColor = persistentSave.furColor or 0 -- If it doesn't exist, set to default
    persistentSave.furColor = persistentSave.furColor >= 3 and 0 or persistentSave.furColor + 1

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        local sprite = olga:GetSprite()

        Util:ApplyColorPalette(sprite, "olga_shader", persistentSave.furColor)
        Util:ApplyColorPalette(olga:GetData().headSprite, "olga_shader", persistentSave.furColor, Util.HeadLayerId)
        Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, olga.Position, Vector.Zero, olga)
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, Util.OnUseDressingTable, SlotVariant.MOMS_DRESSING_TABLE)
--#region Helper Functions
--#endregion