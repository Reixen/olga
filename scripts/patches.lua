local Mod = OlgaMod

if not Epiphany then return end

function Mod:LoadPatches()
    Epiphany:AddToDictionary(
        Epiphany.Character.KEEPER.DisallowedPickUpVariants[PickupVariant.PICKUP_TAROTCARD],
        {
            [Mod.Pickup.FEEDING_KIT_ID] = 1,
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