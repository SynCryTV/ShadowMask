local _, SM = ...

local function escapePattern(text)
    return text:gsub("(%W)", "%%%1")
end

function SM:ObserveName(name, realm)
    if not name or name == "" then return end
    self.knownNames = self.knownNames or {}
    self.knownNames[name] = self:AliasForName(name)
    if realm and realm ~= "" then
        local fullName = name .. "-" .. realm
        self.knownNames[fullName] = self:AliasForName(name)
    end
end

function SM:ObserveUnit(unit)
    if unit and UnitExists(unit) and UnitIsPlayer(unit) then
        local name, realm = UnitName(unit)
        self:ObserveName(name, realm)
    end
end

function SM:RefreshKnownNames()
    self:ObserveUnit("player")
    self:ObserveUnit("target")
    self:ObserveUnit("focus")
    self:ObserveUnit("mouseover")
    if InspectFrame and InspectFrame.unit then self:ObserveUnit(InspectFrame.unit) end
    for index = 1, 4 do self:ObserveUnit("party" .. index) end
    for index = 1, 40 do self:ObserveUnit("raid" .. index) end
    local now = GetTime()
    if not self.nextSocialScan or now >= self.nextSocialScan then
        self.nextSocialScan = now + 10
        if IsInGuild and IsInGuild() and GetNumGuildMembers and GetGuildRosterInfo then
            for index = 1, GetNumGuildMembers() do
                local name = GetGuildRosterInfo(index)
                self:ObserveName(name)
            end
        end
        if C_FriendList and C_FriendList.GetNumFriends and C_FriendList.GetFriendInfoByIndex then
            for index = 1, C_FriendList.GetNumFriends() do
                local info = C_FriendList.GetFriendInfoByIndex(index)
                if info then self:ObserveName(info.name) end
            end
        end
    end
end

function SM:MaskText(text)
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

function SM:MaskFrameText(frame)
    if not frame or not frame.GetRegions or not frame:IsVisible() then return end
    for _, region in ipairs({ frame:GetRegions() }) do
        if region:GetObjectType() == "FontString" and region.GetText and region.SetText then
            local original = region:GetText()
            local masked = self:MaskText(original)
            if masked ~= original then region:SetText(masked) end
        end
    end
end

function SM:MaskVisibleText()
    if not self.db or not self.db.enabled then return end
    local frame = EnumerateFrames()
    while frame do
        self:MaskFrameText(frame)
        frame = EnumerateFrames(frame)
    end
end

local function maskTooltip(tooltip)
    local _, unit = tooltip:GetUnit()
    if unit then SM:ObserveUnit(unit) end
    SM:MaskFrameText(tooltip)
end

if TooltipDataProcessor and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, maskTooltip)
end
