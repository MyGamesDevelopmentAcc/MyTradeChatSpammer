local addonName, AddonNS = ...
local GS = LibStub("MyLibrary_GUI");

--- @type WowList
local WowList = LibStub("WowList-1.5");

AddonNS.gui = {};

local self = AddonNS.gui;

function MyTradeChatSpammer_MinimapOnClick()
    AddonNS.refreshList()
    AddonNS.updateSpamButtonText();
    self.mainFrame:Show();
end

function AddonNS.refreshList()
    local list = self.mainFrame.containerFrame.list;

    list:RemoveAll()

    for i, v in pairs(AddonNS.db.singles) do
        --print(i, v)
        list:AddData({ i, v });
    end
    list:UpdateView()
end

self.mainFrame = GS:CreateButtonFrame(addonName, 40 + 700 + 30, 400);


self.mainFrame.containerFrame = CreateFrame("Frame", addonName .. "-container", self.mainFrame)
local containerFrame = self.mainFrame.containerFrame;
containerFrame:SetPoint("TOPLEFT", 0, -22)
containerFrame:SetPoint("BOTTOMRIGHT")



local list
do
    containerFrame.list = WowList:CreateNew(addonName .. "_spamList",
        {
            columns = { {
                id = "id",
                name = "Id",
                width = 40,
                sortFunction = function(a, b)
                    return a < b
                end,
                displayFunction = function(cellData, rowData)
                    return cellData
                end,
            }, {
                id = "Message",
                name = "Message",
                width = 690,
                sortFunction = nil,
                displayFunction = nil,
                textureDisplayFunction = nil,
                cellOnEnterFunction = nil,
                cellOnLeaveFunction = nil,
            }, },
            rows = 10,
            height = 180
        }, containerFrame);

    list = containerFrame.list;
    list:SetPoint('TOPLEFT', containerFrame, 'TOPLEFT', 16, -70);
    list:SetMultiSelection(false);
end


--
-- [[ GUI - FILTER BOX ]]
local function createSearchBox(framepoint, frame, point, text, posX, posY, width, height)
    local f = frame;
    local fontString = GS.CreateFontString(f, nil, "ARTWORK", text, framepoint, f, point, posX, posY);
    fontString:SetTextColor(1, 1, 1, 1);
    local editBox = CreateFrame("EditBox", nil, f, "SearchBoxTemplate")
    editBox:SetPoint('TOPLEFT', fontString, 'TOPRIGHT', 5, 4)

    editBox:SetHeight(height);
    editBox:SetWidth(width);

    return editBox
end




-- [[ GUI - Main FILTER BOX ]]
do
    local f = containerFrame;

    local searchEditBox = createSearchBox("TOPLEFT", containerFrame, "TOPLEFT", "Filter: ", 16, -50, 300
    , 20);
    searchEditBox:HookScript("OnTextChanged", function(self)
        local txt = string.lower(searchEditBox:GetText());

        list:AddFilter("filterByEditBox", function(data)
            local id = data[1];
            local message = data[2];
            if (#txt == 0) then
                return true;
            end

            if (
                    string.find(string.lower(id), txt) or
                    string.find(string.lower(message), txt)) then
                return true;
            end
            return false;
            -- return genericFilter(data,txt);
        end);
        list:UpdateView();
    end)
    self.filterEditBox = searchEditBox;
end

-- [[ GUI - textScrollFrame]]
local function createEditBox(frame, posX, posY, height)
    local textScrollFrame = CreateFrame("ScrollFrame", nil, frame, "InputScrollFrameTemplate")

    textScrollFrame:SetHeight(height)
    textScrollFrame:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", posX, posY);
    textScrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -posX, posY);

    InputScrollFrame_OnLoad(textScrollFrame);
    textScrollFrame.EditBox:SetMaxLetters(255);
    textScrollFrame.EditBox:SetCountInvisibleLetters(false);
    -- textScrollFrame.EditBox:SetSpacing(5)
    textScrollFrame.EditBox:SetFontObject(NumberFont_Shadow_Tiny)
    --    textScrollFrame.EditBox:SetJustifyH("CENTER")
    --
    --





    return textScrollFrame
end
containerFrame.textScrollFrame = createEditBox(containerFrame, 25, 40, 60)

hooksecurefunc("SetItemRef", function(link, text, button)
    containerFrame.textScrollFrame.EditBox:Insert(text)
end)




-- id
do
    local fontString = GS.CreateFontString(containerFrame, nil, "ARTWORK", "Id: ", "BOTTOMLEFT", containerFrame,
        "BOTTOMLEFT", 25, 8);
    fontString:SetTextColor(1, 1, 1, 1);
    containerFrame.idBox = CreateFrame("EditBox", nil, containerFrame, "InputBoxInstructionsTemplate")
    local idBox = containerFrame.idBox
    idBox:SetPoint('TOPLEFT', fontString, 'TOPRIGHT', 5, 4)
    idBox:SetHeight(20);
    idBox:SetWidth(100);
    idBox:SetAutoFocus(false);
end

--- [[ save button]]
local saveButton = CreateFrame("Button", nil, containerFrame, "UIPanelButtonTemplate")
saveButton:SetPoint("TOPLEFT", containerFrame.idBox, "TOPRIGHT", 5, 0);

saveButton:SetSize(60, 20)
saveButton:SetText("Save")

saveButton:SetScript("OnClick", function(self, button)
    AddonNS.record(containerFrame.idBox:GetText(), containerFrame.textScrollFrame.EditBox:GetText());
    AddonNS.refreshList()
end)

--- [[ delete button]]
local deleteButton = CreateFrame("Button", nil, containerFrame, "UIPanelButtonTemplate")
deleteButton:SetPoint("TOPLEFT", saveButton, "TOPRIGHT", 5, 0);

deleteButton:SetSize(60, 20)
deleteButton:SetText("Delete")

deleteButton:SetScript("OnClick", function(self, button)
    AddonNS.delete(containerFrame.idBox:GetText());
    AddonNS.refreshList()
end)

--- [[ spam button]]
local spamButton = CreateFrame("Button", nil, containerFrame, "UIPanelButtonTemplate")
spamButton:SetPoint("TOPLEFT", deleteButton, "TOPRIGHT", 100, 0);

spamButton:SetSize(130, 20)
spamButton:SetText("Start spamming")
function AddonNS.updateSpamButtonText()
    spamButton:SetText(AddonNS.db.spam and "Stop spamming" or "Start spamming")
    print(AddonNS.db.spam and "Stop spamming" or "Start spamming", AddonNS.db.spam)
end

spamButton:SetScript("OnClick", function(self, button)
    AddonNS.toggleSpamming();
    AddonNS.updateSpamButtonText()
end)


list:SetButtonOnMouseDownFunction(function(rowData)
    --print("mouse down")

    containerFrame.textScrollFrame.EditBox:SetText(rowData[2])
    containerFrame.idBox:SetText(rowData[1]);

    --ChatFrame1EditBox:Show()
end)
