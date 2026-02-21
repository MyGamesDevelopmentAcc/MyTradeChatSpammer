local addonName, AddonNS = ...

-- events
AddonNS.events = {};
LibStub("MyLibrary_Events").embed(AddonNS.events);

-- DB

AddonNS.db = {};
AddonNS.db.singles = {};
AddonNS.db.spam = false;
AddonNS.db.play = 1;
AddonNS.init = function(db)
	AddonNS.db = db;
	AddonNS.db.play = AddonNS.db.play or 1;
	AddonNS.db.singles = AddonNS.db.singles or {};
	AddonNS.db.spam = AddonNS.db.spam or false;
end
LibStub("MyLibrary_DB").asyncLoad("MyTradeChatSpammerDB", AddonNS.init);
_G["SLASH_" .. addonName .. "SlashCommand1"] = "/mtcs"

-- CONFIG
local maxWaitSpamTime = 120; -- maximal to send regardless
local minLoopTime = 15;      -- minmal can be set to 15 but it then spams a lot
local minReqMessagesInBetween = 5;

-- /mtcs r -- records with random id
-- [not yet implemented] /mtcs send MY_SUPER_ID1 say|trade
-- [not yet implemented] /mtcs send MY_SUPER_ID1
-- [not yet implemented] /mtcs sendnext MY_SUPERGROUP_ID1 say|trade
-- [not yet implemented] /mtcs clear ID
-- [not yet implemented] /mtcs clearall
-- [not yet implemented] /mtcs print (optional)ID --if ID not provided, prints all recorded messages

-- /mtcs r -- records with random id
-- /mtcs record MY_SUPER_ID1 WTS super cost thingy
-- /mtcs toggle -- enable and disable spmming
-- /mtcs delete ID -- removes given Id

local commands = {};
local function getRecordsAsList()
	local singlesPlaylist = {}
	for i, v in pairs(AddonNS.db.singles) do
		table.insert(singlesPlaylist, v);
	end
	return singlesPlaylist;
end
local function trim(txt)
	return txt and txt:match("^%s*(.-)%s*$") or "";
end

local function record(id, txt)
	if not id or id and #id == 0 then
		local i = #getRecordsAsList()
		id = "#" .. i;
		while AddonNS.db.singles["#" .. i] do
			i = i + 1
			id = "#" .. i
		end
	end
	AddonNS.db.singles[id] = txt;
end
local function delete(id)
	AddonNS.db.singles[id] = nil;
end
AddonNS.record = record;
AddonNS.delete = delete;

