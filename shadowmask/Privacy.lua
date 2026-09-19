local _, SM = ...

local function escapePattern(text)
    return text:gsub("(%W)", "%%%1")
end

function SM:ObserveName(name, realm)
    if issecretvalue and (issecretvalue(name) or issecretvalue(realm)) then return end
    if not name or name == "" then return end
    self.knownNames = self.knownNames or {}
    self.knownNames[name] = self:AliasForName(name)
    if realm and realm ~= "" then
        local fullName = name .. "-" .. realm
        self.knownNames[fullName] = self:AliasForName(name)
    end
end

function SM:ObserveUnit(unit)
    if issecretvalue and issecretvalue(unit) then return end
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local name, realm = UnitName(unit)
        self:ObserveName(name, realm)
    end
end

function SM:RefreshKnownNames()
    -- This cache is intentionally rebuilt from currently visible units. It is
    -- never written to SavedVariables and cannot grow from global chat traffic.
    self.knownNames = {}
    self.aliases = {}
    self.aliasCount = 0
    self:ObserveUnit("player")
    self:ObserveUnit("target")
    self:ObserveUnit("focus")
    self:ObserveUnit("mouseover")
    if InspectFrame and InspectFrame.unit then self:ObserveUnit(InspectFrame.unit) end
    for index = 1, 4 do self:ObserveUnit("party" .. index) end
    for index = 1, 40 do self:ObserveUnit("raid" .. index) end
end

function SM:MaskText(text)
    if issecretvalue and issecretvalue(text) then return text end
    if not self.db or not self.db.enabled or type(text) ~= "string" or text == "" then
        return text
    end
    local names = {}
    for name in pairs(self.knownNames or {}) do names[#names + 1] = name end
    table.sort(names, function(a, b) return #a > #b end)
    for _, name in ipairs(names) do
        local alias = self.knownNames[name]
        if alias and alias ~= name then
            text = text:gsub(escapePattern(name), function() return alias end)
        end
    end
    return text
end

local function setTooltipTitle(tooltip)
    if not tooltip or not tooltip.GetUnit then return end
    local _, unit = tooltip:GetUnit()
    if issecretvalue and issecretvalue(unit) then return end
    if not unit then return end
    local isPlayer = UnitIsPlayer(unit)
    if issecretvalue and issecretvalue(isPlayer) then return end
    if not isPlayer then return end
    local name = UnitName(unit)
    if issecretvalue and issecretvalue(name) then return end
    if not name then return end
    local title = tooltip:GetName() and _G[tooltip:GetName() .. "TextLeft1"]
    if title and title.SetText then title:SetText(SM:AliasForName(name)) end
end

local function maskTooltip(tooltip)
    setTooltipTitle(tooltip)
end

function SM:MaskCharacterFrame()
    if CharacterFrame and CharacterFrame.SetTitle and self.db and self.db.enabled then
        CharacterFrame:SetTitle(self:SanitizeAlias(self.db.ownAlias, "Streamer"))
    end
end

function SM:MaskInspectFrame()
    if not InspectFrame or not InspectFrame.SetTitle then return end
    local unit = InspectFrame.unit
    if issecretvalue and issecretvalue(unit) then return end
    if not unit then return end
    local name = UnitName(unit)
    if issecretvalue and issecretvalue(name) then return end
    if name then InspectFrame:SetTitle(self:AliasForName(name)) end
end

function SM:RefreshPrivacyPanels()
    self:MaskCharacterFrame()
    self:MaskInspectFrame()
end

function SM:InstallPrivacyHooks()
    if CharacterFrame and not self.characterHooked then
        self.characterHooked = true
        CharacterFrame:HookScript("OnShow", function() SM:MaskCharacterFrame() end)
        hooksecurefunc(CharacterFrame, "UpdateTitle", function() SM:MaskCharacterFrame() end)
    end
    if InspectFrame and not self.inspectHooked then
        self.inspectHooked = true
        InspectFrame:HookScript("OnShow", function() SM:MaskInspectFrame() end)
        if InspectFrame_UnitChanged then
            hooksecurefunc("InspectFrame_UnitChanged", function() SM:MaskInspectFrame() end)
        end
    end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, maskTooltip)
end

local setup = CreateFrame("Frame")
setup:RegisterEvent("PLAYER_LOGIN")
setup:RegisterEvent("ADDON_LOADED")
setup:SetScript("OnEvent", function(_, event, addon)
    if event == "PLAYER_LOGIN" or addon == "Blizzard_InspectUI" then
        C_Timer.After(0, function() SM:InstallPrivacyHooks(); SM:RefreshPrivacyPanels() end)
    end
end)
