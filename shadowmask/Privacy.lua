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
    local isPlayer = UnitIsPlayer(unit)
    if issecretvalue and issecretvalue(isPlayer) then return end
    if not isPlayer then return end
    local name = UnitName(unit)
    if issecretvalue and issecretvalue(name) then return end
    if name then InspectFrame:SetTitle(self:AliasForName(name)) end
end

function SM:RefreshPrivacyPanels()
    self:MaskCharacterFrame()
    self:MaskInspectFrame()
end

function SM:MaskGameTooltipUnit(tooltip)
    local _, unit = tooltip:GetUnit()
    if issecretvalue and issecretvalue(unit) then return end
    if not unit then return end
    local isPlayer = UnitIsPlayer(unit)
    if issecretvalue and issecretvalue(isPlayer) then return end
    if not isPlayer then return end
    local name = tooltip:GetName()
    local title = name and _G[name .. "TextLeft1"]
    if title and title.SetText then title:SetText("") end
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
    if GameTooltip and not self.gameTooltipHooked then
        self.gameTooltipHooked = true
        -- EllesmereUI calls GameTooltip:SetUnit(frame._euiUnit) on hover and
        -- refreshes it repeatedly. SetUnit is a method, not a HookScript event
        -- on current Retail clients, so hook it directly after its native work.
        hooksecurefunc(GameTooltip, "SetUnit", function(tooltip)
            SM:MaskGameTooltipUnit(tooltip)
        end)
    end
end

local function suppressPlayerTooltipName(_, lineData)
    local unit = lineData.unitToken
    if issecretvalue and issecretvalue(unit) then return end
    if not unit then return end
    local isPlayer = UnitIsPlayer(unit)
    if issecretvalue and issecretvalue(isPlayer) then return end
    if not isPlayer then return end
    -- Returning true consumes only the UnitName line. Tooltip body, guild,
    -- level and NPC tooltips stay untouched.
    return true
end

local function suppressGuidResolvedTooltipName(tooltip, data)
    local guid = data and data.guid
    if issecretvalue and issecretvalue(guid) then return end
    if type(guid) ~= "string" or not guid:match("^Player%-") then return end
    -- Some custom unit frames expose no usable unitToken at all. A player
    -- GUID is still clean tooltip data and distinguishes players from NPCs.
    local title = tooltip:GetName() and _G[tooltip:GetName() .. "TextLeft1"]
    if title and title.SetText then title:SetText("") end
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    -- EllesmereUI and other custom unit frames can expose a secret or absent
    -- unitToken while retaining a clean Player GUID. This stays outside the
    -- secure tooltip pre-pipeline, which Midnight rejects for custom code.
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, suppressGuidResolvedTooltipName)
end

if TooltipDataProcessor and Enum and Enum.TooltipDataLineType then
    TooltipDataProcessor.AddLinePreCall(Enum.TooltipDataLineType.UnitName, suppressPlayerTooltipName)
end

local setup = CreateFrame("Frame")
setup:RegisterEvent("PLAYER_LOGIN")
setup:RegisterEvent("ADDON_LOADED")
setup:SetScript("OnEvent", function(_, event, addon)
    if event == "PLAYER_LOGIN" or addon == "Blizzard_InspectUI" then
        C_Timer.After(0, function() SM:InstallPrivacyHooks(); SM:RefreshPrivacyPanels() end)
    end
end)
