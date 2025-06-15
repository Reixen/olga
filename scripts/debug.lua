--#region Variables
local Mod = OlgaMod

local Debug = {}
OlgaMod.Debug = Debug

local Util = OlgaMod.Util

--#endregion
--#region Functions

-- for loop soon
--Console.RegisterCommand("debugOlga", "", "", true, AutocompleteType.NONE)
Console.RegisterCommand("olgadebug switch", "Switches the stance of Olga Familiar", "Switches between standing and sitting", true, AutocompleteType.NONE)
Console.RegisterCommand("olgadebug animate", "Plays a random animation", "Plays a random animation", true, AutocompleteType.NONE)
Console.RegisterCommand("olgadebug addnull", "Allows the food items to be reused", "", true, AutocompleteType.NONE)

function Debug:Command(command, args)
    if command ~= "olgadebug" then return end

    if args == "switch" then

        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            local olga = familiar:ToFamiliar()

            local data = olga:GetData()
            data.targetPos = nil

            if olga.State == Util.DogState.SITTING then
                olga:GetSprite():Play(Util.BodyAnim.SIT_TO_STAND, true)
            elseif olga.State == Util.DogState.STANDING then
                olga:GetSprite():Play(Util.BodyAnim.STAND_TO_SIT, true)
            end
            olga.Velocity = Vector.Zero
        end

    elseif args == "animate" then
        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            Mod.Dog.Head:DoIdleAnimation(familiar:ToFamiliar(), familiar:GetData())
        end

    elseif args == "addnull" then
        for _, player in ipairs(PlayerManager.GetPlayers()) do ---@cast player EntityPlayer
            local tempFX = player:GetEffects()
            for collType, nullFX in pairs(Mod.FeedingBowl.CollectibleToNullFX) do
                local collAmt = 0
                if collType == CollectibleType.COLLECTIBLE_NULL then
                    for _, _ in ipairs(Isaac.FindByType(EntityType.ENTITY_SLOT, Mod.FeedingBowl.BOWL_VARIANT)) do
                        collAmt = collAmt + 1
                    end
                else
                    collAmt = player:GetCollectibleNum(collType, true, true)
                end

                if collAmt then
                    tempFX:AddNullEffect(nullFX, false, collAmt)
                end
            end
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Debug.Command)
--#endregion


