
-------------------------------------
-- 查看装备等级 Author: M
-------------------------------------

local LibEvent = LibStub:GetLibrary("LibEvent.7000")
local LibItemInfo = LibStub:GetLibrary("LibItemInfo.7000")
local GetItemUpgradeInfoAPI = C_Item.GetItemUpgradeInfo
local GetItemInfoAPI = C_Item.GetItemInfo
local GetItemSetInfoAPI = C_Item.GetItemSetInfo
local GetLootJournalItemSetItemsAPI = C_LootJournal.GetItemSetItems

local DEFAULT_NAME_FONT_FILE, DEFAULT_NAME_FONT_SIZE, DEFAULT_NAME_FONT_FLAGS = GameFontNormalLargeOutline:GetFont()
local DEFAULT_ITEM_FONT_FILE, DEFAULT_ITEM_FONT_SIZE, DEFAULT_ITEM_FONT_FLAGS = ChatFontNormal:GetFont()
local InspectFrames = setmetatable({}, { __mode = "k" })

local function GetConfiguredFontFile(dbKey, defaultFontFile)
    local font = TinyInspectRemakeDB and TinyInspectRemakeDB[dbKey]
    if (not font or font == "default") then
        return defaultFontFile
    end

    local fontFile
    local fontObject = _G[font]
    if (fontObject and fontObject.GetFont) then
        fontFile = fontObject:GetFont()
    end

    if (not fontFile) then
        local LibMedia = LibStub:GetLibrary("LibSharedMedia-3.0", true)
        if (LibMedia and LibMedia:IsValid("font", font)) then
            fontFile = LibMedia:Fetch("font", font)
        end
    end
    if (not fontFile) then
        return defaultFontFile
    end
    if (not C_UIFileAsset.IsKnownFile(fontFile)) then
        return defaultFontFile
    end
    return fontFile
end

local function ApplyInspectFonts(frame)
    if (not frame) then return end
    local nameFontFile = GetConfiguredFontFile("InspectNameFont", DEFAULT_NAME_FONT_FILE)
    local itemFontFile = GetConfiguredFontFile("InspectItemFont", DEFAULT_ITEM_FONT_FILE)

    if (frame.title) then
        frame.title:SetFont(nameFontFile, DEFAULT_NAME_FONT_SIZE, DEFAULT_NAME_FONT_FLAGS)
    end
    if (frame.setSummary) then
        frame.setSummary:SetFont(itemFontFile, 14, "THINOUTLINE")
    end

    local i = 1
    while (frame["item"..i]) do
        local itemframe = frame["item"..i]
        itemframe.levelString:SetFont(itemFontFile, DEFAULT_ITEM_FONT_SIZE, DEFAULT_ITEM_FONT_FLAGS)
        itemframe.itemString:SetFont(itemFontFile, DEFAULT_ITEM_FONT_SIZE, DEFAULT_ITEM_FONT_FLAGS)
        i = i + 1
    end
end

--bliz func
--裝備清單
local slots_retail = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },

}

local slots_wotlk = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },
    { index = 18, name = RANGEDSLOT, },
    { index = 4, name = SHIRTSLOT, },
    { index = 19, name = TABARDSLOT, },
}

local slots_classic = {
    { index = 1, name = HEADSLOT, },
    { index = 2, name = NECKSLOT, },
    { index = 3, name = SHOULDERSLOT, },
    { index = 5, name = CHESTSLOT, },
    { index = 6, name = WAISTSLOT, },
    { index = 7, name = LEGSSLOT, },
    { index = 8, name = FEETSLOT, },
    { index = 9, name = WRISTSLOT, },
    { index = 10, name = HANDSSLOT, },
    { index = 11, name = FINGER0SLOT, },
    { index = 12, name = FINGER1SLOT, },
    { index = 13, name = TRINKET0SLOT, },
    { index = 14, name = TRINKET1SLOT, },
    { index = 15, name = BACKSLOT, },
    { index = 16, name = MAINHANDSLOT, },
    { index = 17, name = SECONDARYHANDSLOT, },
    { index = 18, name = RANGEDSLOT, },
}

local slots = slots_retail
if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
    slots = slots_wotlk
elseif WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    slots = slots_classic
end

