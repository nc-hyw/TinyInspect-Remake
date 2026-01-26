
-------------------------------------
-- 鼠标装等和天赋 Author: M
-------------------------------------

local LibEvent = LibStub:GetLibrary("LibEvent.7000")

local function FindLine(tooltip, keyword)
    local line, text
    for i = 2, tooltip:NumLines() do
        line = _G[tooltip:GetName() .. "TextLeft" .. i]
        text = line:GetText() or ""
        if (string.find(text, keyword)) then
            return line, i, _G[tooltip:GetName() .. "TextRight" .. i]
        end
    end
end

local LevelLabel = STAT_AVERAGE_ITEM_LEVEL .. ": "
local SpecLabel = SPECIALIZATION .. ": "

local function SafeUnitIsPlayer(unit)
    if (not unit) then return false end
    local ok, value = pcall(UnitIsPlayer, unit)
    if (ok) then return value end
    return false
end

local function SafeUnitIsUnit(a, b)
    if (not a or not b) then return false end
    local ok, value = pcall(UnitIsUnit, a, b)
    if (ok) then return value end
    return true
end

local function SafeCanInspect(unit)
    if (not unit) then return false end
    local ok, value = pcall(CanInspect, unit)
    if (ok) then return value end
    return true
end

local function SafeUnitIsVisible(unit)
    if (not unit) then return false end
    local ok, value = pcall(UnitIsVisible, unit)
    if (ok) then return value end
    return true
end

local function AppendToGameTooltip(guid, ilevel, spec, weaponLevel, isArtifact)
    spec = spec or ""
    if (TinyInspectRemakeDB and not TinyInspectRemakeDB.EnableMouseSpecialization) then spec = "" end
    local _, unit = GameTooltip:GetUnit()
    if (not unit) then return end
    local ilvlLine, _, lineRight = FindLine(GameTooltip, LevelLabel)
    local ilvlText = format("%s|cffffffff%s|r", LevelLabel, ilevel)
    local specText = format("|cffb8b8b8%s|r", spec)
    if (weaponLevel and weaponLevel > 0 and TinyInspectRemakeDB.EnableMouseWeaponLevel) then
        ilvlText = ilvlText .. format(" (%s)", weaponLevel)
    end
    if (ilvlLine) then
        ilvlLine:SetText(ilvlText)
        lineRight:SetText(specText)
    else
        GameTooltip:AddDoubleLine(ilvlText, specText)
    end
    GameTooltip:Show()
end

--觸發觀察
if (GameTooltip.ProcessInfo) then
    hooksecurefunc(GameTooltip, "ProcessInfo", function(self, info)
        if (not info or not info.tooltipData) then return end
        local flag = info.tooltipData.type
        if (flag ~= 2) then return end

        if (TinyInspectRemakeDB and (TinyInspectRemakeDB.EnableMouseItemLevel or TinyInspectRemakeDB.EnableMouseSpecialization)) then
            local _, unit = self:GetUnit()
            if (not unit) then return end
            if (not SafeUnitIsPlayer(unit)) then return end
            local data = GetInspectInfo(unit, 3)
            if (data and data.ilevel > 0 and SafeUnitIsUnit(data.unit, unit)) then
                return AppendToGameTooltip(nil, floor(data.ilevel), data.spec, data.weaponLevel, data.isArtifact)
            end
            if (not SafeCanInspect(unit) or not SafeUnitIsVisible(unit)) then return end
            local inspecting = GetInspecting()
            if (inspecting) then
                if (inspecting.unit and not SafeUnitIsUnit(inspecting.unit, unit)) then
                    return AppendToGameTooltip(nil, "n/a")
                else
                    return AppendToGameTooltip(nil, "......")
                end
            end
            ClearInspectPlayer()
            NotifyInspect(unit)
            AppendToGameTooltip(nil, "...")
        end
    end)
end

--@see InspectCore.lua
LibEvent:attachTrigger("UNIT_INSPECT_READY", function(self, data)
    if (TinyInspectRemakeDB and not TinyInspectRemakeDB.EnableMouseItemLevel) then return end
    if (data.guid == UnitGUID("mouseover")) then
        AppendToGameTooltip(data.guid, floor(data.ilevel), data.spec, data.weaponLevel, data.isArtifact)
    end
end)
