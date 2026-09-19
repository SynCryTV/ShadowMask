local _, SM = ...

local chatEvents = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM",
    "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM",
}

function SM:FilterChat(_, event, message, author, ...)
    if not self.db or not self.db.enabled then return false end
    -- In chat filters the sender GUID is the 12th event argument (10th in
    -- this vararg list).  Unknown whisperers cannot be level-checked safely.
    local guid = select(10, ...)
    if event == "CHAT_MSG_WHISPER" and self.db.blockLowLevelWhispers and self:IsKnownLowLevel(guid) then
        return true
    end
    if not self.db.maskChat then return false end
    if not author then return false end
    local alias = self:AliasForChatAuthor(author)
    if alias == author then return false end
    -- The author argument controls Blizzard's chat header. Replacing text as well
    -- catches messages that repeat a character name in their body.
    message = message:gsub(author, alias)
    return false, message, alias, ...
end

function SM:InstallChatFilters()
    for _, event in ipairs(chatEvents) do
        ChatFrame_AddMessageEventFilter(event, function(...) return SM:FilterChat(...) end)
    end
end
