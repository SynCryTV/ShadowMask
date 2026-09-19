local addonName, SM = ...
SM = SM or {}
_G.ShadowMask = SM

local defaults = {
    enabled = true,
    ownAlias = "Streamer",
    aliasPrefix = "Player",
    maskSelf = true,
    maskGroup = true,
    maskChat = true,
    hideFriendlyNameplates = true,
    autoDeclineBlocked = true,
    showMinimapButton = true,
    blocked = {},
    trusted = {},
}

local function copyDefaults(target, source)
    for key, value in pairs(source) do
        if target[key] == nil then
            target[key] = type(value) == "table" and {} or value
        end
    end
end

function SM:NormalizeName(name)
    if issecretvalue and issecretvalue(name) then return nil end
    if not name or name == "" then return nil end
    return (name:gsub("%s*%-%s*[^%s]+$", "")):lower()
end

function SM:SanitizeAlias(value, fallback)
    local alias = tostring(value or ""):gsub("%s+", "")
    return alias ~= "" and alias or fallback
end

function SM:IsTrusted(name)
    local key = self:NormalizeName(name)
    return key and self.db.trusted[key]
end

function SM:IsBlocked(name)
    local key = self:NormalizeName(name)
    return key and self.db.blocked[key]
end

function SM:IsActiveGroupMemberName(name)
    if not IsInGroup() then return false end
    local count = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
    local prefix = IsInRaid() and "raid" or "party"
    local key = self:NormalizeName(name)
    if not key then return false end
    for index = 1, count do
        local groupName = UnitName(prefix .. index)
        if not (issecretvalue and issecretvalue(groupName))
            and self:NormalizeName(groupName) == key then
            return true
        end
    end
    return false
end

function SM:AliasForName(name)
    if issecretvalue and issecretvalue(name) then return name end
    if not self.db.enabled or not name or name == "" then return name end
    local bareName = name:gsub("%s*%-%s*[^%s]+$", "")
    local ownName = UnitName("player")
    if self.db.maskSelf and ownName and (not issecretvalue or not issecretvalue(ownName)) and bareName:lower() == ownName:lower() then
        return self:SanitizeAlias(self.db.ownAlias, "Streamer")
    end
    if self:IsTrusted(bareName) then return name end
    if not self.db.maskGroup then return name end

    local prefix = self:SanitizeAlias(self.db.aliasPrefix, "Player")
    -- A fixed public alias is enough for targets, tooltips and chat-adjacent
    -- text. Numbered aliases exist only for people in the current party/raid.
    if not self:IsActiveGroupMemberName(bareName) then return prefix end

    self.aliases = self.aliases or {}
    local key = self:NormalizeName(bareName)
    if not key then return name end
    if not self.aliases[key] then
        self.aliasCount = (self.aliasCount or 0) + 1
        self.aliases[key] = string.format("%s%02d", prefix, self.aliasCount)
    end
    return self.aliases[key]
end

function SM:AliasForChatAuthor(name)
    if issecretvalue and issecretvalue(name) then return name end
    if not self.db or not self.db.enabled or not name then return name end
    local bareName = name:gsub("%s*%-%s*[^%s]+$", "")
    local ownName = UnitName("player")
    if self.db.maskSelf and ownName and (not issecretvalue or not issecretvalue(ownName)) and bareName:lower() == ownName:lower() then
        return self:SanitizeAlias(self.db.ownAlias, "Streamer")
    end
    if self:IsTrusted(bareName) then return name end
    -- Chat can contain thousands of unique authors. Never allocate an alias
    -- entry for it; a generic label is enough to conceal the sender.
    return self:SanitizeAlias(self.db.aliasPrefix, "Player")
end

local friendlyPlayerNameplateCVars = {
    "nameplateShowFriendlyPlayers",
    "nameplateShowFriends",
    -- EllesmereUI name-only mode explicitly enables this separate WoW CVar.
    "UnitNameFriendlyPlayerName",
    "nameplateShowOnlyNameForFriendlyPlayerUnits",
    -- Opposite-faction players use a separate Blizzard name display channel.
    "UnitNameEnemyPlayerName",
}

function SM:ApplyEllesmereFriendlyNameplatePrivacy(isHiding)
    local db = _G.EllesmereUINameplatesDB
    local ui = _G.EllesmereUI
    local module = ui and ui._ModuleNS and ui._ModuleNS.EllesmereUINameplates
    local profile = db and db.profile
    if not profile then return end
    if self.ellesmereFriendlyNameplateState == isHiding then return end
    self.ellesmereFriendlyNameplateState = isHiding

    local restore = self.db.ellesmereFriendlyPlayersRestore
    if isHiding then
        if not restore then
            restore = { value = profile.showFriendlyPlayers, wasNil = profile.showFriendlyPlayers == nil }
            self.db.ellesmereFriendlyPlayersRestore = restore
        end
        profile.showFriendlyPlayers = false
    elseif restore then
        profile.showFriendlyPlayers = restore.wasNil and nil or restore.value
        self.db.ellesmereFriendlyPlayersRestore = nil
    end
    if module and module.UpdateFriendlyNameplateSystem then
        module.UpdateFriendlyNameplateSystem()
    end
