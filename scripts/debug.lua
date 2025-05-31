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
Console.RegisterCommand("olgadebug animate", "Plays a random head animation", "Plays a random head animation", true, AutocompleteType.NONE)
--Console.RegisterCommand("olgadebug fetch", "Makes all consumables throwable", "Cannot consume cards/runes", true, AutocompleteType.NONE)

function Debug:Command(command, args)
    if command == "olgadebug" then
        if args == "switch" then

            for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
                local olga = familiar:ToFamiliar()
                if not olga then return end
                
                local data = olga:GetData()
                data.randomPosition = nil

                if olga.State == Util.DogState.SITTING then
                    olga:GetSprite():Play(Util.BodyAnim.SIT_TO_STAND, true)
                elseif olga.State == Util.DogState.STANDING then
                    olga:GetSprite():Play(Util.BodyAnim.STAND_TO_SIT, true)
                end
                olga.Velocity = Vector.Zero
            end
        elseif args == "animate" then
            for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
                local olga = familiar:ToFamiliar()
                if not olga then return end
                olga:GetData().headSprite:Play(Util.HeadAnim.YAWN, true)
            end
        elseif args == "fetch" then
            --for _, player in ipairs(Isaac.FindByType(EntityType.ENTITY_PLAYER)) do
                --local data = player:ToPlayer():GetData()
                --if not data.canFetch then
                    --data.canFetch = true
                --else
                    --data.canFetch = false
                --end
            --end
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Debug.Command)
--#endregion
