--#region Variables
local Mod = OlgaMod

local Debug = {}
OlgaMod.Debug = Debug

local Util = OlgaMod.Util
local saveMan = Mod.SaveManager

Debug.COMMAND_IDENTIFIER = "olgadebug"
Debug.Commands = {
    ["animate"] = {Desc = "Plays a random animation",
    Function = function(id)
        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
            local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
            local data = olga:GetData()
            --Mod.Dog.Head:DoMiniIdleAnim(data.headSprite, Mod.Dog.Head.MiniIdle["Sniff"])
            Mod.Dog.Head:DoIdleAnimation(olga, data, Mod.Dog.Head.IdleAnim[id])
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
    ["clearpoints"] = {Desc = "Turns your Pup points to 0 and locks all achievements",
    Function = function()
        local persistentSave = saveMan.GetPersistentSave()
        local runSave = saveMan.GetRunSave()
        local points = (runSave and runSave.pupPoints) or (persistentSave and persistentSave.pupPoints) or 0

        print("You had " .. points .. " Pup points.")
        persistentSave.pupPoints = 0
        saveMan.GetRunSave().pupPoints = 0

        for _, ach in pairs(Util.Achievements) do
            Isaac.ExecuteCommand("lockachievement " ..ach.ID)
        end
    end
    },
    ["showpoints"] = {Desc = "Show Pup point amount",
    Function = function()
        local persistentSave = saveMan.GetPersistentSave()
        local runSave = saveMan.GetRunSave()
        local points = (runSave and runSave.pupPoints) or (persistentSave and persistentSave.pupPoints) or 0

        print("You have " .. points .. " Pup points.")
    end
    },
}

for param, table in pairs(Debug.Commands) do
    Console.RegisterCommand(Debug.COMMAND_IDENTIFIER .. " " .. param, table.Desc, table.Desc, true, AutocompleteType.NONE)
end

--#region Debug Callbacks
---@param command string
---@param parameter string
function Debug:Command(command, parameter)
    if command ~= Debug.COMMAND_IDENTIFIER then
        return
    end

    local strParameter = parameter
    local stringLength = strParameter:len()
    local number = ""
    if strParameter:match("%d+") and strParameter:match("%D+") then -- if it has numbers and chars
        local charFound = false

        while not charFound do
            local char = parameter:sub(stringLength, stringLength)

            if char:match("%D+") then
                charFound = true
            else
                number = char .. number
            end

            stringLength = stringLength - 1
        end
    end

    number = number ~= "" and tonumber(number) or 0
    strParameter = strParameter:sub(1, stringLength + 1) -- Get the string without the numbers

    if not Debug.Commands[strParameter] then
        return
    end
    Debug.Commands[strParameter].Function(number)
end
Mod:AddCallback(ModCallbacks.MC_EXECUTE_CMD, Debug.Command)
--#endregion