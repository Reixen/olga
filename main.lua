OlgaDog = RegisterMod("Olga", 1)

if not REPENTOGON then
    return
end

OlgaDog.Game = Game()
OlgaDog.SfxMan = SFXManager()
OlgaDog.Familiar = Isaac.GetEntityVariantByName("Olga")
OlgaDog.OlgaBody = {}
OlgaDog.OlgaHead = {}


include("scripts.olga_body")
include("scripts.olga_head")
include("scripts.petting_hand")
--include("scripts.fetch")