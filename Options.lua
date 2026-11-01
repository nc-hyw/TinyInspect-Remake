
--------------
-- 配置面板 --
--------------

local LibEvent = LibStub:GetLibrary("LibEvent.7000")

local VERSION = 4.0

local addon, ns = ...

local L = ns.L

local DefaultDB = {
    version = VERSION,                    --配置的版本號
    ShowItemBorder = false,               --物品直角邊框 #暂停用#
    EnableItemLevel  = true,              --物品等級
      ShowColoredItemLevelString = false, --裝等文字隨物品品質
      ShowItemSlotString = true,          --物品部位文字
        EnableItemLevelBag = true,
        EnableItemLevelBank = true,
        EnableItemLevelMerchant = true,
        EnableItemLevelTrade = true,
        EnableItemLevelGuildBank = true,
        EnableItemLevelAuction = true,
        EnableItemLevelAltEquipment = true,
        EnableItemLevelPaperDoll = true,
        EnableItemLevelGuildNews = true,
        EnableItemLevelChat = false,
        EnableItemLevelLoot = true,
        EnableItemLevelOther = true,
    ShowInspectAngularBorder = false,     --觀察面板直角邊框
    ShowInspectClassBorder = true,        --装备列表职业边框染色
    ShowInspectColoredLabel = true,       --觀察面板高亮橙裝武器標簽
    ShowCharacterItemSheet = true,        --顯示玩家自己裝備列表
    ShowInspectItemSheet = true,          --顯示观察对象装备列表 --20190318Added
        ShowOwnFrameWhenInspecting = false,   --觀察同時顯示自己裝備列表
        ShowItemStats = false,                --顯示裝備屬性統計
        ShowUpgradeInfo = true,               --顯示升級路徑信息
        ShowInspectItemSetSummary = true,     --顯示套裝摘要
    EnablePartyItemLevel = true,          --小隊裝等
        SendPartyItemLevelToSelf = true,  --發送小隊裝等到自己面板
        SendPartyItemLevelToParty = false, --發送小隊裝等到隊伍頻道
        ShowPartySpecialization = true,   --顯示隊友天賦
    EnableRaidItemLevel = false,          --團隊裝等
    EnableMouseItemLevel = false,         --鼠標裝等
    EnableMouseSpecialization = true,     --鼠標天賦
    EnableMouseWeaponLevel = true,        --鼠標武器等級
    PaperDollItemLevelOutsideString = false, --PaperDoll文字外邊顯示(沒有在配置面板)
    ItemLevelAnchorPoint = "TOP",         --裝等位置
    ShowGearDurability = true,            --裝備耐久度顯示
    GearDurabilityAnchorPoint = "BOTTOM", --裝備耐久度位置
    ShowPluginGreenState = false,         --裝備綠字屬性前綴顯示
    ShowGemAndEnchant = true,             --显示宝石和附魔
    InspectNameFont = "default",          --觀察面板玩家名稱字體
    InspectItemFont = "default",          --觀察面板物品字體
    AnnouncementMode = "noticeAlways",    --公告顯示模式 noticeNever|noticeSnooze|noticeAlways
    AnnouncementLastSeen = "",            --最近一次已顯示的公告內容簽名
}

local GeneralGroupOptions = {
    { key = "EnablePartyItemLevel",
      child = {
        { key = "ShowPartySpecialization" },
        { key = "SendPartyItemLevelToSelf" },
        { key = "SendPartyItemLevelToParty" },
      }
    },
    { key = "EnableRaidItemLevel",
        checkedFunc = function() TinyInspectRaidFrame:Show() end,
        uncheckedFunc = function() TinyInspectRaidFrame:Hide() end,
    },
}

local GeneralMouseOptions = {
    { key = "EnableMouseItemLevel",
      child = {
        { key = "EnableMouseSpecialization" },
        { key = "EnableMouseWeaponLevel" },
      }
    },
}

local InspectEquipmentOptions = {
    { key = "ShowCharacterItemSheet" },
    { key = "ShowGemAndEnchant" },
    { key = "ShowInspectItemSheet",
      child = {
        { key = "ShowOwnFrameWhenInspecting" },
        { key = "ShowItemStats" },
        { key = "ShowUpgradeInfo" },
        { key = "ShowInspectItemSetSummary" },
      },
    },
}

