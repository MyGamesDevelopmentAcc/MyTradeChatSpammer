local addonName, AddonNS = ...

AddonNS.db.singles = {};
AddonNS.db.groups = {};
_G["SLASH_" .. addonName .. "SlashCommand1"] = "/mtcs"


-- [not yet implemented] /mtcs record MY_SUPER_ID1 WTS super cost thingy
-- [not yet implemented] /mtcs recordgroup MY_SUPERGROUP_ID1
-- [not yet implemented] /mtcs play MY_SUPER_ID1 say|trade
-- [not yet implemented] /mtcs play MY_SUPER_ID1
-- [not yet implemented] /mtcs playnext MY_SUPERGROUP_ID1 say|trade
-- [not yet implemented] /mtcs clear ID
-- [not yet implemented] /mtcs clearall
-- [not yet implemented] /mtcs print (optional)ID --if ID not provided, prints all recorded messages

local commands = {};

commands["record"] = function(txt)
	local id = txt:sub(1, txt:find(" ") - 1);
	txt = txt:sub(txt:find(" ") + 1);
	print(id)
	print(txt)
	AddonNS.db.singles[id] = txt;
end

local play = 1;
local spam = true;
local function playNext(where)
	local singlesPlaylist = {}
	for i, v in pairs(AddonNS.db.singles) do
		table.insert(singlesPlaylist, v);
	end
	if (#singlesPlaylist >0) then
		play = play > #singlesPlaylist and 1 or play;
		SendChatMessage(singlesPlaylist[play], where, nil, 2);
		play = play + 1;
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
	print(txt)
	if (txt:find(" ")) then
		local id = txt:sub(1, txt:find(" ") - 1);
		print(id, AddonNS.db.singles[id])
		ChatFrame1EditBox:SetText("/mtcs record " .. id .. " " .. AddonNS.db.singles[id])
	else
		for i, v in pairs(AddonNS.db.singles) do
			print(i, v)
		end
	end
end
SlashCmdList[addonName .. "SlashCommand"] = function(msg)
	print(msg)
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


local scheduleFrame = CreateFrame("Frame")
local sendCallback = nil;
local function sendMessage(...)
	if(sendCallback) then
		-- print("clicked")
		-- print(...)
		scheduleFrame:Hide()
		playNext("CHANNEL");
		sendMessage = function() end
		sendCallback()
		sendCallback=nil;
	else
		print("clicked but not scheduled")
		-- print(...)
	end
end

--scheduleFrame:SetFrameStrata("TOOLTIP")
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
	--print("enabling spamming")
	spammingActive = true;
	local function spamLoop()
		--print("spamm loop")
		local callback = function()
			--print("callback triggered")

			if (spammingActive) then -- to prevent from reactivating the loop when dispatching a message			print("Looping yo!", GetTime())
				
				--print("scheduling timer")
				timer = C_Timer.NewTimer(15, spamLoop);
			end
		end
		scheduleNextMessage(callback);
	end

	spamLoop()
end

local function disableSpamming()

	--print("disabling spamming")
	spammingActive = false;
	if (timer) then
		timer:Cancel();
	end
end

local function UpdateSpammer()
	print("UpdateSpammer", spam, spammingActive, isOnTradeChat())
	if spam and not spammingActive and isOnTradeChat() then
		enableSpamming()
	elseif (spammingActive and (not spam or not isOnTradeChat())) then
		disableSpamming();
	end
end

commands["spam"] = function(txt)
	if (spam) then
		spam = false;
		print("disabling spamming");
	else
		spam = true;
		print("enabling spamming");
	end
	UpdateSpammer();
end

AddonNS.events:RegisterEvent("CHANNEL_UI_UPDATE",UpdateSpammer) 
AddonNS.events:RegisterEvent("PLAYER_ENTERING_WORLD",UpdateSpammer)