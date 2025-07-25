--#region Variables
local Mod = OlgaMod

local Whistle = {}
OlgaMod.Whistle = Whistle

local sfxMan = Mod.SfxMan
local Util = Mod.Util
local Head = Mod.Dog.Head
local Body = Mod.Dog.Body

Whistle.WHISTLE_ID = Mod.PickupHandler.Pickup[PickupVariant.PICKUP_TAROTCARD].WHISTLE_ID
Whistle.WHISTLE_SFX = Isaac.GetSoundIdByName("Dog Whistle")
--#endregion
--#region EID Compatibility
if EID then
    EID:addIcon("Card" .. Whistle.WHISTLE_ID, "Whistle", 0, 9, 9, 6, 6, Mod.EIDSprite)

    EID:addCard(Whistle.WHISTLE_ID,
        "When near Olga, toggles her state between standing and sitting"..
        "#When Olga is far, she runs towards you"..
        "# {{Warning}} When chasing Isaac for a while, Olga WILL catch you"
    )
end
Mod.EncyCompat[#Mod.EncyCompat+1] = function()
    local encyWiki = {
        { -- Effect
            { str = "Effect", fsize = 2, clr = 3, halign = 0 },
            { str = "When near Olga, toggles her state between standing and sitting." },
            { str = "When Olga is far, she runs towards you" },
            { str = "When chasing Isaac for a while, Olga WILL catch you" },
        },
        { -- Notes
            { str = "Notes", fsize = 2, clr = 3, halign = 0 },
            { str = "The sound effects dont mean anything aside from how long you've survived"},
            { str = "Try to not get caught for as long as you can!"}
        },
    }
    Encyclopedia.AddCard({
        Class = "Olga",
        ID = Whistle.WHISTLE_ID,
        WikiDesc = encyWiki,
        ModName = "Olga",
        UnlockFunc = function(self)
            local gameData = Isaac.GetPersistentGameData()
            local whistleAch = Util.Achievements.WHISTLE
            if not gameData:Unlocked(whistleAch.ID) then
                self.Desc = "Get " ..tostring(whistleAch.Requirement) .. " Pup Points to unlock!"
                return self
            end
        end
    })
end
if MinimapAPI then
    MinimapAPI:AddPickup(
        "Whistle", "Whistle",
        EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_TAROTCARD, Whistle.WHISTLE_ID,
        nil, "OlgaPickup")
    MinimapAPI:AddIcon("Whistle", Mod.MinimapSprite, "Whistle")
end
--#endregion
--#region Whistle Callbacks
---@param cardId Card
---@param player EntityPlayer
function Whistle:OnWhistleUse(cardId, player)
    player:AddCard(cardId)
    sfxMan:Play(Whistle.WHISTLE_SFX, 1.2, 2, false, math.random(14, 18) / 20)

    for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Dog.VARIANT)) do
        local olga = familiar:ToFamiliar() ---@cast olga EntityFamiliar
        local data = olga:GetData() ---@cast data DogData

        if Util:IsBusy(olga) or not data.headRender then
            if data.eventTimer > Body.RIDING_TRANSITION_EVENT
            and olga.State == Util.DogState.WHISTLED then
                Head:DoIdleAnimation(olga, data, Head.IdleAnim[2])
            end
            goto skip
        end

        if Util:IsWithin(olga, player.Position, Head.HAPPY_DISTANCE) then
            local sprite = olga:GetSprite()
            if olga.State == Util.DogState.SITTING then
                sprite:Play(Util.BodyAnim.SIT_TO_STAND, true)
                data.eventCD = Body.EVENT_COOLDOWN + olga.FrameCount
            elseif olga.State == Util.DogState.STANDING then
                sprite:Play(Util.BodyAnim.STAND_TO_SIT, true)
                olga.Velocity = Vector.Zero
                data.targetPos = nil
            end
            data.eventCD = (Body.EVENT_COOLDOWN * 2) + olga.FrameCount
            goto skip
        end

        data.targetPlayer = player
        olga.State = Util.DogState.WHISTLED
        ::skip::
    end
end
Mod:AddCallback(ModCallbacks.MC_USE_CARD, Whistle.OnWhistleUse, Whistle.WHISTLE_ID)
--#endregion