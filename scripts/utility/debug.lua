--#region Variables
local Mod = OlgaMod

local Debug = {}
OlgaMod.Debug = Debug

local Util = OlgaMod.Util
local saveMan = Mod.SaveManager

Debug.COMMAND_IDENTIFIER = "olgadebug"
Debug.Commands = {
    ["switch"] = {Desc = "Changes the stance of the dog",
    Function = function()
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
    end
    },
    ["animate"] = {Desc = "Plays a random animation",
    Function = function()
        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
            local data = olga:GetData()
            --Mod.Dog.Head:DoMiniIdleAnim(data.headSprite, Mod.Dog.Head.MiniIdle["Tilt"])
            Mod.Dog.Head:DoIdleAnimation(familiar:ToFamiliar(), familiar:GetData(), Mod.Dog.Head.IdleAnim[3])
            data.animCD = olga.FrameCount + 180
        end
    end
    },
    ["addnull"] = {Desc = "Grants an extra use for each valid food item you have",
    Function = function()
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

                if collAmt ~= 0 then
                    tempFX:AddNullEffect(nullFX, false, collAmt)
                end
            end
        end
    end
    },
    ["clearpoints"] = {Desc = "Turns your Pup points to 0",
    Function = function()
        local persistentSave = saveMan.GetPersistentSave()
        local runSave = saveMan.GetRunSave()
        local points = (runSave and runSave.pupPoints) or (persistentSave and persistentSave.pupPoints) or 0

        print("You had " .. points .. " Pup points.")
        persistentSave.pupPoints = 0
        saveMan.GetRunSave().pupPoints = 0
    end
    },
}

for param, table in pairs(Debug.Commands) do
    Console.RegisterCommand(Debug.COMMAND_IDENTIFIER .. " " .. param, table.Desc, table.Desc, true, AutocompleteType.NONE)
end

--#region Debug Callbacks
function Debug:Command(command, parameter)
    if command ~= Debug.COMMAND_IDENTIFIER or not Debug.Commands[parameter] then
        return
    end
    Debug.Commands[parameter].Function()
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Debug.Command)
--#endregion