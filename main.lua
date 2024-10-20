OlgaDog = RegisterMod("Olga", 1)

if not REPENTOGON then
    return
end

OlgaDog.Game = Game()
OlgaDog.SfxMan = SFXManager()
OlgaDog.Familiar = Isaac.GetEntityVariantByName("Olga")

include("scripts.olga")
include("scripts.petting_hand")