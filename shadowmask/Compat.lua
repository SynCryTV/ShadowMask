local _, SM = ...

local function maskFrameName(frame)
    if not frame then return end
    local unit = frame.unit or frame.displayedUnit or frame._euiUnit
    local nameText = frame.nameText or frame.NameText or frame.Name or frame.name
    if unit and nameText and nameText.SetText and UnitExists(unit) then
        local hostile = UnitCanAttack("player", unit)
        if (issecretvalue and issecretvalue(hostile)) or hostile then return end
        local isPlayer = UnitIsPlayer(unit)
        if (issecretvalue and issecretvalue(isPlayer)) or not isPlayer then return end
        local name = UnitName(unit)
        if name then nameText:SetText(SM:AliasForName(name)) end
    end
end

local function maskEllesmereRaidButton(module, button, unit, data)
    if not button then return end
    unit = unit or button:GetAttribute("unit")
    if issecretvalue and issecretvalue(unit) then return end
    if not unit or not UnitExists(unit) then return end
    local hostile = UnitCanAttack("player", unit)
    if (issecretvalue and issecretvalue(hostile)) or hostile then return end
    local isPlayer = UnitIsPlayer(unit)
    if (issecretvalue and issecretvalue(isPlayer)) or not isPlayer then return end
    local name = UnitName(unit)
    if issecretvalue and issecretvalue(name) then return end
    if not name then return end
    data = data or (module.GetFFD and module.GetFFD(button))
    if not data then return end
    local alias = SM:AliasForName(name)
    if data.nameText and data.nameText.SetText then data.nameText:SetText(alias) end
    if data.topNameBarText and data.topNameBarText.SetText then data.topNameBarText:SetText(alias) end
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
    self:InstallEllesmereNameProvider()
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
    self:InstallEllesmereRaidFrameProvider()
    self:RefreshEllesmereRaidFrames()
end

function SM:RefreshEllesmereRaidFrames()
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUIRaidFrames
    if not module then return end
    for _, button in ipairs(module._allButtons or {}) do
        maskEllesmereRaidButton(module, button)
    end
    for unit, button in pairs(module._partyUnitToButton or {}) do
        maskEllesmereRaidButton(module, button, unit)
    end
end

function SM:InstallEllesmereRaidFrameProvider()
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUIRaidFrames
    if not module or module._shadowMaskRaidProvider then return end
    module._shadowMaskRaidProvider = true
    -- Raid Frames exposes its finished paint function. Hooking it means the
    -- alias is applied in the same repaint as Ellesmere's own display name,
    -- avoiding the visible one-second name flash from polling.
    if module._PaintButtonTail then
        hooksecurefunc(module, "_PaintButtonTail", function(button, data, _, unit)
            maskEllesmereRaidButton(module, button, unit, data)
        end)
    end
    if module.RefreshAllNames then
        hooksecurefunc(module, "RefreshAllNames", function()
            SM:RefreshEllesmereRaidFrames()
        end)
    end
end

function SM:MaskTrackedNameplateText(fontString)
    local unit = self.nameplateTextUnits and self.nameplateTextUnits[fontString]
    if not unit or (issecretvalue and issecretvalue(unit)) then return end
    local hostile = UnitCanAttack("player", unit)
    if (issecretvalue and issecretvalue(hostile)) or hostile then return end
    local isPlayer = UnitIsPlayer(unit)
    if (issecretvalue and issecretvalue(isPlayer)) or not isPlayer then return end
    local name = UnitName(unit)
    if issecretvalue and issecretvalue(name) then return end
    if not name or self.nameplateWriting[fontString] then return end
    self.nameplateWriting[fontString] = true
    fontString:SetText(self:AliasForName(name))
    self.nameplateWriting[fontString] = nil
end

