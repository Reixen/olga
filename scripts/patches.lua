--#region Variables
local Mod = OlgaMod

local Consumables = Mod.PickupHandler.Pickup[PickupVariant.PICKUP_TAROTCARD]
local Trinkets = Mod.PickupHandler.Pickup[PickupVariant.PICKUP_TRINKET]
--#endregion
--#region Callbacks
function Mod:LoadPatches()
    Mod.Util.ModdedHands = {
        {PlayerTypeTable = Epiphany and Epiphany.PlayerType, PlayerTypes = {
                "MAGDALENE",
                "EDEN",
                "BLUEBABY",
                "SAMSON",
                "KEEPER",
                "JUDAS1",
                "JUDAS2",
                "JUDAS",
                "JUDAS4",
                "JUDAS5"
            }, FileString = "epiphany"
        },
        {PlayerTypeTable = FiendFolio and FiendFolio.PLAYER, PlayerTypes = {
                "FIEND",
            }, FileString = "fiend_folio"
        },
        {PlayerTypeTable = GIMP and GIMP.CHARACTER, PlayerTypes = {
                "GIMP",
                "GIMP_B",
                "GIMP_C"
            }, FileString = "gimp"
        },
    }

    if Encyclopedia then
        for _, compatFunc in ipairs(Mod.EncyCompat) do
            compatFunc()
        end
    end

    if BedroomExpanded then
        Mod:AddCallback(ModCallbacks.MC_POST_SLOT_COLLISION, Mod.Cosmetics.OnUseDressingTable, BedroomExpanded.Slot.CLOTHING_RACK.ID)
    end

    if not Epiphany then
        return
    end

    Epiphany:AddToDictionary(
        Epiphany.Character.KEEPER.DisallowedPickUpVariants[PickupVariant.PICKUP_TAROTCARD],
        {
            [Consumables.FEEDING_KIT_ID] = 1,
            [Consumables.ROD_OF_THE_GODS_ID] = 1,
            [Consumables.STICK_ID] = 1,
            [Consumables.TENNIS_BALL_ID] = 1,
            [Consumables.WHISTLE_ID] = 1
        }
    )

    Epiphany:AddToDictionary(
        Epiphany.Character.KEEPER.DisallowedPickUpVariants[PickupVariant.PICKUP_TRINKET],
        {[Trinkets.CRUDE_DRAWING_ID] = 1}
    )

    function Mod:OnEssenceOfTheKeeperUse()
        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            local sprite = familiar:GetSprite()
            if sprite:GetRenderFlags() ~= AnimRenderFlags.GOLDEN then
                sprite:SetRenderFlags(AnimRenderFlags.GOLDEN)
                familiar:GetData().headSprite:SetRenderFlags(AnimRenderFlags.GOLDEN)
            end
        end
    end
    Mod:AddCallback(ModCallbacks.MC_USE_CARD, Mod.OnEssenceOfTheKeeperUse, Epiphany.Essence.KEEPER.ID)
end
Mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, Mod.LoadPatches)
--#endregion