end

function SM:ApplyFriendlyNameplatePrivacy()
    if not self.db or not SetCVar then return end
    if InCombatLockdown() then
        self.friendlyNameplateUpdatePending = true
        return
    end
    self.friendlyNameplateUpdatePending = nil
    local isHiding = self.db.enabled and self.db.hideFriendlyNameplates
    self:ApplyEllesmereFriendlyNameplatePrivacy(isHiding)
    local restore = self.db.friendlyNameplateCVarRestore
    if isHiding then
        restore = restore or {}
        self.db.friendlyNameplateCVarRestore = restore
        for _, cvar in ipairs(friendlyPlayerNameplateCVars) do
            local value = GetCVar and GetCVar(cvar)
            if value ~= nil and restore[cvar] == nil then restore[cvar] = value end
            pcall(SetCVar, cvar, 0)
        end
    elseif restore then
        for cvar, value in pairs(restore) do pcall(SetCVar, cvar, value) end
        self.db.friendlyNameplateCVarRestore = nil
    end
end

function SM:Refresh()
    if self.ApplyFriendlyNameplatePrivacy then self:ApplyFriendlyNameplatePrivacy() end
    if self.RefreshFrames then self:RefreshFrames() end
    if self.RefreshCompat then self:RefreshCompat() end
    if self.RefreshGameTooltip then self:RefreshGameTooltip() end
    if self.UpdateMinimapButton then self:UpdateMinimapButton() end
end

function SM:Print(message)
    print("|cff8b5cf6ShadowMask|r " .. message)
end

function SM:AddName(listName, name)
    local key = self:NormalizeName(name)
    if not key then
        self:Print("Usage: /sm " .. listName .. " <name>")
        return
    end
    self.db[listName][key] = true
    self:Refresh()
    self:Print(name .. " added to " .. listName .. ".")
end

SLASH_SHADOWMASK1 = "/shadowmask"
SLASH_SHADOWMASK2 = "/sm"
SlashCmdList.SHADOWMASK = function(message)
    local command, rest = message:match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "toggle" or command == "" then
        SM.db.enabled = not SM.db.enabled
        SM:Refresh()
        SM:Print(SM.db.enabled and "enabled." or "disabled.")
    elseif command == "block" then
        SM:AddName("blocked", rest)
    elseif command == "trust" then
        SM:AddName("trusted", rest)
    elseif command == "unblock" or command == "untrust" then
        local key = SM:NormalizeName(rest)
        local list = command == "unblock" and "blocked" or "trusted"
        if key then SM.db[list][key] = nil; SM:Refresh(); SM:Print(rest .. " removed.") end
    elseif command == "alias" and rest ~= "" then
        SM.db.ownAlias = SM:SanitizeAlias(rest, "Streamer")
        SM:Refresh()
        SM:Print("Own alias set to " .. SM.db.ownAlias .. ".")
    elseif command == "options" then
        SM:OpenOptions()
    elseif command == "minimap" then
        SM:ToggleMinimapButton()
    else
        SM:Print("/sm options | minimap | toggle | block <name> | trust <name> | unblock <name> | untrust <name> | alias <text>")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        ShadowMaskDB = ShadowMaskDB or {}
        copyDefaults(ShadowMaskDB, defaults)
        SM.db = ShadowMaskDB
        SM.db.ownAlias = SM:SanitizeAlias(SM.db.ownAlias, "Streamer")
        SM.db.aliasPrefix = SM:SanitizeAlias(SM.db.aliasPrefix, "Player")
        SM.aliases, SM.aliasCount = {}, 0
        SM:InstallChatFilters()
        C_Timer.After(1, function() SM:Refresh() end)
        SM:Print("loaded. Type /sm for commands.")
    elseif event == "PLAYER_REGEN_ENABLED" and SM.friendlyNameplateUpdatePending then
        SM:ApplyFriendlyNameplatePrivacy()
    elseif event == "PARTY_INVITE_REQUEST" and SM.db and SM.db.enabled and SM.db.autoDeclineBlocked then
        local inviter = ...
        if SM:IsBlocked(inviter) and not InCombatLockdown() then
            DeclineGroup()
            SM:Print("Blocked invite from " .. inviter .. ".")
        end
    elseif SM.db then
        C_Timer.After(0, function() SM:Refresh() end)
    end
end)