local InspectAppearanceOptions = {
    { key = "ShowInspectAngularBorder" },
    { key = "ShowInspectClassBorder" },
    { key = "ShowInspectColoredLabel" },
}

if (GetLocale():sub(1,2) == "zh") then
    tinsert(InspectAppearanceOptions, { key = "ShowPluginGreenState" })
end

local ItemLevelOptions = {
    { key = "EnableItemLevel",
      child = {
        { key = "ShowColoredItemLevelString" },
        { key = "ShowItemSlotString" },
        { key = "EnableItemLevelOther", labelKey = "Other" },
        { key = "EnableItemLevelAltEquipment", labelKey = "AltEquipment" },
        { key = "EnableItemLevelGuildNews", labelKey = "GuildNews" },
        { key = "EnableItemLevelChat", labelKey = "Chat" },
        { key = "EnableItemLevelPaperDoll", labelKey = "PaperDoll" },
      },
    },
}

local DurabilityOptions = {
    { key = "ShowGearDurability",
      checkedFunc = function() LibEvent:trigger("GEAR_DURABILITY_DISPLAY_CHANGED") end,
      uncheckedFunc = function() LibEvent:trigger("GEAR_DURABILITY_DISPLAY_CHANGED") end,
    },
}

TinyInspectRemakeDB = DefaultDB

local function CallCustomFunc(self)
    local checked = self:GetChecked()
    if (self.anchorPopupButton) then
        self.anchorPopupButton:SetEnabled(checked)
        if (not checked and self.anchorPopup) then
            self.anchorPopup:Hide()
        end
    end
    if (checked and self.checkedFunc) then
        self.checkedFunc(self)
    end
    if (not checked and self.uncheckedFunc) then
        self.uncheckedFunc(self)
    end
end

local function StatusSubCheckbox(self, status)
    local checkbox
    for i = 1, self:GetNumChildren() do
        checkbox = select(i, self:GetChildren())
        if (checkbox.key) then
            checkbox:SetEnabled(status)
            StatusSubCheckbox(checkbox, status)
        end
    end
end

local function OnClickCheckbox(self)
    local status = self:GetChecked()
    TinyInspectRemakeDB[self.key] = status
    StatusSubCheckbox(self, status)
    CallCustomFunc(self)
end

local AnchorFrames = {}
local AnchorPoints = {
    "TOPLEFT", "LEFT", "BOTTOMLEFT",
    "TOP", "BOTTOM",
    "TOPRIGHT", "RIGHT", "BOTTOMRIGHT",
    "CENTER",
}

local function UpdateAnchorFrame(frame)
    if (not frame or not frame.anchorkey) then return end
    local anchorPoint = TinyInspectRemakeDB and TinyInspectRemakeDB[frame.anchorkey]
    for _, point in ipairs(AnchorPoints) do
        if (frame[point]) then
            frame[point]:GetNormalTexture():SetVertexColor(1, 1, 1)
        end
    end
    if (anchorPoint and frame[anchorPoint]) then
        frame[anchorPoint]:GetNormalTexture():SetVertexColor(1, 0.2, 0.1)
    end
end

local function CreateAnchorFrame(anchorInfo, parent)
    if (not anchorInfo) then return end
    if (type(anchorInfo) ~= "table") then
        anchorInfo = { key = anchorInfo }
    end
    local anchorkey = anchorInfo.key
    if (not anchorkey) then return end
    local CreateAnchorButton = function(frame, anchorPoint)
        local button = CreateFrame("Button", nil, frame)
        button.anchorPoint = anchorPoint
        button:SetSize(12, 12)
        button:SetPoint(anchorPoint)
        button:SetNormalTexture("Interface\\Buttons\\WHITE8X8")
        button:SetScript("OnClick", function(self)
            local parent = self:GetParent()
            local anchorPoint = self.anchorPoint
            TinyInspectRemakeDB[parent.anchorkey] = anchorPoint
            UpdateAnchorFrame(parent)
            LibEvent:trigger("ANCHOR_POINT_CHANGED", parent.anchorkey, anchorPoint)
        end)
        frame[anchorPoint] = button
    end
    local frame = CreateFrame("Frame", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or "ThinBorderTemplate")
    frame.anchorkey = anchorkey
    frame:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true, tileSize = 8, edgeSize = 16,
            insets   = {left = 4, right = 4, top = 4, bottom = 4}
    })
    frame:SetBackdropColor(0, 0, 0, 0.7)
    frame:SetBackdropBorderColor(1, 1, 1, 0)
    frame:SetSize(80, 80)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", anchorInfo.xpos or 530, anchorInfo.ypos or 44)
    frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    frame.title:SetPoint("BOTTOM", frame, "TOP", 0, 3)
    frame.title:SetWidth(anchorInfo.labelWidth or 100)
    frame.title:SetText(L[anchorInfo.labelKey or anchorkey])
    for _, point in ipairs(AnchorPoints) do
        CreateAnchorButton(frame, point)
    end
    UpdateAnchorFrame(frame)
    tinsert(AnchorFrames, frame)
    return frame
