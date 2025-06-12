local Mod = OlgaMod

function Mod:LoadPatches()
    if not Epiphany then return end


    Epiphany:AddToDictionary(
        Epiphany.Character.KEEPER.DisallowedPickUpVariants[PickupVariant.PICKUP_TAROTCARD],
        {
            [Mod.Pickup.FEEDING_BOWL_ID] = 1,
            [Mod.Pickup.ROD_OF_THE_GODS_ID] = 1,
            [Mod.Pickup.STICK_ID] = 1,
            [Mod.Pickup.TENNIS_BALL_ID] = 1
        }
    )

    Epiphany:AddToDictionary(
        Epiphany.Character.KEEPER.DisallowedPickUpVariants[PickupVariant.PICKUP_TRINKET],
        {[Mod.Pickup.CRUDE_DRAWING_ID] = 1}
    )
end
Mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, Mod.LoadPatches)