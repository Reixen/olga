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
OlgaMod.PickupHandler = {}

-- Interactables
OlgaMod.Fetch = {}
OlgaMod.FeedingBowl = {}
OlgaMod.Whistle = {}
OlgaMod.Cosmetics = {}

OlgaMod.Dog.VARIANT = Isaac.GetEntityVariantByName("Olga")

OlgaMod.EIDSprite = Sprite()
OlgaMod.EIDSprite:Load("gfx/ui/olga_eid_icons.anm2", true)
OlgaMod.MinimapSprite = Sprite()
OlgaMod.MinimapSprite:Load("gfx/ui/olga_minimap_ui.anm2", true)

OlgaMod.SaveManager = include("scripts.utility.save_manager")
OlgaMod.SaveManager.Init(OlgaMod)

-- Needed because I need to access Persistent Game Data for unlocks
OlgaMod.EncyCompat = {}

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
            "whistle",
            "cosmetics"
        }
    },
    {FolderName = "",
        Files = {
            "patches",
            "ency"
        }
    }
}

for _, folder in ipairs(fileStructure) do
    for _, fileName in ipairs(folder.Files) do
        include("scripts." .. folder.FolderName .. "."  .. fileName)
    end
end