end

local function CreateAnchorPopupButton(checkbox, anchorInfo)
    if (not checkbox or not checkbox.Text) then return end

    local button = CreateFrame("Button", nil, checkbox:GetParent(), "UIPanelButtonTemplate")
    button:SetText(L[anchorInfo.buttonLabelKey or anchorInfo.labelKey or anchorInfo.key])
    local buttonText = button:GetFontString()
    local buttonWidth = buttonText and ceil(buttonText:GetStringWidth()) + 24 or 100
    button:SetSize(max(80, buttonWidth), 24)
    button:SetFrameLevel(checkbox:GetFrameLevel() + 2)

    local checkboxTextWidth = ceil(checkbox.Text:GetStringWidth())
    button:SetPoint("LEFT", checkbox.Text, "LEFT", checkboxTextWidth + 6, 0)

    local popup = CreateAnchorFrame(anchorInfo, UIParent)
    popup.title:Hide()
    popup:ClearAllPoints()
    popup:SetPoint("TOP", button, "BOTTOM", 0, -10)
    popup:SetFrameStrata("DIALOG")
    popup:SetClampedToScreen(true)
    popup:Hide()

    local closeButton = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeButton:SetPoint("TOP", popup, "BOTTOM", 0, -4)
    closeButton:SetScript("OnClick", function()
        popup:Hide()
    end)

    checkbox.anchorPopupButton = button
    checkbox.anchorPopup = popup
    button:SetEnabled(TinyInspectRemakeDB and TinyInspectRemakeDB[checkbox.key] ~= false)

    button:SetScript("OnClick", function()
        if (popup:IsShown()) then
            popup:Hide()
        else
            UpdateAnchorFrame(popup)
            popup:Show()
        end
    end)

    return popup
end

local function CreateCheckbox(list, parent, anchor, offsetx, offsety)
    local checkbox
    if (not list) then return offsety end
    for _, v in ipairs(list) do
        checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        checkbox.key = v.key
        checkbox.checkedFunc = v.checkedFunc
        checkbox.uncheckedFunc = v.uncheckedFunc
        local textWidth = max(220, 420 - offsetx)
        checkbox:SetSize(26, 26)
        checkbox.Text:ClearAllPoints()
        checkbox.Text:SetPoint("TOPLEFT", checkbox, "TOPLEFT", 28, -4)
        checkbox.Text:SetWidth(textWidth)
        checkbox.Text:SetJustifyH("LEFT")
        checkbox.Text:SetJustifyV("TOP")
        checkbox.Text:SetWordWrap(true)
        checkbox.Text:SetText(L[v.labelKey or v.key])
        checkbox:SetScript("OnClick", OnClickCheckbox)
        checkbox:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", offsetx, -6-offsety)
        local rowHeight = max(26, ceil(checkbox.Text:GetStringHeight()) + 8)
        checkbox:SetHitRectInsets(0, -(textWidth + 4), 0, -max(0, rowHeight - 26))
        offsety = offsety + rowHeight
        offsety = CreateCheckbox(v.child, checkbox, anchor, offsetx, offsety)
    end
    return offsety
end

