local Mod = OlgaDog

local DOG_BODY = Mod.OlgaBody
local DOG_HEAD = Mod.OlgaHead

--Console.RegisterCommand("debugOlga", "", "", true, AutocompleteType.NONE)
Console.RegisterCommand("debugOlga switch", "Switches the stance of Olga Familiar", "Switches between standing and sitting", true, AutocompleteType.NONE)
Console.RegisterCommand("debugOlga animate", "Plays a random head animation", "Plays a random head animation", true, AutocompleteType.NONE)

function Mod:Command(command, args)
    if command == "debugOlga" then
        if args == "switch" then

            for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Familiar)) do
                local olga = familiar:ToFamiliar()
                if not olga then return end
                if olga.State == DOG_BODY.STATE.SITTING then
                    DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.SIT_TO_STAND)
                elseif olga.State == DOG_BODY.STATE.STANDING then
                    DOG_BODY:SetAnimation(olga, DOG_BODY.ANIM.STAND_TO_SIT)
                end
            end
        elseif args == "animate" then
            for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Familiar)) do
                local olga = familiar:ToFamiliar()
                if not olga then return end
                DOG_HEAD:SetAnimation(olga, DOG_HEAD.ANIM.YAWN)
            end
        end
    end
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Mod.Command)
