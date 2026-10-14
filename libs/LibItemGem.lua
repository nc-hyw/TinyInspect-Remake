
-------------------------------------
-- 物品寶石庫 Author: M
-------------------------------------

local MAJOR, MINOR = "LibItemGem.7000", 4
local lib = LibStub:NewLibrary(MAJOR, MINOR)

local GetItemGem = C_Item.GetItemGem
local GetItemGemID = C_Item and C_Item.GetItemGemID
local GetItemInfo = C_Item.GetItemInfo
local GetItemStats = C_Item.GetItemStats

if not lib then return end

local function GetEmbeddedGemID(itemLink, index)
    if (type(GetItemGemID) == "function") then
        local ok, gemID = pcall(GetItemGemID, itemLink, index)
        if (ok and type(gemID) == "number" and gemID > 0) then
            return gemID
        end
    end

    if (type(itemLink) ~= "string") then return end
    local gem1, gem2, gem3, gem4 = string.match(itemLink,
        "item:%d+:[^:]*:([^:]*):([^:]*):([^:]*):([^:]*)")
    local gemID = tonumber(({ gem1, gem2, gem3, gem4 })[index])
    if (gemID and gemID > 0) then
        return gemID
    end
end

function lib:GetItemGemInfo(ItemLink)
    local total, info = 0, {}
    local stats = GetItemStats(ItemLink)
    if (type(stats) == "table") then
        for key, num in pairs(stats) do
            if (string.find(key, "EMPTY_SOCKET_")) then
                for i = 1, num do
                    total = total + 1
                    table.insert(info, { name = _G[key] or EMPTY, link = nil })
                end
            end
        end
    end
    local quality = select(3, GetItemInfo(ItemLink))
    -- Artifact relic socket count changed in later versions; trust actual socket stats.
    if (quality == 6 and total > 0) then
        for i = 1, total-#info do
            table.insert(info, { name = RELICSLOT or EMPTY, link = nil })
        end
    end
    local name, link
    for i = 1, 4 do
        name, link = GetItemGem(ItemLink, i)
        if (not link) then
            local gemID = GetEmbeddedGemID(ItemLink, i)
            if (gemID) then
                name, link = GetItemInfo(gemID)
                link = link or ("item:" .. gemID)
            end
        end
        if (link) then
            if (info[i]) then
                info[i].name = name
                info[i].link = link
            else
                table.insert(info, { name = name, link = link })
            end
        end
    end
    if (#info > total) then
        total = #info
    end
    return total, info, quality
end