local function InitCheckbox(parent)
    local checkbox
    for i = 1, parent:GetNumChildren() do
        checkbox = select(i, parent:GetChildren())
        if (checkbox.key) then
            checkbox:SetChecked(TinyInspectRemakeDB[checkbox.key])
            StatusSubCheckbox(checkbox, checkbox:GetChecked())
            CallCustomFunc(checkbox)
            InitCheckbox(checkbox)
        end
    end
end

local BuiltInFontChoices = {
    { value = "default",       labelKey = "DefaultFont" },
    { value = "ChatFontNormal", labelKey = "ChatFont" },
    { value = "GameFontNormal", labelKey = "GameFont" },
    { value = "QuestFont",      labelKey = "QuestFont" },
    { value = "CombatLogFont",  labelKey = "CombatLogFont" },
}

local AnnouncementChoices = {
    { value = "noticeAlways", labelKey = "AlwaysShowAnnouncements" },
    { value = "noticeSnooze", labelKey = "ShowOncePerAnnouncement" },
    { value = "noticeNever",  labelKey = "NeverShowAnnouncements" },
}

local function GetFontChoices()
    local choices, known = {}, {}
    for _, choice in ipairs(BuiltInFontChoices) do
        choices[#choices + 1] = {
            value = choice.value,
            text = L[choice.labelKey],
        }
        known[choice.value] = true
    end

    local LibMedia = LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if (LibMedia) then
        for _, fontName in ipairs(LibMedia:List("font")) do
            if (not known[fontName]) then
                choices[#choices + 1] = { value = fontName, text = fontName }
                known[fontName] = true
            end
        end
    end
    return choices
end

local function GetFontFile(font)
    local fontObject = _G[font]
    if (fontObject and fontObject.GetFont) then
        return fontObject:GetFont()
    end

    local LibMedia = LibStub:GetLibrary("LibSharedMedia-3.0", true)
    if (LibMedia and LibMedia:IsValid("font", font)) then
        return LibMedia:Fetch("font", font)
    end
end

local function IsFontChoiceValid(font)
    if (font == "default") then
        return true
    end
    local fontFile = GetFontFile(font)
    if (not fontFile) then
        return false
    end
    return C_UIFileAsset.IsKnownFile(fontFile)
end

local INVALID_FONT_POPUP = "TINYINSPECT_REMAKE_INVALID_FONT"
StaticPopupDialogs[INVALID_FONT_POPUP] = {
    text = L.InvalidFontMessage,
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function ShowInvalidFontPopup(font)
    StaticPopup_Show(INVALID_FONT_POPUP, font)
end

local function GetAnnouncementChoices()
    local choices = {}
    for _, choice in ipairs(AnnouncementChoices) do
        choices[#choices + 1] = {
            value = choice.value,
            text = L[choice.labelKey],
        }
    end
    return choices
end

local function CreateDropdown(parent, labelKey, dbKey, choicesProvider, x, y, onChanged, validator)
    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    label:SetWidth(520)
    label:SetJustifyH("LEFT")
    label:SetWordWrap(true)
    label:SetText(L[labelKey])
    local labelHeight = max(16, ceil(label:GetStringHeight()))
    label:SetHeight(labelHeight)

    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -6)
    dropdown:SetWidth(300)
    dropdown:SetDefaultText(L.SelectOption)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, choice in ipairs(choicesProvider()) do
            rootDescription:CreateRadio(choice.text,
                function(value)
                    return TinyInspectRemakeDB and TinyInspectRemakeDB[dbKey] == value
                end,
                function(value)
                    if (validator and not validator(value)) then
                        ShowInvalidFontPopup(value)
                        C_Timer.After(0, function()
                            dropdown:GenerateMenu()
                        end)
                        return
                    end
                    TinyInspectRemakeDB[dbKey] = value
                    if (onChanged) then
                        onChanged(dbKey, value)
                    end
                end,
                choice.value)
        end
    end)
    return dropdown, y - labelHeight - 48
end

local displayName = "TinyInspect-Remake"

local PageContents = {}