function SM:TrackNameplateText(fontString, unit)
    if not fontString or not fontString.SetText or not unit then return end
    self.nameplateTextUnits = self.nameplateTextUnits or setmetatable({}, { __mode = "k" })
    self.nameplateWriting = self.nameplateWriting or setmetatable({}, { __mode = "k" })
    self.nameplateNameHooked = self.nameplateNameHooked or setmetatable({}, { __mode = "k" })
    self.nameplateTextUnits[fontString] = unit
    if not self.nameplateNameHooked[fontString] then
        self.nameplateNameHooked[fontString] = true
        -- SetText is called again whenever Blizzard updates a target plate.
        -- Keep the tracked FontString in the closure: the hook argument is the
        -- new text, not a reliable frame reference.
        hooksecurefunc(fontString, "SetText", function()
            SM:MaskTrackedNameplateText(fontString)
        end)
    end
    self:MaskTrackedNameplateText(fontString)
end

function SM:RefreshNameplates()
    -- Blizzard and Plater both expose their live plates through this API.
    -- Only the known name FontStrings are tracked; there is no global frame scan.
    if C_NamePlate and C_NamePlate.GetNamePlates then
        for _, plate in ipairs(C_NamePlate.GetNamePlates() or {}) do
            local unit = plate.namePlateUnitToken
                or (plate.UnitFrame and (plate.UnitFrame.namePlateUnitToken or plate.UnitFrame.unit))
            local frame = plate.UnitFrame
            if frame then self:TrackNameplateText(frame.name or frame.unitName, unit) end
        end
    end

    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUINameplates
    if not module then return end
    for unit, plate in pairs(module.friendlyPlates or {}) do
        self:TrackNameplateText(plate.name, unit)
    end
    for unit, plate in pairs(module.pendingUnits or {}) do
        local frame = plate and plate.UnitFrame
        if frame then self:TrackNameplateText(frame.name or frame.unitName, unit) end
    end
end

function SM:TrackNameplateUnit(unit)
    if not unit or not C_NamePlate or not C_NamePlate.GetNamePlateForUnit then return end
    local plate = C_NamePlate.GetNamePlateForUnit(unit)
    local frame = plate and plate.UnitFrame
    if frame then self:TrackNameplateText(frame.name or frame.unitName, unit) end
end

function SM:RestoreTargetNameplateText()
    if not self.hiddenTargetNameTexts then return end
    for fontString in pairs(self.hiddenTargetNameTexts) do
        if fontString and fontString.SetAlpha then pcall(fontString.SetAlpha, fontString, 1) end
    end
    self.hiddenTargetNameTexts = nil
end

function SM:RestoreTargetNameplates()
    if not self.hiddenTargetNameplates then return end
    local hidden = self.hiddenTargetNameplates
    -- Clear the marker before restoring alpha so our SetAlpha hook does not
    -- immediately force a released (formerly targeted) plate back to zero.
    self.hiddenTargetNameplates = nil
    for frame, alpha in pairs(hidden) do
        if frame and frame.SetAlpha then pcall(frame.SetAlpha, frame, alpha) end
    end
end

function SM:HideTargetNameplate(frame)
    if not frame or not frame.SetAlpha then return end
    self.hiddenTargetNameplates = self.hiddenTargetNameplates or setmetatable({}, { __mode = "k" })
    self.targetNameplateAlphaHooks = self.targetNameplateAlphaHooks or setmetatable({}, { __mode = "k" })
    self.targetNameplateWriting = self.targetNameplateWriting or setmetatable({}, { __mode = "k" })
    if self.hiddenTargetNameplates[frame] == nil then
        local alpha = frame.GetAlpha and frame:GetAlpha() or 1
        self.hiddenTargetNameplates[frame] = (issecretvalue and issecretvalue(alpha)) and 1 or alpha
    end
    if not self.targetNameplateAlphaHooks[frame] then
        self.targetNameplateAlphaHooks[frame] = true
        -- Midnight's nameplate driver repaints the selected target after the
        -- target event. Keep only frames in our explicit target set hidden;
        -- released/other plates remain entirely under Blizzard's control.
        hooksecurefunc(frame, "SetAlpha", function()
            if SM.hiddenTargetNameplates and SM.hiddenTargetNameplates[frame]
                and not SM.targetNameplateWriting[frame] then
                SM.targetNameplateWriting[frame] = true
                frame:SetAlpha(0)
                SM.targetNameplateWriting[frame] = nil
            end
        end)
    end
    self.targetNameplateWriting[frame] = true
    pcall(frame.SetAlpha, frame, 0)
    self.targetNameplateWriting[frame] = nil
