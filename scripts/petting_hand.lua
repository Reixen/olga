--#region Variables
local Mod = OlgaMod

local PettingHand = {}
OlgaMod.PettingHand = PettingHand

PettingHand.ModdedHands = {
    "MAGDALENE",
    "EDEN",
    "BLUEBABY",
    "SAMSON",
    "KEEPER"
}
--#endregion
--#region Petting Hand Functions

function PettingHand:OnChangeFamilyMember()
    PettingHand:UpdateHandColor()
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, PettingHand.OnChangeFamilyMember, CollectibleType.COLLECTIBLE_CLICKER)

-- Update the petting hand color based on the player's skin
function PettingHand:UpdateHandColor()
    for _, doggy in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        if not doggy then return end
        local olga = doggy:ToFamiliar() ---@cast olga EntityFamiliar
        local player = olga.Player
        local sprite = olga:GetData().headSprite
        local playerColor = player:GetBodyColor()
        local playerType = player:GetPlayerType()
        local EPlayer = Epiphany and Epiphany.PlayerType or nil

        for string, value in pairs(SkinColor) do
            string:lower()
            if playerColor == value then
                sprite:ReplaceSpritesheet(0, "gfx/petting_hands/petting_hand_" .. string .. ".png")
                break
            end
        end

        if Epiphany then
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
    end
end
--#endregion