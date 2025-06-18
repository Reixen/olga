OlgaMod = RegisterMod("Olga", 1)

if not REPENTOGON then return end

    -- Variables
OlgaMod.Game = Game()
OlgaMod.SfxMan = SFXManager()
OlgaMod.Room = function() return OlgaMod.Game:GetRoom() end
OlgaMod.Level = function() return OlgaMod.Game:GetLevel() end

OlgaMod.Dog = {}
OlgaMod.Util = {}
OlgaMod.Fetch = {}
OlgaMod.FeedingBowl = {}
OlgaMod.Debug = {}

OlgaMod.Dog.VARIANT = Isaac.GetEntityVariantByName("Olga")

OlgaMod.Pickup = {
    CRUDE_DRAWING_ID = Isaac.GetTrinketIdByName("Crude Drawing"),
    STICK_ID = Isaac.GetCardIdByName("Stick"),
    FEEDING_KIT_ID = Isaac.GetCardIdByName("Feeding Kit"),
    TENNIS_BALL_ID = Isaac.GetCardIdByName("Tennis Ball"),
    ROD_OF_THE_GODS_ID = Isaac.GetCardIdByName("Rod of the Gods")
}

OlgaMod.SaveManager = include("scripts.utility.save_manager")
OlgaMod.SaveManager.Init(OlgaMod)

local fileStructure = {
    {FolderName = "utility",
        Files = {
            "util",
            "debug",
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


----------------------------------------------------------------
---                          TO DO:                          ---
----------------------------------------------------------------
--- 1) Head + Body
---     - Animations bro
---         - Lie Down
---             - When initialized, sleep
---             - Wake up and stretch if approached.
---             - Lie back to position if within range, otherwise stand.
---         - Sit
---             - Scratch
---         - Stand
---             - Feed on Bowl
---             - Running
---         - Head Specific Idle Animations
---             - Curious
--- 2) Fetch [DONE]
--- 3) Petting Hand [DONE]
--- 4) Feeding Bowl
---     - Animations
---         - Snack
---         - Dinner
---         - Generic
---         - Dessert
---     - Dog goes to bowl, feeds on supper
---     - Needs better pour sfx
--- 5) Gameplay
---     - Decide if dog should be spawned by using a consumable or just instantly
---     - To remove Sac Altar use?
--- 6) Bugfixes
--- 
--- Low Priority Bugs (Too Specific)
---     - Make her stop going to target pos if it stops existing after spawning
---     - Get the pickup back when HG is used after leaving the room mid-fetch
--- 
--- Attribution:
--- olga_yawn.wav: https://freesound.org/people/jinxycat49/sounds/490164/
--- feeding_bowl_pour.wav: dog_food_in_bowl.wav by smokevhstapes -- https://freesound.org/s/412382/ -- License: Attribution 4.0
--- feeding_bowl_fall.wav: Metal Dog Bowl Falling.wav by ChamoneSteyn -- https://freesound.org/s/542210/ -- License: Attribution 4.0