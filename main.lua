OlgaMod = RegisterMod("Olga", 1)

if not REPENTOGON then return end

    -- Variables
OlgaMod.Game = Game()
OlgaMod.SfxMan = SFXManager()
OlgaMod.Room = function() return OlgaMod.Game:GetRoom() end
OlgaMod.Level = function() return OlgaMod.Game:GetLevel() end

OlgaMod.Dog = {}
OlgaMod.Util = {}
OlgaMod.Debug = {}
-- Interactables
OlgaMod.PickupHandler = {}
OlgaMod.Fetch = {}
OlgaMod.FeedingBowl = {}
OlgaMod.Whistle = {}

OlgaMod.Dog.VARIANT = Isaac.GetEntityVariantByName("Olga")

OlgaMod.EIDSprite = Sprite()
OlgaMod.EIDSprite:Load("gfx/ui/eid_icons.anm2", true)

OlgaMod.SaveManager = include("scripts.utility.save_manager")
OlgaMod.SaveManager.Init(OlgaMod)

local fileStructure = {
    {FolderName = "utility",
        Files = {
            "util",
            "debug",
            "pickup_handler",
        }
    },
    {FolderName = "dog",
        Files = {
            "body",
            "head",
        }
    },
    {FolderName = "interactables",
        Files = {
            "fetch",
            "feeding_bowl",
            "whistle"
        }
    },
    {FolderName = "",
        Files = {
            "patches",
        }
    }
}

for _, folder in ipairs(fileStructure) do
    for _, fileName in ipairs(folder.Files) do
        if fileName == "save_manager" then
        else
            include("scripts." .. folder.FolderName .. "."  .. fileName)
        end
    end
end