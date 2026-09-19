local _, SM = ...

local ICON = "Interface\\Icons\\Spell_Shadow_Shadowform"

local function positionButton(button)
    local angle = SM.db.minimapAngle or 225
    local radians = math.rad(angle)
    local radius = 80
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * radius, math.sin(radians) * radius)
end

function SM:UpdateMinimapButton()
    if not self.minimapButton or not self.db then return end
    self.minimapButton:SetShown(self.db.showMinimapButton)
    if self.db.showMinimapButton then positionButton(self.minimapButton) end
end

function SM:CreateMinimapButton()
    if self.minimapButton then return end
    local button = CreateFrame("Button", "ShadowMaskMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetMovable(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", 0, 0)
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture(ICON)
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    button.icon = icon
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            SM.db.enabled = not SM.db.enabled
            SM:Refresh()
            SM:Print(SM.db.enabled and "enabled." or "disabled.")
        elseif Settings and SM.settingsCategory then
            Settings.OpenToCategory(SM.settingsCategory:GetID())
        end
    end)
    button:SetScript("OnDragStart", function(self) self:StartMoving() end)
    button:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local mx, my = Minimap:GetCenter()
        if x and y and mx and my then
            SM.db.minimapAngle = math.deg(math.atan2(y - my, x - mx))
        end
        positionButton(self)
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ShadowMask")
        GameTooltip:AddLine("Left-click: settings", 1, 1, 1)
        GameTooltip:AddLine("Right-click: toggle", 1, 1, 1)
        GameTooltip:AddLine("Drag: move button", 1, 1, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    self.minimapButton = button
    self:UpdateMinimapButton()
end

local setup = CreateFrame("Frame")
setup:RegisterEvent("PLAYER_LOGIN")
setup:SetScript("OnEvent", function()
    C_Timer.After(0, function() SM:CreateMinimapButton() end)
end)
