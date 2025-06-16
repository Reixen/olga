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

local fileStructure = {
    ["utility"] = {
        "save_manager",
        "util",
        "debug",
    },
    ["dog"] = {
        "body",
        "head",
    },
    ["interactables"] = {
        "fetch",
        "feeding_bowl",
    },
    [""] = {
        "patches",
    }
}

for folderName, scripts in pairs(fileStructure) do
    for _, fileName in ipairs(scripts) do
        if fileName == "save_manager" then
            OlgaMod.SaveManager = include("scripts." .. folderName .. "."  .. fileName)
        else
            include("scripts." .. folderName .. "."  .. fileName)
        end
    end
end

OlgaMod.SaveManager.Init(OlgaMod)

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
--- 2) Fetch
---     - Use Save manager
--- 3) Petting Hand [DONE]
--- 4) Feeding Bowl
---     - Animations
---         - Snack
---         - Dinner
---         - Generic
---         - Dessert
---     - Dog goes to bowl, feeds on supper and u get +1000 reputation points
---     - Use Savemanager
--- 5) Gameplay
---     - Decide if dog should be spawned by using a consumable or just instantly
---     - To remove Sac Altar use?
--- 6) Bugfixes
---     - Make her stop going to target pos if it stops existing after spawning
---     - Glowing Hourglass
---         - Get the pickup back when HG is used after leaving the room mid-fetch
---         - Prevent her from duplicating
---         - Lose Reputation points
--- 
--- Attribution:
--- olga_yawn.wav: https://freesound.org/people/jinxycat49/sounds/490164/
--- feeding_bowl_pour.wav: dog_food_in_bowl.wav by smokevhstapes -- https://freesound.org/s/412382/ -- License: Attribution 4.0
--- feeding_bowl_fall.wav: Metal Dog Bowl Falling.wav by ChamoneSteyn -- https://freesound.org/s/542210/ -- License: Attribution 4.0