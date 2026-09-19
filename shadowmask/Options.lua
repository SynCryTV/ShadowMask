local _, SM = ...

local function createCheckBox(parent, label, key, y)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetPoint("TOPLEFT", 18, y)
    button.Text:SetText(label)
    button:SetScript("OnClick", function(self)
        SM.db[key] = self:GetChecked() and true or false
        SM:Refresh()
    end)
    parent.controls[key] = button
end

local function createEditBox(parent, label, key, y)
    local text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    text:SetPoint("TOPLEFT", 20, y)
    text:SetText(label)
    local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    box:SetSize(230, 24)
    box:SetPoint("TOPLEFT", 20, y - 22)
    box:SetAutoFocus(false)
    box:SetScript("OnEnterPressed", function(self)
        if self:GetText() ~= "" then
            SM.db[key] = SM:SanitizeAlias(self:GetText(), key == "ownAlias" and "Streamer" or "Player")
            self:SetText(SM.db[key])
            SM:Refresh()
        end
        self:ClearFocus()
    end)
    box:SetScript("OnEditFocusLost", function(self)
        if self:GetText() ~= "" then
            SM.db[key] = SM:SanitizeAlias(self:GetText(), key == "ownAlias" and "Streamer" or "Player")
            self:SetText(SM.db[key])
            SM:Refresh()
        end
    end)
    parent.controls[key] = box
end

function SM:RefreshOptions()
    local panel = self.optionsPanel
    if not panel or not self.db then return end
    for key, control in pairs(panel.controls) do
        if control:GetObjectType() == "CheckButton" then control:SetChecked(self.db[key])
        else control:SetText(self.db[key]) end
    end
end

function SM:CreateOptions()
    if self.optionsPanel then return end
    local panel = CreateFrame("Frame", "ShadowMaskOptionsPanel", UIParent)
    panel.name, panel.controls = "ShadowMask", {}
    self.optionsPanel = panel
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("ShadowMask")
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", 18, -42)
    subtitle:SetText("Streamer privacy controls. Changes apply immediately.")
    createCheckBox(panel, "Enable ShadowMask", "enabled", -72)
    createCheckBox(panel, "Mask own character name", "maskSelf", -102)
    createCheckBox(panel, "Mask group and unit-frame names", "maskGroup", -132)
    createCheckBox(panel, "Hide friendly player nameplates", "hideFriendlyNameplates", -162)
    createCheckBox(panel, "Mask names in chat", "maskChat", -192)
    createCheckBox(panel, "Block all incoming whispers", "blockWhispers", -222)
    createCheckBox(panel, "Decline all group invitations", "blockInvites", -252)
    createCheckBox(panel, "Decline all duel requests", "blockDuels", -282)
    createCheckBox(panel, "Show minimap button", "showMinimapButton", -312)
    createEditBox(panel, "Your stream alias", "ownAlias", -348)
    createEditBox(panel, "Alias prefix for other characters", "aliasPrefix", -412)
    panel:SetScript("OnShow", function() SM:RefreshOptions() end)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, "ShadowMask")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local setup = CreateFrame("Frame")
setup:RegisterEvent("PLAYER_LOGIN")
setup:SetScript("OnEvent", function()
    C_Timer.After(0, function() SM:CreateOptions() end)
end)
