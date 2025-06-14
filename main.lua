OlgaMod = RegisterMod("Olga", 1)

if not REPENTOGON then return end

    -- Variables
OlgaMod.Game = Game()
OlgaMod.SfxMan = SFXManager()
OlgaMod.Room = function() return OlgaMod.Game:GetRoom() end

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

local scriptName = {
    "util",
    "olga_body",
    "olga_head",
    "fetch",
    "feeding_bowl",
    "debug",
    "patches"
}

for _, scripts in ipairs(scriptName) do
    include("scripts." .. scripts)
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
---     - Optimize
--- 2) Fetch [DONE]
--- 3) Petting Hand [DONE]
--- 4) Feeding Bowl
---     - Beggar (Bowl) that accepts breakfast-eque items
---     - Dog goes to bowl, feeds on supper and u get +1000 reputation points
--- 5) Gameplay
---     - Decide if dog should be spawned by using a consumable or just instantly
--- 
--- Make her stop going to target pos if it stops existing after spawning