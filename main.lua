local addonName, AddonNS = ...

-- [[ Constants ]]
local DB_NAME = "MyTradeChatSpammerDB"
local TRADE_CHANNEL_NAME = "Trade - City"

local MAX_LOOP_WAIT_TIME_BETWEEN_MESSAGES = 120
local MIN_LOOP_WAIT_TIME_BETWEEN_MESSAGES = 30
local MIN_REQUESTES_IN_BETWEEN_MESSAGES = 5
local ADDON_CHAT_PREFIX = "|cffff2459My|r|cffffffffTradeChatSpammer|r"

-- [[ Dependencies ]]
AddonNS.events = {}
LibStub("MyLibrary_Events").embed(AddonNS.events)

local function addonPrint(...)
	print(ADDON_CHAT_PREFIX .. ":|cffaaaaff", ...,"|r")
end

-- [[ Database ]]
AddonNS.db = {
	singles = {},
	spam = false,
	play = 1,
}

local function initDb(db)
	AddonNS.db = db
	AddonNS.db.play = AddonNS.db.play or 1
	AddonNS.db.singles = AddonNS.db.singles or {}
	AddonNS.db.spam = AddonNS.db.spam or false
end

AddonNS.init = initDb
LibStub("MyLibrary_DB").asyncLoad(DB_NAME, AddonNS.init)

-- [[ Message Store Helpers ]]
local function getRecordsAsList()
	local singlesPlaylist = {}
	for _, message in pairs(AddonNS.db.singles) do
		table.insert(singlesPlaylist, message)
	end
	return singlesPlaylist
end

local function recordMessage(id, text)
	if (not id) or #id == 0 then
		local i = #getRecordsAsList()
		id = "#" .. i
		while AddonNS.db.singles["#" .. i] do
			i = i + 1
			id = "#" .. i
		end
	end

	AddonNS.db.singles[id] = text
end
AddonNS.record = recordMessage

local function deleteMessage(id)
	AddonNS.db.singles[id] = nil
end
AddonNS.delete = deleteMessage

local function sendNextMessage(where)
	local singlesPlaylist = getRecordsAsList()
	if #singlesPlaylist == 0 then
		return
	end

	AddonNS.db.play = AddonNS.db.play > #singlesPlaylist and 1 or AddonNS.db.play
	C_ChatInfo.SendChatMessage(singlesPlaylist[AddonNS.db.play], where, nil, 2)
	AddonNS.db.play = AddonNS.db.play + 1
end

local function sendById(id, where)
	local message = AddonNS.db.singles[id]
	if (not message) or #message == 0 then
		addonPrint("No message found for id:", id)
		return
	end

	C_ChatInfo.SendChatMessage(message, where, nil, 2)
end

-- [[ Slash Command Helpers ]]
local function trim(text)
	return text and text:match("^%s*(.-)%s*$") or ""
end

local function printUsage(usage)
	addonPrint("Usage: " .. usage)
end

local function printHelp()
	addonPrint("Commands:")
	addonPrint("/mtcs help")
	addonPrint("/mtcs r <message>")
	addonPrint("/mtcs record <id> <message>")
	addonPrint("/mtcs delete <id>")
	addonPrint("/mtcs print [id]")
	addonPrint("/mtcs send [id] [chatType]")
	addonPrint("/mtcs toggle")
end

local function parseSlashInput(message)
	message = trim(message)
	if #message == 0 then
		return "", ""
	end

	local cmd, text = message:match("^(%S+)%s*(.-)$")
	return string.lower(cmd or ""), text or ""
end

local commands = {
	help = function()
		printHelp()
	end,
	r = function(text)
		text = trim(text)
		if #text == 0 then
			printUsage("/mtcs r <message>")
			return
		end

		recordMessage(nil, text)
	end,
	record = function(text)
		text = trim(text)
		local id, message = text:match("^(%S+)%s+(.+)$")
		if (not id) or (not message) then
			printUsage("/mtcs record <id> <message>")
			return
		end

		recordMessage(id, message)
	end,
	delete = function(text)
		text = trim(text)
		if #text == 0 then
			printUsage("/mtcs delete <id>")
			return
		end

		deleteMessage(text)
	end,
	print = function(text)
		text = trim(text)
		if #text > 0 then
			print(text, AddonNS.db.singles[text])
			return
		end

		for id, message in pairs(AddonNS.db.singles) do
			print(id, message)
		end
	end,
	send = function(text)
		local id, where = strsplit(" ", text)
		where = where or "channel"

		if id and #id > 0 then
			sendById(id, where)
		else
			sendNextMessage(where)
		end
	end,
	toggle = function()
		AddonNS.toggleSpamming()
	end,
}

