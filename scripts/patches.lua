local Mod = OlgaMod

if EID then
    local sprite = Sprite()
    sprite:Load("gfx/ui/eid_icons.anm2", true)

    EID:addIcon("Card" .. Mod.Pickup.STICK_ID, "Stick", 0, 9, 9, 6, 6, sprite)
    EID:addIcon("Card" .. Mod.Pickup.TENNIS_BALL_ID, "Tennis Ball", 0, 9, 9, 6, 6, sprite)
    EID:addIcon("Card" .. Mod.Pickup.ROD_OF_THE_GODS_ID, "Rod of the Gods", 0, 9, 9, 6, 6, sprite)
    EID:addIcon("Card" .. Mod.Pickup.FEEDING_KIT_ID, "Feeding Kit", 0, 9, 9, 6, 6, sprite)

    EID:addIcon("Olga", "Olga", 0, 9, 9, 5, 6, sprite)
    EID:addIcon("Feeding Bowl", "Feeding Bowl", 0, 9, 9, 5, 6, sprite)
    EID:addIcon("Generic Food", "Generic Food", 0, 9, 9, 5, 6, sprite)

    EID:addTrinket(Mod.Pickup.CRUDE_DRAWING_ID,
        "Prevents {{Olga}} Olga from disappearing next floor"
    )
    EID:addCard(Mod.Pickup.FEEDING_KIT_ID,
        "{{Feeding Bowl}} Spawns a" ..
        "#{{Blank}} Feeding Bowl and grants Isaac a Generic Food" ..
        "#{{Generic Food}} Feed {{Olga}} Olga to get Pup points!" ..
        "#Can be fed with {{Collectible" .. CollectibleType.COLLECTIBLE_DESSERT .. "}}, " ..
        "{{Collectible" .. CollectibleType.COLLECTIBLE_DINNER .. "}}, or {{Collectible" .. CollectibleType.COLLECTIBLE_SNACK.. "}} "..
        "and will not be removed from inventory"
    )
    EID:addCard(Mod.Pickup.STICK_ID,
        "Spawns a movable target that lasts longer when moved" ..
        "#{{Card" .. Mod.Pickup.STICK_ID .. "}} Throws the Stick towards the target"
    )
    EID:addCard(Mod.Pickup.TENNIS_BALL_ID,
        "Spawns a movable target that lasts longer when moved" ..
        "#{{Card" .. Mod.Pickup.TENNIS_BALL_ID .. "}} Throws the Tennis Ball towards the target"
    )
    EID:addCard(Mod.Pickup.ROD_OF_THE_GODS_ID,
        "Spawns a movable target that lasts longer when moved" ..
        "#{{Card" .. Mod.Pickup.ROD_OF_THE_GODS_ID .. "}} Throws the pole towards the target"
    )

    EID:setModIndicatorName("Olga")
    EID:setModIndicatorIcon("Olga")
end

function Mod:LoadPatches()
    if Epiphany then
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
end
Mod:AddCallback(ModCallbacks.MC_POST_MODS_LOADED, Mod.LoadPatches)

if not Epiphany then
    return
end

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