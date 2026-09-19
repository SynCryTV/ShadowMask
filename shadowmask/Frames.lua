local _, SM = ...

local unitFrames = {
    { unit = "player", text = "PlayerFrameTitleText" },
    { unit = "target", text = "TargetFrameTextureFrameName" },
    { unit = "focus", text = "FocusFrameTextureFrameName" },
}

local function setUnitText(unit, fontString)
    if not fontString or not fontString.SetText or not UnitExists(unit) then return end
    local name = UnitName(unit)
    if name then fontString:SetText(SM:AliasForName(name)) end
end

function SM:RefreshFrames()
    if not self.db then return end
    if self.RefreshKnownNames then self:RefreshKnownNames() end
    for _, entry in ipairs(unitFrames) do setUnitText(entry.unit, _G[entry.text]) end

    for index = 1, 4 do
        setUnitText("party" .. index, _G["PartyMemberFrame" .. index .. "Name"])
    end
    for index = 1, 40 do
        setUnitText("raid" .. index, _G["CompactRaidFrame" .. index .. "Name"])
    end
    if self.MaskVisibleText then self:MaskVisibleText() end
end
