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

local function sortedNames(list)
    local names = {}
    for name in pairs(list) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function SM:RefreshOptions()
    local panel = self.optionsPanel
    if not panel or not self.db then return end
    for key, control in pairs(panel.controls) do
        if control:GetObjectType() == "CheckButton" then control:SetChecked(self.db[key])
        else control:SetText(self.db[key]) end
    end
    panel.trustedList:SetText(table.concat(sortedNames(self.db.trusted), "\n"))
end

local function createTrustedEditor(panel, y)
    local label = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", 340, y)
    label:SetText("Trusted names")
    local list = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    list:SetMultiLine(true)
    list:SetAutoFocus(false)
    list:SetFontObject(ChatFontNormal)
    list:SetSize(220, 145)
    list:SetPoint("TOPLEFT", 340, y - 22)
    list:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    panel.trustedList = list
    local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    hint:SetPoint("TOPLEFT", 340, y - 172)
    hint:SetText("One name per line. Copy this field to export; paste and import to replace.")
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetSize(100, 24)
    save:SetPoint("TOPLEFT", 340, y - 194)
    save:SetText("Import / replace")
    save:SetScript("OnClick", function()
        local result = {}
        for name in list:GetText():gmatch("[^\r\n]+") do
            local key = SM:NormalizeName(name)
            if key then result[key] = true end
        end
        SM.db.trusted = result
        SM:Refresh()
        SM:RefreshOptions()
        SM:Print("Trusted names imported.")
    end)
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
    createCheckBox(panel, "Block whispers from known characters below level 21", "blockLowLevelWhispers", -222)
    createCheckBox(panel, "Decline invites from known characters below level 21", "blockLowLevelInvites", -252)
    createCheckBox(panel, "Decline all duel requests", "blockDuels", -282)
    createCheckBox(panel, "Show minimap button", "showMinimapButton", -312)
    createEditBox(panel, "Your stream alias", "ownAlias", -348)
    createEditBox(panel, "Alias prefix for other characters", "aliasPrefix", -412)
    createTrustedEditor(panel, -72)
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