local UPGRADE_TEXT_COLOR = "ffffd200"

local function ColorizeUpgradeText(text)
    if (not text) then
        return ""
    end

    return format("|c%s%s|r", UPGRADE_TEXT_COLOR, text)
end

local function FormatInspectItemText(link, name)
    if (not link or not TinyInspectRemakeDB or not TinyInspectRemakeDB.ShowUpgradeInfo) then
        return link or name or ""
    end

    local info = GetItemUpgradeInfoAPI(link)
    if (not info or not info.trackString) then
        return link
    end

    if (info.currentLevel ~= nil and info.maxLevel ~= nil) then
        return format("%s %s", ColorizeUpgradeText(format("[%s %d/%d]", info.trackString, info.currentLevel, info.maxLevel)), link)
    end

    return format("%s %s", ColorizeUpgradeText(format("[%s]", info.trackString)), link)
end

local function FormatAverageItemLevel(ilevel)
    if (not ilevel) then
        return ""
    end
    if (ilevel == floor(ilevel)) then
        return format("%d", ilevel)
    end
    return format("%.1f", ilevel)
end

local function SafeGetItemSetID(link)
    if (not link) then return end
    local info = { pcall(GetItemInfoAPI, link) }
    local setID = info[17]
    if (info[1] and type(setID) == "number" and setID > 0) then
        return setID
    end
end

local function SafeGetItemSetName(setID)
    if (not setID) then return end
    local ok, name = pcall(GetItemSetInfoAPI, setID)
    if (ok and type(name) == "string" and name ~= "") then
        return name
    end
end

local function GetItemSetMaxPieces(setID, equippedCount)
    local maxPieces = equippedCount or 0
    if (not setID) then
        return maxPieces
    end

    local ok, items = pcall(GetLootJournalItemSetItemsAPI, setID)
    if (not ok or type(items) ~= "table") then
        return maxPieces
    end

    local invTypes, invTypeCount = {}, 0
    for _, item in ipairs(items) do
        local invType = item and item.invType
        if (invType and not invTypes[invType]) then
            invTypes[invType] = true
            invTypeCount = invTypeCount + 1
        end
    end

    return max(maxPieces, invTypeCount)
end

local function GetUnitItemSetSummary(unit)
    local sets = {}
    for _, slot in ipairs(slots) do
        local _, level, _, link = LibItemInfo:GetUnitItemInfo(unit, slot.index)
        if (link and level and level > 0) then
            local setID = SafeGetItemSetID(link)
            if (setID) then
                local setInfo = sets[setID]
                if (not setInfo) then
                    setInfo = { id = setID, count = 0 }
                    sets[setID] = setInfo
                end
                setInfo.count = setInfo.count + 1
            end
        end
    end

    local best
    for _, setInfo in pairs(sets) do
        if (not best or setInfo.count > best.count) then
            best = setInfo
        end
    end
    if (not best) then return end

    local name = SafeGetItemSetName(best.id)
    if (not name) then return end

    return name, best.count, GetItemSetMaxPieces(best.id, best.count)
end


