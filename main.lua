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

----------------------------------------------------------------
---                          TO DO:                          ---
----------------------------------------------------------------
--- 1) Bugfixes - In progress!
--- 2) Sfx - Currently under review!
--- 
--- Future TODO:
---     - Lie Down
---        - When initialized, sleep
---        - Wake up and stretch if approached.
---        - Lie back to position if within range, otherwise stand.
---     - Bork Set 2
---     
--- Low Priority Bugs
---     - Make her stop going to target pos if it stops existing after spawning
---     - Get the pickup back when HG is used after leaving the room mid-fetch
---     - Make her stop going to the fetching object when the campfire is at that position
--- 
--- Attribution:
--- yawn: https://freesound.org/people/jinxycat49/sounds/490164/
--- feeding_bowl_pour.wav: Pouring dog food into bowl by Ryntjie -- https://freesound.org/s/365052/ -- License: Attribution NonCommercial 3.0
--- feeding_bowl_fall.wav: Metal Dog Bowl Falling.wav by ChamoneSteyn -- https://freesound.org/s/542210/ -- License: Attribution 4.0
--- pant_1 and pant_2: dog panting + half growl + whine.WAV by pogmothoin -- https://freesound.org/s/401307/ -- License: Attribution 4.0
--- crunch and mini_crunch.wavs: Dog_Eat.wav by Blu_150058 -- https://freesound.org/s/326212/ -- License: Attribution NonCommercial 3.0
--- gulp.wav: Swallowing and gulping by 170084 -- https://freesound.org/s/408205/ -- License: Attribution NonCommercial 4.0
---
--- Dog Sounds by iainmccurdy -- https://freesound.org/s/640743/ -- License: Attribution 4.0 -- Unused