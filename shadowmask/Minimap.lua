local _, SM = ...

local BUTTON_POSITION = { x = 76, y = -6 }
local ICON = "Interface\\Icons\\Spell_Shadow_Shadowform"

function SM:SetMinimapButtonShown(isShown)
    self.db.showMinimapButton = isShown and true or false
    if not self.minimapButton then return end
    self.minimapButton:SetShown(self.db.showMinimapButton)
end

function SM:ToggleMinimapButton()
    self:SetMinimapButtonShown(not self.db.showMinimapButton)
    self:Print(self.db.showMinimapButton and "Minimap button shown." or "Minimap button hidden.")
end

function SM:UpdateMinimapButton()
    if self.minimapButton and self.db then
        self.minimapButton:SetShown(self.db.showMinimapButton)
    end
end

function SM:OpenOptions()
    if Settings and self.settingsCategory then
        Settings.OpenToCategory(self.settingsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory and self.optionsPanel then
        InterfaceOptionsFrame_OpenToCategory(self.optionsPanel)
    end
end

function SM:CreateMinimapButton()
    if self.minimapButton then return end
    local button = CreateFrame("Button", "ShadowMaskMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetPoint("CENTER", Minimap, "CENTER", BUTTON_POSITION.x, BUTTON_POSITION.y)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("CENTER", 0, 0)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            SM:OpenOptions()
        else
            SM.db.enabled = not SM.db.enabled
            SM:Refresh()
            SM:Print(SM.db.enabled and "enabled." or "disabled.")
        end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ShadowMask")
        GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: toggle on/off", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    self.minimapButton = button
    self:SetMinimapButtonShown(self.db.showMinimapButton)
end

local setup = CreateFrame("Frame")
setup:RegisterEvent("PLAYER_LOGIN")
setup:SetScript("OnEvent", function()
    C_Timer.After(0, function() SM:CreateMinimapButton() end)
end)