_G["MTCS_API_Record"] = record;
commands["r"] = function(txt)
	txt = trim(txt);
	if (#txt == 0) then
		print("Usage: /mtcs r <message>");
		return;
	end
	record(nil, txt)
end

commands["delete"] = function(txt)
	txt = trim(txt);
	if (#txt == 0) then
		print("Usage: /mtcs delete <id>");
		return;
	end
	delete(txt);
end

commands["record"] = function(txt)
	txt = trim(txt);
	local id, message = txt:match("^(%S+)%s+(.+)$");
	if (not id or not message) then
		print("Usage: /mtcs record <id> <message>");
		return;
	end
	record(id, message)
end

local function playNext(where)
	local singlesPlaylist = getRecordsAsList();
	if (#singlesPlaylist > 0) then
		AddonNS.db.play = AddonNS.db.play > #singlesPlaylist and 1 or AddonNS.db.play;
		SendChatMessage(singlesPlaylist[AddonNS.db.play], where, nil, 2);
		AddonNS.db.play = AddonNS.db.play + 1;
	end
end

local function sendById(id, where)
	local message = AddonNS.db.singles[id];
	if (not message or #message == 0) then
		print("No message found for id:", id);
		return;
	end
	SendChatMessage(message, where, nil, 2);
end

commands["send"] = function(txt)
	local id, where = strsplit(" ", txt);
	where = where or "channel";

	if (id and #id > 0) then
		sendById(id, where);
	else
		playNext(where)
	end
end
commands["print"] = function(txt)
	txt = trim(txt);
	--print("---")
	--print(txt)
	--print("---")
	if (#txt > 0) then
		local id = txt;
		print(id, AddonNS.db.singles[id])
	else
		for i, v in pairs(AddonNS.db.singles) do
			print(i, v)
		end
	end
end
commands["help"] = function()
	print("MyTradeChatSpammer commands:");
	print("/mtcs help");
	print("/mtcs r <message>");
	print("/mtcs record <id> <message>");
	print("/mtcs delete <id>");
	print("/mtcs print [id]");
	print("/mtcs send [id] [chatType]");
	print("/mtcs toggle");
end
SlashCmdList[addonName .. "SlashCommand"] = function(msg)
	msg = trim(msg);
	if (#msg == 0) then
		commands["help"]();
		return;
	end

	local cmd, txt = msg:match("^(%S+)%s*(.-)$");
	cmd = string.lower(cmd or "");
	txt = txt or "";

	local handler = commands[cmd];
	if (not handler) then
		print("Unknown command:", cmd);
		commands["help"]();
		return;
	end
	handler(txt);
end
local spammingActive = false;
local function isOnTradeChat()
	return GetChannelName((GetChannelName("Trade - City"))) > 0
end

local msgCounter = 0;

local selfName = nil;

local function getSelfName()
	if (not selfName) then
		local unitName, server = UnitFullName("player")
		if (not server) then
			return "";
		end
		selfName = unitName .. "-" .. server;
	end
	return selfName;
end

local function CountMessages(eventName, text, playerName, languageName, channelName, playerName2, specialFlags,
							 zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile,
							 isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	msgCounter = msgCounter + ("Trade - City" == channelBaseName and playerName ~= getSelfName() and 1 or 0);
	--print( selfName,playerName, msgCounter);
end

local function ResetMessageCounter()
	--print("reseting counter")
	msgCounter = 0;
end

local lastSpamTime = 0;
local scheduleFrame = CreateFrame("Frame")
local sendCallback = nil;
local function sendMessage(...)
	if (sendCallback and (msgCounter >= minReqMessagesInBetween or time() - lastSpamTime > maxWaitSpamTime)) then
		--print ("wait time: ", time() - lastSpamTime);
		lastSpamTime = time();
		-- print("clicked")
		-- print(...)
		scheduleFrame:Hide()
		playNext("CHANNEL");
		-- sendMessage = function()
		-- end
		sendCallback()
		sendCallback = nil;
		ResetMessageCounter()
	elseif (msgCounter < minReqMessagesInBetween) then
		--print("Ignoring as counter is: ", msgCounter, " and timer is ", time() - lastSpamTime);
	else
		--print("clicked but not scheduled")
		-- print(...)
	end
end

scheduleFrame:EnableKeyboard(true)
scheduleFrame:SetPropagateKeyboardInput(true)
scheduleFrame:SetScript("OnKeyDown", sendMessage)
scheduleFrame:Hide()

local function scheduleNextMessage(callback)
	--print("scheduling next message")
	sendCallback = callback;

	scheduleFrame:Show()
end

local timer






local function enableSpamming()
	msgCounter = minReqMessagesInBetween; -- to allow first message to go through;
	AddonNS.events:RegisterEvent("CHAT_MSG_CHANNEL", CountMessages)
	--print("enabling spamming")
	spammingActive = true;
	local function spamLoop()
		--print("spamm loop")
		local callback = function()
			--print("callback triggered")

			if (spammingActive) then -- to prevent from reactivating the loop when dispatching a message			print("Looping yo!", GetTime())
				--print("scheduling timer")
				timer = C_Timer.NewTimer(minLoopTime, spamLoop);
			end
		end
		scheduleNextMessage(callback);
	end

	spamLoop()
end

local function disableSpamming()
	AddonNS.events:UnregisterEvent("CHAT_MSG_CHANNEL")
	--print("disabling spamming")
	spammingActive = false;
	if (timer) then
		timer:Cancel();
	end
	sendCallback = nil;
	scheduleFrame:Hide();
end

local function UpdateSpammer()
	--print("UpdateSpammer", AddonNS.db.spam, spammingActive, isOnTradeChat())
	if AddonNS.db.spam and not spammingActive and isOnTradeChat() then
		enableSpamming()
	elseif (spammingActive and (not AddonNS.db.spam or not isOnTradeChat())) then
		disableSpamming();
	end
end
function AddonNS.toggleSpamming()
	if (AddonNS.db.spam) then
		AddonNS.db.spam = false;
		print("disabling spamming");
	else
		AddonNS.db.spam = true;
		print("enabling spamming");
	end
	UpdateSpammer();
end

commands["toggle"] = function()
	AddonNS.toggleSpamming()
end

AddonNS.events:RegisterEvent("CHANNEL_UI_UPDATE", UpdateSpammer)
AddonNS.events:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateSpammer)