end

function SM:HideTargetNameplateText(fontString)
    if not fontString or not fontString.SetAlpha then return end
    self.hiddenTargetNameTexts = self.hiddenTargetNameTexts or setmetatable({}, { __mode = "k" })
    self.hiddenTargetNameTexts[fontString] = true
    pcall(fontString.SetAlpha, fontString, 0)
end

function SM:HideTargetPlayerNameplateForUnit(unit)
    if not unit or not self.db or not self.db.enabled or not UnitExists("target") then return end
    local isTarget, isPlayer = UnitIsUnit(unit, "target"), UnitIsPlayer("target")
    if (issecretvalue and (issecretvalue(isTarget) or issecretvalue(isPlayer))) or not isTarget or not isPlayer then return end

    -- The driver resolves both ordinary and Blizzard's "script" nameplates.
    -- The latter is the selected-player name-only display seen in the report,
    -- and is not always exposed by C_NamePlate's direct lookup.
    local driver = _G.NamePlateDriverFrame
    local plate = driver and driver.GetNamePlateForUnit and driver:GetNamePlateForUnit(unit)
    if not plate and C_NamePlate and C_NamePlate.GetNamePlateForUnit then
        plate = C_NamePlate.GetNamePlateForUnit(unit, issecure and issecure() or false)
    end
    local frame = plate and (plate.UnitFrame or plate.unitFrame)

    -- Ellesmere already has the robust pre-event Blizzard UnitFrame
    -- suppressor needed for its own plates. Reuse it for the selected player
    -- instead of competing with its frame ownership and layout hooks.
    local ui = _G.EllesmereUI
    local euiNameplates = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUINameplates
    if plate and euiNameplates and euiNameplates.HideBlizzardFrame then
        pcall(euiNameplates.HideBlizzardFrame, plate, unit)
    end
    self:HideTargetNameplate(plate)
    self:HideTargetNameplate(frame)
    if frame then
        self:HideTargetNameplateText(frame.name)
        self:HideTargetNameplateText(frame.unitName)
        self:HideTargetNameplateText(frame.nameText)
        self:HideTargetNameplateText(frame.subText1)
        self:HideTargetNameplateText(frame.subText2)
    end
end

function SM:InstallTargetNameplateSuppressor()
    if self.targetNameplateDriverHooked then return end
    local driver = _G.NamePlateDriverFrame
    if not driver or not driver.OnNamePlateAdded then return end
    self.targetNameplateDriverHooked = true

    -- Run in the driver's own nameplate-add pass. Ellesmere uses this same
    -- timing to suppress Blizzard's UnitFrame before NAME_PLATE_UNIT_ADDED;
    -- doing it later is too late for the selected name-only player display.
    hooksecurefunc(driver, "OnNamePlateAdded", function(_, unit)
        SM:HideTargetPlayerNameplateForUnit(unit)
    end)
end

