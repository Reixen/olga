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
Console.RegisterCommand("olgadebug clearnull", "Allows the food items to be reused", "", true, AutocompleteType.NONE)

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

    elseif args == "clearnull" then
        for _, player in ipairs(PlayerManager.GetPlayers()) do ---@cast player EntityPlayer
            local tempFX = player:GetEffects()
            tempFX:RemoveNullEffect(Mod.FeedingBowl.CONSUMED_DINNER_ID, 99)
            tempFX:RemoveNullEffect(Mod.FeedingBowl.CONSUMED_SNACK_ID, 99)
            tempFX:RemoveNullEffect(Mod.FeedingBowl.CONSUMED_DESSERT_ID, 99)
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Debug.Command)
--#endregion


