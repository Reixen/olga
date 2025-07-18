--#region Variables
local Mod = OlgaMod
--#endregion
-- dpower yearns for Ency entries
--#region Ency
if Encyclopedia then
    local info = {
        kit = {
            ID = Mod.FeedingBowl.FEEDING_KIT_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "Spawns a feeding bowl." },
                    { str = "Feeding Bowl and grants Isaac 1 Generic Food" },
                    { str = "Can be fed with Dessert, Dinner or Snack and will not be removed from Isaac's inventory" },
                },
            },
        },
        whistle = {
            ID = Mod.Whistle.WHISTLE_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "When near Olga, toggles her state between standing and sitting." },
                    { str = "When Olga is far, she runs towards you" },
                    { str = "When chasing Isaac for a while, Olga WILL catch you" },
                },
            },
        },
        stick = {
            ID = Mod.Fetch.STICK_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "Spawns a movable target that lasts longer when moved." },
                    { str = "Throws the Stick towards the target" },
                },
            },
        },
        ball = {
            ID = Mod.Fetch.TENNIS_BALL_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "Spawns a movable target that lasts longer when moved." },
                    { str = "Throws the Tennis Ball towards the target" },
                },
            },
        },
        godStick = {
            ID = Mod.Fetch.ROD_OF_THE_GODS_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "Spawns a movable target that lasts longer when moved." },
                    { str = "Throws the pole towards the target" },
                },
            },
        },
        crudeDrawing = {
            ID = Mod.Dog.Body.TRINKET_ID,
            WIKI = {
                { -- Effect
                    { str = "Effect", fsize = 2, clr = 3, halign = 0 },
                    { str = "Prevents Olga from disappearing next floor"},
                    { str = "Reduces the droprates of special consumables by half"}
                },
            },
        },
    }
    for name, PickupTable in pairs(info) do
        Encyclopedia.AddCard({
            Class = "Olga",
            ID = PickupTable.ID,
            WikiDesc = PickupTable.WIKI,
            ModName = "Olga",
        })
    end
end
--#endregion