function SM:RefreshTargetPlayerNameplatePrivacy()
    self:RestoreTargetNameplateText()
    self:RestoreTargetNameplates()
    -- Target privacy is independent from the optional global nameplate toggle:
    -- streamers may keep ordinary plates on while their selected player must
    -- never expose a name above the character.
    if not self.db or not self.db.enabled or not UnitExists("target") then return end
    local isPlayer = UnitIsPlayer("target")
    if (issecretvalue and issecretvalue(isPlayer)) or not isPlayer then return end

    -- Blizzard shows a selected player's name again even with the name CVar
    -- disabled. The target may be assigned to a UnitFrame on the next render
    -- update; the exact NAME_PLATE_UNIT_ADDED path below covers that case.
    self:HideTargetPlayerNameplateForUnit("target")

    -- Ellesmere's enemy plate is a separate custom frame. Its plate registry
    -- retains the real unit token, so its name and subtitle can be handled
    -- directly without scanning arbitrary UI frames.
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUINameplates
    for unit, euiPlate in pairs(module and module.plates or {}) do
        local isTarget = UnitIsUnit(unit, "target")
        if not (issecretvalue and issecretvalue(isTarget)) and isTarget then
            self:HideTargetNameplate(euiPlate)
            self:HideTargetNameplateText(euiPlate.name)
            self:HideTargetNameplateText(euiPlate.subText1)
            self:HideTargetNameplateText(euiPlate.subText2)
            self:HideTargetNameplateText(euiPlate.guild)
            self:HideTargetNameplateText(euiPlate.guildText)
        end
    end
end

function SM:RefreshTargetPlayerNameplatePrivacyDeferred()
    self:RefreshTargetPlayerNameplatePrivacy()
    -- Blizzard may assign the selected player's UnitFrame one render later.
    -- Recheck the same explicit target without scanning arbitrary frames.
    C_Timer.After(0.05, function() SM:RefreshTargetPlayerNameplatePrivacy() end)
    C_Timer.After(0.20, function() SM:RefreshTargetPlayerNameplatePrivacy() end)
end