local function CreateScrollablePage(pageTitle)
    local page = CreateFrame("Frame", nil, UIParent)
    local scrollFrame = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -28, 4)
    scrollFrame.ScrollBar:Hide()
    scrollFrame:HookScript("OnScrollRangeChanged", function(self, _, verticalRange)
        self.ScrollBar:SetShown(floor(verticalRange) ~= 0)
    end)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local value = self:GetVerticalScroll() - delta * 40
        self:SetVerticalScroll(max(0, min(value, self:GetVerticalScrollRange())))
    end)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(700, 1)
    content:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", 0, 0)
    scrollFrame:SetScrollChild(content)
    page:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(max(700, width - 32))
    end)

    content.title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    content.title:SetPoint("TOPLEFT", content, "TOPLEFT", 18, -16)
    content.title:SetText(format("%s - %s", displayName, pageTitle))
    content.cursorY = -52
    page.content = content
    page.scrollFrame = scrollFrame
    tinsert(PageContents, content)
    return page
end

local function CreateSectionTitle(content, titleKey)
    local title = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", content, "TOPLEFT", 18, content.cursorY)
    title:SetWidth(620)
    title:SetJustifyH("LEFT")
    title:SetWordWrap(true)
    title:SetText(L[titleKey])
    local titleHeight = max(18, ceil(title:GetStringHeight()))
    title:SetHeight(titleHeight)
    return title, titleHeight
end

local function AddCheckboxSection(page, titleKey, list)
    local content = page.content
    local sectionY = content.cursorY
    local title, titleHeight = CreateSectionTitle(content, titleKey)
    local checkboxHeight = CreateCheckbox(list, content, title, 18, 9)
    content.cursorY = sectionY - titleHeight - 6 - checkboxHeight - 18
end

local function AddDropdownSection(page, titleKey, dropdowns)
    local content = page.content
    local sectionY = content.cursorY
    local _, titleHeight = CreateSectionTitle(content, titleKey)
    local cursorY = sectionY - titleHeight - 12
    for _, dropdownInfo in ipairs(dropdowns) do
        cursorY = select(2, CreateDropdown(content, dropdownInfo.labelKey, dropdownInfo.dbKey,
            dropdownInfo.choicesProvider, 18, cursorY, dropdownInfo.onChanged, dropdownInfo.validator))
    end
    content.cursorY = cursorY - 18
end

local function AddPopupAnchorCheckboxSection(page, titleKey, list, anchorInfo)
    local content = page.content
    local sectionY = content.cursorY
    local title, titleHeight = CreateSectionTitle(content, titleKey)
    local checkboxHeight = CreateCheckbox(list, content, title, 18, 9)
    local checkboxKey = anchorInfo.checkboxKey or (list[1] and list[1].key)
    local checkbox
    for i = 1, content:GetNumChildren() do
        local child = select(i, content:GetChildren())
        if (child.key == checkboxKey) then
            checkbox = child
            break
        end
    end
    local popup = CreateAnchorPopupButton(checkbox, anchorInfo)
    content.cursorY = sectionY - titleHeight - 6 - checkboxHeight - 18
    return popup
end

local function FinalizePage(page)
    page.content:SetHeight(max(560, -page.content.cursorY + 24))
end

local function OnInspectFontChanged(key, value)
    LibEvent:trigger("INSPECT_FONT_CHANGED", key, value)
end

local generalPage = CreateScrollablePage(L.General)
generalPage.name = displayName
AddCheckboxSection(generalPage, "PartyAndRaid", GeneralGroupOptions)
AddCheckboxSection(generalPage, "MouseFunctions", GeneralMouseOptions)
AddDropdownSection(generalPage, "Fonts", {
    { labelKey = "InspectNameFont", dbKey = "InspectNameFont", choicesProvider = GetFontChoices, onChanged = OnInspectFontChanged, validator = IsFontChoiceValid },
    { labelKey = "InspectItemFont", dbKey = "InspectItemFont", choicesProvider = GetFontChoices, onChanged = OnInspectFontChanged, validator = IsFontChoiceValid },
})
AddDropdownSection(generalPage, "Announcements", {
    { labelKey = "AnnouncementMode", dbKey = "AnnouncementMode", choicesProvider = GetAnnouncementChoices },
})
FinalizePage(generalPage)

local inspectPage = CreateScrollablePage(L.InspectPanel)
inspectPage.name = L.InspectPanel
inspectPage.parent = displayName
AddCheckboxSection(inspectPage, "EquipmentInformation", InspectEquipmentOptions)
AddCheckboxSection(inspectPage, "Appearance", InspectAppearanceOptions)
FinalizePage(inspectPage)

