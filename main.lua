OlgaDog = RegisterMod("Olga", 1)

if not REPENTOGON then return end
    
    -- Variables
OlgaDog.Game = Game()
OlgaDog.SfxMan = SFXManager()
OlgaDog.Familiar = Isaac.GetEntityVariantByName("Olga")

    -- Le tables
OlgaDog.OlgaBody = {}
OlgaDog.OlgaHead = {}
OlgaDog.PettingHand = {}
OlgaDog.Fetch = {}
OlgaDog.FeedingBowl = {}

include("scripts.olga_body")
include("scripts.olga_head")
include("scripts.petting_hand")
-- include("scripts.fetch")

----------------------------------------------------------------
---                          TO DO:                          ---
----------------------------------------------------------------
---
--- 1) Head + Body
---     - Animations bro
---         - Sleep
---         - Feed on thy bowl
---         - Running
---         - Signature bark bark idle animation
---         - 3 more idle animations
---     - Optimize
--- 2) Fetch
---     - Create fetching Stick (card)
---     - Create Mark sprite for fetching
---         - Be able to move with more keys instead of one
---     - Better variable names lol
---     - Sprite for the thrown stick
---     - thrown tear having no fixed time to arrive to pos
---     - BugFix!
---         - dog retargets when throwing another pickup (maybe not an issue)
---         - dog gets stuck when pickup is not present at target
--- 3) Petting Hand
---     - Change skin color when reviving
--- 4) Feeding Bowl
---     - Consumable that spawns the bowl
---     - Beggar (Bowl) that accepts breakfast-eque items
---     - Dog goes to bowl, feeds on supper and u get +1000 reputation points
--- 5) Gameplay
---     - When you have the familiar, room clear rewards have a chance of
---       spawning either the dog bowl/stick. Cannot get duplicates
---     - stick can be used multiple times, bowl only once
---     - Decide if dog should be spawned by using a consumable or just instantly
---     - Decide if the dog should go away after a floor
---         - Dog spawns "Crude Drawing" trinket when disappearing
---             - does nothing
--- 