--創建面板
local function GetInspectItemListFrame(parent)
    if (not parent.inspectFrame) then
        local itemfont = "ChatFontNormal"
        local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        local height = parent:GetHeight()
        if (height < 424) then
            height = 424
        end
        frame.backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 8,
            edgeSize = 16,
            insets   = {left = 4, right = 4, top = 4, bottom = 4}
        }
        frame:SetSize(160, height)
        frame:SetFrameLevel(0)
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
        frame:SetBackdrop(frame.backdrop)
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame:SetBackdropBorderColor(0.6, 0.6, 0.6)
        frame.portrait = CreateFrame("Frame", nil, frame, "GarrisonFollowerPortraitTemplate")
        frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
        frame.portrait:SetScale(0.8)
        frame.title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLargeOutline")
        frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -18)
        frame.setSummary = frame:CreateFontString(nil, "ARTWORK", itemfont)
        frame.setSummary:SetPoint("TOPLEFT", frame, "TOPLEFT", 66, -42)
        frame.setSummary:SetFont(frame.setSummary:GetFont(), 14, "THINOUTLINE")
        frame.setSummary:SetTextColor(1, 0.82, 0)

        local itemframe
        local fontsize = GetLocale():sub(1,2) == "zh" and 12 or 9
        local backdrop = {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile     = true,
            tileSize = 8,
            edgeSize = 1,
            insets   = {left = 1, right = 1, top = 1, bottom = 1}
        }
        for i, v in ipairs(slots) do
            itemframe = CreateFrame("Button", nil, frame, "BackdropTemplate")
            itemframe:SetSize(120, min((height-82)/#slots,28))
            itemframe.index = v.index
            itemframe.backdrop = backdrop
            if (i == 1) then
                itemframe:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -70)
            else
                itemframe:SetPoint("TOPLEFT", frame["item"..(i-1)], "BOTTOMLEFT")
            end
            itemframe.label = CreateFrame("Frame", nil, itemframe, "BackdropTemplate")
            itemframe.label:SetSize(38, 16)
            itemframe.label:SetPoint("LEFT")
            itemframe.label:SetBackdrop(backdrop)
            itemframe.label:SetBackdropBorderColor(0, 0.9, 0.9, 0.2)
            itemframe.label:SetBackdropColor(0, 0.9, 0.9, 0.2)
            itemframe.label.text = itemframe.label:CreateFontString(nil, "ARTWORK")
            itemframe.label.text:SetFont(UNIT_NAME_FONT, fontsize, "THINOUTLINE")
            itemframe.label.text:SetSize(34, 14)
            itemframe.label.text:SetPoint("CENTER", 1, 0)
            itemframe.label.text:SetText(v.name)
            itemframe.label.text:SetTextColor(0, 0.9, 0.9)
            itemframe.levelString = itemframe:CreateFontString(nil, "ARTWORK", itemfont)
            itemframe.levelString:SetPoint("LEFT", itemframe.label, "RIGHT", 4, 0)
            itemframe.levelString:SetJustifyH("LEFT")
            itemframe.levelString:SetText("000")
            itemframe.levelString:SetWidth(itemframe.levelString:GetStringWidth())
            itemframe.levelString:SetText("")
            itemframe.itemString = itemframe:CreateFontString(nil, "ARTWORK", itemfont)
            itemframe.itemString:SetHeight(16)
            itemframe.itemString:SetPoint("LEFT", itemframe.levelString, "RIGHT", 2, 0)
            itemframe:SetScript("OnEnter", function(self)
                local r, g, b, a = self.label:GetBackdropColor()
                if (a) then self.label:SetBackdropColor(r, g, b, a+0.5) end
                if (self.link or (self.level and self.level > 0)) then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetInventoryItem(self:GetParent().unit, self.index)
                    GameTooltip:Show()
                end
            end)
            itemframe:SetScript("OnLeave", function(self)
                local r, g, b, a = self.label:GetBackdropColor()
                if (a) then self.label:SetBackdropColor(r, g, b, abs(a-0.5)) end
                GameTooltip:Hide()
            end)
            itemframe:SetScript("OnDoubleClick", function(self)
                if (self.link) then
                    ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
                    ChatEdit_InsertLink(self.link)
                end
            end)
            frame["item"..i] = itemframe
            LibEvent:trigger("INSPECT_ITEMFRAME_CREATED", itemframe)
        end
        
        frame.closeButton = CreateFrame("Button", nil, frame)
        frame.closeButton:SetSize(12, 12)
        frame.closeButton:SetScale(0.85)
        frame.closeButton:SetPoint("BOTTOMLEFT", 5, 6)
        frame.closeButton:SetNormalTexture("Interface\\Cursor\\Item")
        frame.closeButton:GetNormalTexture():SetTexCoord(0, 12/32, 12/32, 0)
        frame.closeButton:SetScript("OnClick", function(self)
            self:GetParent():Hide()
        end)

        parent:HookScript("OnHide", function(self) frame:Hide() end)
        parent.inspectFrame = frame
        InspectFrames[frame] = true
        ApplyInspectFonts(frame)
        LibEvent:trigger("INSPECT_FRAME_CREATED", frame, parent)
    end

    return parent.inspectFrame
end

LibEvent:attachTrigger("INSPECT_FONT_CHANGED", function()
    for frame in pairs(InspectFrames) do
        ApplyInspectFonts(frame)
    end
end)

--顯示面板
function ShowInspectItemListFrame(unit, parent, ilevel, maxLevel)
    if (not parent:IsShown()) then return end
    local frame = GetInspectItemListFrame(parent)
    local class = select(2, UnitClass(unit))
    local color = RAID_CLASS_COLORS[class] or NORMAL_FONT_COLOR
    frame.unit = unit
    frame.portrait:SetLevel(UnitLevel(unit))
    frame.portrait.PortraitRingQuality:SetVertexColor(color.r, color.g, color.b)
    frame.portrait.LevelBorder:SetVertexColor(color.r, color.g, color.b)
    SetPortraitTexture(frame.portrait.Portrait, unit)
    frame.title:SetText(format("%s (%s) ", UnitName(unit), FormatAverageItemLevel(ilevel)))
    frame.title:SetTextColor(color.r, color.g, color.b)
    frame.setSummary:SetText("")
    frame.setSummary:Hide()
    local _, name, level, link, quality
    local itemframe, mframe, oframe, itemwidth
    local width = max(160, floor(frame.title:GetStringWidth()) + 70)
    local formats = "%3s"
    if (maxLevel) then
        formats = "%" .. string.len(floor(maxLevel)) .. "s"
    end
    for i, v in ipairs(slots) do
        _, level, name, link, quality = LibItemInfo:GetUnitItemInfo(unit, v.index)
        itemframe = frame["item"..i]
        itemframe.name = name
        itemframe.link = link
        itemframe.level = level
        itemframe.quality = quality
        itemframe.itemString:SetWidth(0)
        if (level > 0) then
            itemframe.levelString:SetText(format(formats,level))
            itemframe.itemString:SetText(FormatInspectItemText(link, name))
        else
            itemframe.levelString:SetText(format(formats,""))
            itemframe.itemString:SetText("")
        end
        itemframe.levelString:SetTextColor(1, 1, 1)
        itemwidth = itemframe.itemString:GetWidth()
        if (itemwidth > 260) then
            itemwidth = 260
            itemframe.itemString:SetWidth(itemwidth)
        end
        itemframe.width = itemwidth + max(64, floor(itemframe.label:GetWidth() + itemframe.levelString:GetWidth()) + 4)
        itemframe:SetWidth(itemframe.width)
        if (width < itemframe.width) then
            width = itemframe.width
        end
        if (v.index == 16) then
            mframe = itemframe
            mframe:SetAlpha(1)
        elseif (v.index == 17) then
            oframe = itemframe
            oframe:SetAlpha(1)
        end
        LibEvent:trigger("INSPECT_ITEMFRAME_UPDATED", itemframe)
    end
    if (TinyInspectRemakeDB and TinyInspectRemakeDB.ShowInspectItemSetSummary) then
        local setName, equippedCount, maxPieces = GetUnitItemSetSummary(unit)
        if (setName and equippedCount and maxPieces and maxPieces > 0) then
            frame.setSummary:SetText(format("%s (%d/%d)", setName, equippedCount, maxPieces))
            frame.setSummary:Show()
            width = max(width, floor(frame.setSummary:GetStringWidth()) + 70)
        end
    end
    if (mframe and oframe and (mframe.quality == 6 or oframe.quality == 6)) then
        level = max(mframe.level, oframe.level)
        if mframe.link then
            mframe.levelString:SetText(format(formats,level))
        end
        if oframe.link then
            oframe.levelString:SetText(format(formats,level))
        end
    end
    if (mframe and mframe.level <= 0) then
        mframe:SetAlpha(0.4)
    end
    if (oframe and oframe.level <= 0) then
        oframe.link = nil
        oframe:SetAlpha(0.4)
    end
    frame:SetWidth(width + 36)
    frame:Show()

    LibEvent:trigger("INSPECT_FRAME_SHOWN", frame, parent, ilevel)
    frame:SetBackdrop(frame.backdrop)
    frame:SetBackdropColor(0, 0, 0, 0.9)
    frame:SetBackdropBorderColor(color.r, color.g, color.b)

    return frame
end


--裝備變更時
LibEvent:attachEvent("UNIT_INVENTORY_CHANGED", function(self, unit)
    if (InspectFrame and InspectFrame.unit and InspectFrame.unit == unit) then
        ReInspect(unit)
    end
end)

--@see InspectCore.lua 
LibEvent:attachTrigger("UNIT_INSPECT_READY, UNIT_REINSPECT_READY", function(self, data)
    if (TinyInspectRemakeDB and not TinyInspectRemakeDB.ShowInspectItemSheet) then return end
    if (InspectFrame and InspectFrame.unit and UnitGUID(InspectFrame.unit) == data.guid) then
        local frame = ShowInspectItemListFrame(InspectFrame.unit, InspectFrame, data.ilevel, data.maxLevel)
        LibEvent:trigger("INSPECT_FRAME_COMPARE", frame)
    end
end)

--設置邊框
LibEvent:attachTrigger("INSPECT_FRAME_SHOWN", function(self, frame, parent, ilevel)
    local backdrop = frame:GetBackdrop() or {
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile     = true,
            tileSize = 8,
            edgeSize = 16,
            insets   = {left = 4, right = 4, top = 4, bottom = 4}
          }
    if (TinyInspectRemakeDB and TinyInspectRemakeDB.ShowInspectAngularBorder) then
        backdrop.edgeSize = 1
        backdrop.edgeFile = "Interface\\Buttons\\WHITE8X8"
        backdrop.insets.top = 1
        backdrop.insets.left = 1
        backdrop.insets.right = 1
        backdrop.insets.bottom = 1
        frame.backdrop = backdrop
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 2, 0)
    else
        backdrop.edgeSize = 16
        backdrop.edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
        backdrop.insets.top = 4
        backdrop.insets.left = 4
        backdrop.insets.right = 4
        backdrop.insets.bottom = 4
        frame.backdrop = backdrop
        frame:SetPoint("TOPLEFT", parent, "TOPRIGHT", 0, 0)
    end
end)

