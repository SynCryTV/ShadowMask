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
    autoDeclineBlocked = true,
    showMinimapButton = true,
    minimapAngle = 225,
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
    if not name or name == "" then return nil end
    return (name:gsub("%s*%-%s*[^%s]+$", "")):lower()
end

function SM:IsTrusted(name)
    local key = self:NormalizeName(name)
    return key and self.db.trusted[key]
end

function SM:IsBlocked(name)
    local key = self:NormalizeName(name)
    return key and self.db.blocked[key]
end

function SM:AliasForName(name)
    if not self.db.enabled or not name or name == "" then return name end
    local bareName = name:gsub("%s*%-%s*[^%s]+$", "")
    local ownName = UnitName("player")
    if self.db.maskSelf and ownName and bareName:lower() == ownName:lower() then
        return self.db.ownAlias
    end
    if self:IsTrusted(bareName) then return name end
    if not self.db.maskGroup then return name end

    self.aliases = self.aliases or {}
    local key = self:NormalizeName(bareName)
    if not key then return name end
    if not self.aliases[key] then
        self.aliasCount = (self.aliasCount or 0) + 1
        self.aliases[key] = string.format("%s %02d", self.db.aliasPrefix, self.aliasCount)
    end
    return self.aliases[key]
end

function SM:Refresh()
    if self.RefreshFrames then self:RefreshFrames() end
    if self.RefreshCompat then self:RefreshCompat() end
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
        SM.db.ownAlias = rest; SM:Refresh(); SM:Print("Own alias set to " .. rest .. ".")
    elseif command == "options" then
        if Settings and SM.settingsCategory then
            Settings.OpenToCategory(SM.settingsCategory:GetID())
        elseif InterfaceOptionsFrame_OpenToCategory and SM.optionsPanel then
            InterfaceOptionsFrame_OpenToCategory(SM.optionsPanel)
        end
    else
        SM:Print("/sm options | toggle | block <name> | trust <name> | unblock <name> | untrust <name> | alias <text>")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PARTY_INVITE_REQUEST")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        ShadowMaskDB = ShadowMaskDB or {}
        copyDefaults(ShadowMaskDB, defaults)
        SM.db = ShadowMaskDB
        SM.aliases, SM.aliasCount = {}, 0
        SM:InstallChatFilters()
        C_Timer.After(1, function() SM:Refresh() end)
        SM:Print("loaded. Type /sm for commands.")
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
