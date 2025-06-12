--#region Variables
local Mod = OlgaMod

local PettingHand = {}
OlgaMod.PettingHand = PettingHand

PettingHand.SUBSTRING_START = 6

PettingHand.ModdedHands = {
    "MAGDALENE",
    "EDEN",
    "BLUEBABY",
    "SAMSON",
    "KEEPER"
}
--#endregion
--#region Petting Hand Functions
function PettingHand:OnReviveOrClicker()
    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        PettingHand:UpdateHandColor(olga.Player, olga:GetData().headSprite)
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, PettingHand.OnReviveOrClicker, CollectibleType.COLLECTIBLE_CLICKER)
Mod:AddCallback(ModCallbacks.MC_POST_PLAYER_REVIVE, PettingHand.OnReviveOrClicker)

-- Update the petting hand color based on the player's skin
---@param player EntityPlayer
---@param sprite Sprite
function PettingHand:UpdateHandColor(player, sprite)
    local playerColor = player:GetBodyColor()
    local playerType = player:GetPlayerType()
    local data = Mod.Util:GetData(player, Mod.Util.ID)

    if data.pColor and data.pColor == playerColor
    or (data.pType and data.pType == playerType) then
        return
    end

    for string, value in pairs(SkinColor) do
        local colorStr = string:sub(PettingHand.SUBSTRING_START, -1)

        if playerColor == value then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_" .. colorStr .. ".png")
            break
        end
    end

    if Epiphany then
        local EPlayer = Epiphany and Epiphany.PlayerType or nil
        if playerType == EPlayer.JUDAS
        or playerType == EPlayer.JUDAS4
        or playerType == EPlayer.JUDAS5 then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_shadow.png")
            goto finish
        elseif playerType == EPlayer.JUDAS2 
            or playerType == EPlayer.JUDAS1 then
            sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_judas_angel.png")
            goto finish
        end

        for _, moddedString in pairs(PettingHand.ModdedHands) do
            local fileName = moddedString:lower()
            if playerType == EPlayer[moddedString] then
                sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_tr_" .. fileName .. ".png")
                break
            end
        end
    end

    ::finish::
    sprite:LoadGraphics()
    data.pColor = playerColor
    data.pType = playerType
end
--#endregion