function SM:AliasForDamageMeterGUID(guid)
    if (issecretvalue and issecretvalue(guid)) or type(guid) ~= "string" then return nil end
    local units = { "player" }
    if IsInRaid() then
        for index = 1, GetNumGroupMembers() do units[#units + 1] = "raid" .. index end
    elseif IsInGroup() then
        for index = 1, GetNumSubgroupMembers() do units[#units + 1] = "party" .. index end
    end
    for _, unit in ipairs(units) do
        local unitGuid = UnitGUID(unit)
        if not (issecretvalue and issecretvalue(unitGuid)) and unitGuid == guid then
            local name = UnitName(unit)
            if not (issecretvalue and issecretvalue(name)) and name then
                return self:AliasForName(name)
            end
        end
    end
end

function SM:MaskEllesmereDamageMeterBar(module, bar, forceFallback)
    if not self.db or not self.db.enabled or not bar or self.damageMeterWriting and self.damageMeterWriting[bar] then return end
    -- Keep the last safe alias per pooled row. This avoids the local player's
    -- row visibly bouncing Player -> Streamer on every meter update while the
    -- source is briefly unavailable at the start of a render pass.
    local fallback = bar._shadowMaskAlias or self:SanitizeAlias(self.db.aliasPrefix, "Player")
    -- Ellesmere writes the label before it stores the row source. The hook
    -- therefore has no safe identity on that first write; replace it at once
    -- so an original name never reaches a rendered frame.
    if forceFallback or not bar._src then
        if not bar.label or not bar.label.SetText then return end
        self.damageMeterWriting = self.damageMeterWriting or setmetatable({}, { __mode = "k" })
        self.damageMeterWriting[bar] = true
        bar.label:SetText(fallback)
        self.damageMeterWriting[bar] = nil
        return
    end
    local src = bar._src
    local class = src and src.classFilename
    -- Ellesmere keeps classFilename public while name and GUID become secret
    -- in combat. This identifies player rows without ever inspecting a name.
    if (issecretvalue and issecretvalue(class)) or type(class) ~= "string" or not RAID_CLASS_COLORS[class] then return end

    local guid = src.sourceGUID
    if issecretvalue and issecretvalue(guid) then guid = nil end
    if not guid and module._ResolveGroupGUID then guid = module._ResolveGroupGUID(src) end
    local alias = self:AliasForDamageMeterGUID(guid)
    local isLocal = src.isLocalPlayer
    if not alias and not (issecretvalue and issecretvalue(isLocal)) and isLocal == true then
        alias = self:SanitizeAlias(self.db.ownAlias, "Streamer")
    end
    -- When two group members share the same class/spec the restricted API
    -- cannot resolve a GUID in combat. Use a generic alias rather than leak.
    alias = alias or fallback
    if not bar.label or not bar.label.SetText then return end
    self.damageMeterWriting = self.damageMeterWriting or setmetatable({}, { __mode = "k" })
    bar._shadowMaskAlias = alias
    self.damageMeterWriting[bar] = true
    bar.label:SetText(alias)
    self.damageMeterWriting[bar] = nil
end

function SM:TrackEllesmereDamageMeterBar(module, bar)
    if not bar or not bar.label or not bar.label.SetText then return end
    self.damageMeterLabels = self.damageMeterLabels or setmetatable({}, { __mode = "k" })
    if not self.damageMeterLabels[bar.label] then
        self.damageMeterLabels[bar.label] = true
        -- RefreshMeter renders every combat tick; replacement therefore runs
        -- in that same draw pass instead of waiting for combat to end.
        hooksecurefunc(bar.label, "SetText", function()
            SM:MaskEllesmereDamageMeterBar(module, bar, true)
        end)
    end
    self:MaskEllesmereDamageMeterBar(module, bar)
end

function SM:RefreshEllesmereDamageMeter()
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUIDamageMeters
    if not module then return end
    for _, window in ipairs(module._windows or {}) do
        for _, bar in ipairs(window.rowPool or {}) do
            self:TrackEllesmereDamageMeterBar(module, bar)
        end
    end
end

function SM:InstallEllesmereDamageMeterProvider()
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUIDamageMeters
    if not module or module._shadowMaskDamageMeterProvider then return end
    module._shadowMaskDamageMeterProvider = true
    if module.RefreshMeter then
        hooksecurefunc(module, "RefreshMeter", function()
            SM:RefreshEllesmereDamageMeter()
        end)
    end
end

function SM:InstallEllesmereNameProvider()
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUIUnitFrames
    if not module or module._shadowMaskNameProvider or not module.ResolveUnitNickname then return end

    local original = module.ResolveUnitNickname
    module.ResolveUnitNickname = function(unit)
        local name = UnitName(unit)
        local isPlayer = UnitIsPlayer(unit)
        local hostile = UnitCanAttack("player", unit)
        if not (issecretvalue and (issecretvalue(name) or issecretvalue(isPlayer) or issecretvalue(hostile)))
            and name and isPlayer and not hostile then
            return SM:AliasForName(name)
        end
        return original(unit)
    end
    module._shadowMaskNameProvider = true
    if _G._EUF_RefreshUnitNames then _G._EUF_RefreshUnitNames() end
end

function SM:RefreshCompat()
    self:InstallTargetNameplateSuppressor()
    self:RefreshDandersFrames()
    self:RefreshEllesmereUI()
    self:RefreshNameplates()
    self:RefreshTargetPlayerNameplatePrivacy()
    self:InstallEllesmereDamageMeterProvider()
    self:RefreshEllesmereDamageMeter()
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("NAME_PLATE_UNIT_ADDED")
loader:SetScript("OnEvent", function(_, event, addon)
    if event == "NAME_PLATE_UNIT_ADDED" then
        -- Friendly player plates are intentionally omitted from some
        -- GetNamePlates() results. Resolve this exact WoW unit after all
        -- nameplate addons have completed their own add handler.
        C_Timer.After(0, function()
            SM:TrackNameplateUnit(addon)
            SM:HideTargetPlayerNameplateForUnit(addon)
        end)
        return
    end
    if addon == "DandersFrames" or addon == "EllesmereUI" or addon == "EllesmereUINameplates" or addon == "EllesmereUIDamageMeters" or addon == "Plater" then
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
