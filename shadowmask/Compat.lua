local _, SM = ...

local function maskFrameName(frame)
    if not frame then return end
    local unit = frame.unit or frame.displayedUnit or frame._euiUnit
    local nameText = frame.nameText or frame.NameText or frame.Name or frame.name
    if unit and nameText and nameText.SetText and UnitExists(unit) then
        local name = UnitName(unit)
        if name then nameText:SetText(SM:AliasForName(name)) end
    end
end

function SM:RefreshDandersFrames()
    local df = _G.DandersFrames
    if not df then return end
    -- DandersFrames exposes its frame objects; no secure attributes are changed.
    if df.GetAllFrames then
        for _, frame in ipairs(df:GetAllFrames()) do maskFrameName(frame) end
        return
    end
    -- Fallback for releases exposing only the documented public lookup API.
    local api = df.Api
    if api and api.GetFrameForUnit then
        -- DandersFrames puts the player in its party header as well.
        maskFrameName(api.GetFrameForUnit("player", "party"))
        for i = 1, 4 do maskFrameName(api.GetFrameForUnit("party" .. i, "party")) end
        for i = 1, 40 do maskFrameName(api.GetFrameForUnit("raid" .. i, "raid")) end
    end
end

function SM:RefreshEllesmereUI()
    local ui = _G.EllesmereUI
    if not ui then return end
    -- EllesmereUIUnitFrames exposes full frames as named globals while its
    -- internal frame registry stays module-local.
    local fullFrames = {
        { name = "EllesmereUIUnitFrames_Player", unit = "player" },
        { name = "EllesmereUIUnitFrames_Target", unit = "target" },
        { name = "EllesmereUIUnitFrames_Focus", unit = "focus" },
        { name = "EllesmereUIUnitFrames_TargetTarget", unit = "targettarget" },
        { name = "EllesmereUIUnitFrames_FocusTarget", unit = "focustarget" },
        { name = "EllesmereUIUnitFrames_Pet", unit = "pet" },
    }
    for _, entry in ipairs(fullFrames) do
        local frame = _G[entry.name]
        if frame and not frame._euiUnit then frame._euiUnit = entry.unit end
        maskFrameName(frame)
    end
    for index = 1, 5 do
        local frame = _G["EllesmereUIUnitFrames_Boss" .. index]
        if frame and not frame._euiUnit then frame._euiUnit = "boss" .. index end
        maskFrameName(frame)
    end
    -- EllesmereUI creates different frame modules based on enabled profile features.
    -- Its public unit frames retain unit/nameText fields; recurse only through its
    -- known module tables and never modify protected frame attributes.
    local candidates = { ui.UnitFrames, ui.PartyFrames, ui.RaidFrames, ui.Nameplates }
    for _, module in ipairs(candidates) do
        if type(module) == "table" then
            for _, frame in pairs(module.frames or module.Frames or {}) do maskFrameName(frame) end
        end
    end
end

function SM:RefreshCompat()
    self:RefreshDandersFrames()
    self:RefreshEllesmereUI()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(_, _, addon)
    if addon == "DandersFrames" or addon == "EllesmereUI" then
        C_Timer.After(0, function() SM:Refresh() end)
    end
end)

-- Other UI addons may repaint labels after roster events. A small out-of-combat
-- refresh keeps aliases present without touching their secure unit buttons.
local elapsed = 0
loader:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then
        elapsed = 0
        if SM.db and SM.db.enabled then SM:Refresh() end
    end
end)