_G["SLASH_" .. addonName .. "SlashCommand1"] = "/mtcs"
SlashCmdList[addonName .. "SlashCommand"] = function(message)
	local cmd, text = parseSlashInput(message)
	if #cmd == 0 then
		commands.help()
		return
	end

	local handler = commands[cmd]
	if not handler then
		addonPrint("Unknown command:", cmd)
		commands.help()
		return
	end

	handler(text)
end

-- [[ Auto Spam Scheduler ]]
local spammingActive = false
local msgCounter = 0
local selfName = nil
local lastSpamTime = 0
local sendCallback = nil
local timer

local scheduleFrame = CreateFrame("Frame")

local function isOnTradeChat()
	return GetChannelName(GetChannelName(TRADE_CHANNEL_NAME)) > 0
end

local function getSelfName()
	if not selfName then
		local unitName, server = UnitFullName("player")
		if not server then
			return ""
		end
		selfName = unitName .. "-" .. server
	end
	return selfName
end

local function countTradeMessages(_, _, playerName, _, _, _, _, _, _, channelBaseName)
	msgCounter = msgCounter + ((channelBaseName == TRADE_CHANNEL_NAME and playerName ~= getSelfName()) and 1 or 0)
end

local function resetMessageCounter()
	msgCounter = 0
end

local function tryDispatchScheduledMessage()
	if sendCallback and (msgCounter >= MIN_REQUESTES_IN_BETWEEN_MESSAGES or time() - lastSpamTime > MAX_LOOP_WAIT_TIME_BETWEEN_MESSAGES) then
		lastSpamTime = time()
		scheduleFrame:Hide()
		sendNextMessage("CHANNEL")
		sendCallback()
		sendCallback = nil
		resetMessageCounter()
	end
end

scheduleFrame:EnableKeyboard(true)
scheduleFrame:SetPropagateKeyboardInput(true)
scheduleFrame:SetScript("OnKeyDown", tryDispatchScheduledMessage)
scheduleFrame:Hide()

local function scheduleNextMessage(callback)
	sendCallback = callback
	scheduleFrame:Show()
end

local function enableSpamming()
	msgCounter = MIN_REQUESTES_IN_BETWEEN_MESSAGES
	AddonNS.events:RegisterEvent("CHAT_MSG_CHANNEL", countTradeMessages)
	spammingActive = true

	local function spamLoop()
		local callback = function()
			if spammingActive then
				timer = C_Timer.NewTimer(MIN_LOOP_WAIT_TIME_BETWEEN_MESSAGES, spamLoop)
			end
		end
		scheduleNextMessage(callback)
	end

	spamLoop()
end

local function disableSpamming()
	AddonNS.events:UnregisterEvent("CHAT_MSG_CHANNEL")
	spammingActive = false
	if timer then
		timer:Cancel()
	end
	sendCallback = nil
	scheduleFrame:Hide()
end

local function updateSpammerState()
	if AddonNS.db.spam and not spammingActive and isOnTradeChat() then
		enableSpamming()
	elseif spammingActive and (not AddonNS.db.spam or not isOnTradeChat()) then
		disableSpamming()
	end
end

function AddonNS.toggleSpamming()
	if AddonNS.db.spam then
		AddonNS.db.spam = false
		addonPrint("disabled chat spamming")
	else
		AddonNS.db.spam = true
		addonPrint("enabled chat spamming")
	end
	updateSpammerState()
end

AddonNS.events:RegisterEvent("CHANNEL_UI_UPDATE", updateSpammerState)
AddonNS.events:RegisterEvent("PLAYER_ENTERING_WORLD", updateSpammerState)
