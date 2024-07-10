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
	AddonNS.db.spam =  AddonNS.db.spam or false;
end
LibStub("MyLibrary_DB").asyncLoad("MyTradeChatSpammerDB", AddonNS.init);
_G["SLASH_" .. addonName .. "SlashCommand1"] = "/mtcs"

-- CONFIG
local maxWaitSpamTime = 120; -- maximal to send regardless
local minLoopTime = 30; -- minmal can be set to 15 but it then spams a lot
local minReqMessagesInBetween = 3;

-- /mtcs r -- records with random id
-- [not yet implemented] /mtcs play MY_SUPER_ID1 say|trade
-- [not yet implemented] /mtcs play MY_SUPER_ID1
-- [not yet implemented] /mtcs playnext MY_SUPERGROUP_ID1 say|trade
-- [not yet implemented] /mtcs clear ID
-- [not yet implemented] /mtcs clearall
-- [not yet implemented] /mtcs print (optional)ID --if ID not provided, prints all recorded messages

-- /mtcs r -- records with random id
-- /mtcs record MY_SUPER_ID1 WTS super cost thingy
-- /mtcs spam -- enable and disable spmming
-- /mtcs delete ID -- removes given Id

local commands = {};
local function getRecordsAsList()
	local singlesPlaylist = {}
	for i, v in pairs(AddonNS.db.singles) do
		table.insert(singlesPlaylist, v);
	end
	return singlesPlaylist;
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
	record(nil, txt)
end

commands["delete"] = function(txt)
	delete(txt);
end

commands["record"] = function(txt)
	local id = txt:sub(1, txt:find(" ") - 1);
	txt = txt:sub(txt:find(" ") + 1);
	record(id, txt)
end

local function getRecordsAsList()
	local singlesPlaylist = {}
	for i, v in pairs(AddonNS.db.singles) do
		table.insert(singlesPlaylist, v);
	end
	return singlesPlaylist;
end

local function playNext(where)
	local singlesPlaylist = getRecordsAsList();
	if (#singlesPlaylist > 0) then
		AddonNS.db.play = AddonNS.db.play > #singlesPlaylist and 1 or AddonNS.db.play;
		SendChatMessage(singlesPlaylist[AddonNS.db.play], where, nil, 2);
		AddonNS.db.play = AddonNS.db.play + 1;
	end
end

commands["play"] = function(txt)
	local id, where = strsplit(" ", txt);
	where = where or "channel";

	if (id and #id > 0) then
		print(id, where)
		SendChatMessage(AddonNS.db.singles[id], where, nil, 2);
	else
		playNext(where)
	end
end
commands["print"] = function(txt)
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
SlashCmdList[addonName .. "SlashCommand"] = function(msg)
	--print(msg)
	local searchTill = msg:find(" ");
	searchTill = searchTill and (searchTill - 1);
	local cmd = msg:sub(1, searchTill);
	local txt = searchTill and msg:sub(msg:find(" ") + 1) or "";
	commands[cmd](txt);
end
local spammingActive = false;
local function isOnTradeChat()
	return GetChannelName((GetChannelName("Trade - City"))) > 0
end

local msgCounter = 0;

local unitName, server = UnitFullName("player")
local selfName = unitName.."-"..server;

local function CountMessages(eventName, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, languageID, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	msgCounter = msgCounter + ("Trade - City" == channelBaseName and playerName ~= selfName and 1 or 0);
	--print( selfName,playerName, msgCounter);
end

local function ResetMessageCounter()
	--print("reseting counter")
	msgCounter=0;
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
	elseif (msgCounter <minReqMessagesInBetween) then
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
	msgCounter=minReqMessagesInBetween; -- to allow first message to go through;
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

commands["spam"] = function()
	AddonNS.toggleSpamming()
end

AddonNS.events:RegisterEvent("CHANNEL_UI_UPDATE", UpdateSpammer)
AddonNS.events:RegisterEvent("PLAYER_ENTERING_WORLD", UpdateSpammer)