local itemLevelPage = CreateScrollablePage(L.ItemLevel)
itemLevelPage.name = L.ItemLevel
itemLevelPage.parent = displayName
local itemLevelAnchorPopup = AddPopupAnchorCheckboxSection(itemLevelPage, "ItemLevel", ItemLevelOptions, {
    key = "ItemLevelAnchorPoint",
    checkboxKey = "EnableItemLevel",
    buttonLabelKey = "AnchorPicker",
})
local durabilityAnchorPopup = AddPopupAnchorCheckboxSection(itemLevelPage, "Durability", DurabilityOptions, {
    key = "GearDurabilityAnchorPoint",
    checkboxKey = "ShowGearDurability",
    buttonLabelKey = "AnchorPicker",
})
itemLevelPage:HookScript("OnHide", function()
    if (itemLevelAnchorPopup) then
        itemLevelAnchorPopup:Hide()
    end
    if (durabilityAnchorPopup) then
        durabilityAnchorPopup:Hide()
    end
end)
FinalizePage(itemLevelPage)

LibEvent:attachEvent("VARIABLES_LOADED", function()
    if (not TinyInspectRemakeDB or not TinyInspectRemakeDB.version) then
        TinyInspectRemakeDB = DefaultDB
    elseif (TinyInspectRemakeDB.version <= DefaultDB.version) then
        TinyInspectRemakeDB.version = DefaultDB.version
        for k, v in pairs(DefaultDB) do
            if (TinyInspectRemakeDB[k] == nil) then
                TinyInspectRemakeDB[k] = v
            end
        end
    end
    TinyInspectRemakeDB.ShowCorruptedMark = nil
    TinyInspectRemakeDB.EnchantParts = nil
    for _, pageContent in ipairs(PageContents) do
        InitCheckbox(pageContent)
    end
    for _, anchorFrame in ipairs(AnchorFrames) do
        UpdateAnchorFrame(anchorFrame)
    end
end)

LibEvent:attachEvent("PLAYER_LOGIN", function()
    if (not TinyInspectRemakeDB) then return end

    local announcementKey = L.AnnouncementKey
    local announcementTitle = L.AnnouncementTitle
    local announcementChat = L.AnnouncementChat
    local mode = TinyInspectRemakeDB.AnnouncementMode or "noticeAlways"

    if (mode == "noticeNever" or announcementKey == "") then
        return
    end
    if (mode == "noticeSnooze" and TinyInspectRemakeDB.AnnouncementLastSeen == announcementKey) then
        return
    end

    local function AddChatMessage(message)
        if (message == "") then return end
        if (DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.AddMessage) then
            DEFAULT_CHAT_FRAME:AddMessage(message)
        else
            print(message)
        end
    end

    AddChatMessage(("|cff33eeff[TinyInspect-Remake]|r %s"):format(announcementTitle))
    AddChatMessage(announcementChat)
    TinyInspectRemakeDB.AnnouncementLastSeen = announcementKey
end)

if InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(generalPage)
    InterfaceOptions_AddCategory(inspectPage)
    InterfaceOptions_AddCategory(itemLevelPage)
elseif Settings then
    local category = Settings.RegisterCanvasLayoutCategory(generalPage, displayName)
    generalPage.category = category
    Settings.RegisterAddOnCategory(category)

    inspectPage.category = Settings.RegisterCanvasLayoutSubcategory(category, inspectPage, inspectPage.name)
    Settings.RegisterAddOnCategory(inspectPage.category)
    itemLevelPage.category = Settings.RegisterCanvasLayoutSubcategory(category, itemLevelPage, itemLevelPage.name)
    Settings.RegisterAddOnCategory(itemLevelPage.category)
end

SLASH_TinyInspect1 = "/tinyinspect"
SLASH_TinyInspect2 = "/ti"
function SlashCmdList.TinyInspect(msg, editbox)
    if (msg == "raid") then
        return ToggleFrame(TinyInspectRaidFrame)
    end
    if InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(generalPage)
    elseif Settings then
        Settings.OpenToCategory(generalPage.category.ID)
    end
end
