OlgaMod = RegisterMod("Olga", 1)

if not REPENTOGON then return end

    -- Variables
OlgaMod.Game = Game()
OlgaMod.SfxMan = SFXManager()
OlgaMod.Room = function() return OlgaMod.Game:GetRoom() end

OlgaMod.Dog = {}
OlgaMod.PettingHand = {}
OlgaMod.Util = {}
OlgaMod.Debug = {}
OlgaMod.Fetch = {}

OlgaMod.Dog.VARIANT = Isaac.GetEntityVariantByName("Olga")
OlgaMod.Pickup = {
    CRUDE_DRAWING_ID = Isaac.GetTrinketIdByName("Crude Drawing"),
    STICK_ID = Isaac.GetCardIdByName("Stick"),
    FEEDING_BOWL_ID = Isaac.GetCardIdByName("Feeding Bowl"),
    TENNIS_BALL_ID = Isaac.GetCardIdByName("Tennis Ball")
}

local scriptName = {
    "util",
    "olga_body",
    "olga_head",
    "petting_hand",
    "fetch",
    --"feeding_bowl",
    "debug",
}

for _, scripts in ipairs(scriptName) do
    include("scripts." .. scripts)
end

----------------------------------------------------------------
---                          TO DO:                          ---
----------------------------------------------------------------
---
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
---             - Bark Bark Idle Animtion
---         - Head Specific Idle Animations
---             - Curious
---             - Lean
---     - Optimize
---     - Fix Head Reflection being wonky
--- 2) Fetch
---     - Create Mark sprite for fetching
---         - Be able to move with more keys instead of one
--- 3) Petting Hand
---     - Change skin color when reviving
--- 4) Feeding Bowl
---     - Beggar (Bowl) that accepts breakfast-eque items
---     - Dog goes to bowl, feeds on supper and u get +1000 reputation points
--- 5) Gameplay
---     - When you have the familiar, room clear rewards have a chance of
---       spawning either the dog bowl/stick. Cannot get duplicates
---     - stick can be used multiple times, bowl only once
---     - Decide if dog should be spawned by using a consumable or just instantly