local addonName, AddonNS = ...
AddonNS.events = {}
LibStub("AceEvent-3.0"):Embed(AddonNS.events);
local events = {};
local function addEvent(eventName, f)
    events[eventName] =  events[eventName] or {};
    events[eventName][f] = true;
end
local function removeEvent(eventName, f)
    events[eventName] =  events[eventName] or {};
    events[eventName][f] = nil;
end
local function getEvents(eventName)
    return events[eventName] or {};
end

local function OnEvent(self, event, ...)
    local functions = getEvents(event);
    for i,_ in pairs(functions) do
        i(...);
    end
end
local frame = CreateFrame("Frame")
frame:HookScript("OnEvent", OnEvent);
function AddonNS.events:RegisterEvent(eventName, f)
    if (not events[eventName]) then 
        frame:RegisterEvent(eventName)
    end
    addEvent(eventName, f or AddonNS.events[eventName])

end

function AddonNS.events:UnregisterEvent(eventName)
    removeEvent(eventName, f or AddonNS.events[eventName])
    if (events[eventName] and next(events[eventName]) == nil) then 
        frame:UnregisterEvent(eventName)
    end
end

function AddonNS.events:Register(eventName)
    frame:UnregisterEvent(eventName)
end

function AddonNS.events:OnDbLoaded(f)
    self:RegisterEvent("PLAYER_LOGIN",f)
end
function AddonNS.events:OnInitialize(f)
    self:OnDbLoaded(f);
end