--高亮橙裝和武器
LibEvent:attachTrigger("INSPECT_ITEMFRAME_UPDATED", function(self, itemframe)
    local r, g, b = 0, 0.9, 0.9
    if (TinyInspectRemakeDB and TinyInspectRemakeDB.ShowInspectColoredLabel) then
        if (itemframe.quality and itemframe.quality > 4) then
            r, g, b = GetItemQualityColor(itemframe.quality)
        elseif (itemframe.name and not itemframe.link) then
            r, g, b = 0.9, 0.8, 0.4
        elseif (not itemframe.link) then
            r, g, b = 0.5, 0.5, 0.5
        end
    end
    itemframe.label:SetBackdropBorderColor(r, g, b, 0.2)
    itemframe.label:SetBackdropColor(r, g, b, 0.2)
    itemframe.label.text:SetTextColor(r, g, b)
end)

--自己裝備列表
LibEvent:attachTrigger("INSPECT_FRAME_COMPARE", function(self, frame)
    if (not frame) then return end
    if (TinyInspectRemakeDB and TinyInspectRemakeDB.ShowOwnFrameWhenInspecting) then
        local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
        local playerFrame = ShowInspectItemListFrame("player", frame, ilevel, maxLevel)
        if (frame.statsFrame) then
            frame.statsFrame:SetParent(playerFrame)
        end
    elseif (frame.statsFrame) then
        frame.statsFrame:SetParent(frame)
    end
    if (frame.statsFrame) then
        frame.statsFrame:SetPoint("TOPLEFT", frame.statsFrame:GetParent(), "TOPRIGHT", 1, -1)
    end
end)


----------------
--   Player   --
----------------

PaperDollFrame:HookScript("OnShow", function(self)
    if (TinyInspectRemakeDB and not TinyInspectRemakeDB.ShowCharacterItemSheet) then return end
    local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
    ShowInspectItemListFrame("player", self, ilevel, maxLevel)
end)

LibEvent:attachEvent("PLAYER_EQUIPMENT_CHANGED", function(self)
    if (CharacterFrame:IsShown() and TinyInspectRemakeDB and TinyInspectRemakeDB.ShowCharacterItemSheet) then
        local _, ilevel, _, _, _, maxLevel = LibItemInfo:GetUnitItemLevel("player")
        ShowInspectItemListFrame("player", PaperDollFrame, ilevel, maxLevel)
    end
end)
