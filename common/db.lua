local addonName, AddonNS = ...
AddonNS.db = {};
local function OnEvent()
	_G[addonName.."DB"] = _G[addonName.."DB"] or {};
	AddonNS.db = _G[addonName.."DB"];
	AddonNS.db.play = AddonNS.db.play or 1;
end
AddonNS.events:OnDbLoaded(OnEvent)