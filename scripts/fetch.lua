--#region Variables
local Mod = OlgaDog

local game = Mod.Game

local FETCH = {}
local debugFetch = false

--#endregion
--#region Callbacks

---@param player EntityPlayer
function FETCH:OnUseBone(cardId, player, useFlags)
    local data = player:GetData()
    if not data.IsHoldingBone or data.cardId then 
        data.IsHoldingBone = false 
        data.cardId = cardId
    end
    if debugFetch then
        data.IsHoldingBone = true
        local cardConfig = Isaac.GetItemConfig():GetCard(cardId)
        local anm2Name = cardConfig.Name
        local animName = cardConfig.HudAnim
        local sprite = Sprite()
        -- make a bone
        print(anm2Name)
        sprite:Load(anm2Name, false)
        sprite:SetAnimation(animName, false)
        sprite:LoadGraphics()

        player:AnimatePickup(sprite, false, "LiftItem")
        print("success")
    end
    --return true
end
Mod:AddCallback(ModCallbacks.MC_PRE_USE_CARD, FETCH.OnUseBone)

function FETCH:OnRender()
    if not debugFetch then
        return
    end
    
    local player = Isaac.GetPlayer()
    local data = player:GetData()
    
    if not data.hasFamiliar then
        for _, familiar in ipairs(Isaac.FindByType(EntityType.ENTITY_FAMILIAR, Mod.Familiar)) do
            if not familiar then
                return
            end
            data.hasFamiliar = familiar
        end
    end

    data.doggyData = data.hasFamiliar:GetData()
    


    
    if debugFetch then
        if Input.IsActionPressed(ButtonAction.ACTION_SHOOTDOWN, 0) 
        and data.IsHoldingBone then
            player:AnimatePickup(Sprite(), false, "HideItem")
            data.IsHoldingBone = false
            print("what")
            Isaac.Spawn(EntityType.ENTITY_PICKUP, 300, data.cardId, player.Position, Vector.Zero, nil)
        end
        --player:StopExtraAnimation()
    end
end
Mod:AddCallback(ModCallbacks.MC_POST_RENDER, FETCH.OnRender)
