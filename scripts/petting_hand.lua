--#region Variables
local Mod = OlgaDog
local PETTING_HAND = {}

--PETTING_HAND.VARIANT = Isaac.GetEntityVariantByName("Petting Hand")

PETTING_HAND.COLOR = {
    PINK = -1,
    WHITE = 0,
    BLACK = 1,
    BLUE = 2,
    RED = 3,
    GREEN = 4,
    GREY = 5,
    SHADOW = 6
}

PETTING_HAND.COMPATIBILITY = {
    "MAGDALENE",
    "EDEN",
    "BLUEBABY",
    "SAMSON",
    "KEEPER"
}
--#endregion
--#region Petting Hand Functions

function PETTING_HAND:OnChangeFamilyMember()
    OlgaDog:UpdateHandColor()
end
Mod:AddCallback(ModCallbacks.MC_USE_ITEM, PETTING_HAND.OnChangeFamilyMember, CollectibleType.COLLECTIBLE_CLICKER)

--#endregion
--#region Petting Hand Update Function

-- Update the petting hand color based on the player's skin
function OlgaDog:UpdateHandColor()
    for _, doggy in pairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, OLGA_FAMILIAR)) do
        if not doggy then return end
        local olga = doggy:ToFamiliar()
        local player = olga.Player
        local sprite = olga:GetSprite()
        local skinColor = player:GetBodyColor()
        local playerType = player:GetPlayerType()
        local EPlayer = Epiphany.PlayerType

        for string, value in pairs(PETTING_HAND.COLOR) do
            string:lower()
            if skinColor == value then
                sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_" .. string .. ".png")
                break
            end
        end

        if Epiphany then
            if playerType == EPlayer.JUDAS
            or playerType == EPlayer.JUDAS4
            or playerType == EPlayer.JUDAS5 then
                sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_shadow.png")
                goto finish
            elseif playerType == EPlayer.JUDAS2 
                or playerType == EPlayer.JUDAS1 then
                sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_judas_angel.png")
                goto finish
            end

            for _, moddedString in pairs(PETTING_HAND.COMPATIBILITY) do
                local fileName = moddedString:lower()
                if playerType == EPlayer[moddedString] then
                    sprite:ReplaceSpritesheet(2, "gfx/petting_hands/petting_hand_tr_" .. fileName .. ".png")
                    break
                end
            end
        end
        
        ::finish::
        sprite:LoadGraphics()
    end
end
--#endregion