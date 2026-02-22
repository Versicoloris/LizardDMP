LizardDMP = {}
LizardDMP.bestBySlot = {}
LizardDMP.primaryStat = nil
LizardDMP.secondaryStat = nil

local ADDON_NAME = ...

local INVTYPE_MAP = {
    ["INVTYPE_HEAD"] = "HeadSlot",
    ["INVTYPE_NECK"] = "NeckSlot",
    ["INVTYPE_SHOULDER"] = "ShoulderSlot",
    ["INVTYPE_CHEST"] = "ChestSlot",
    ["INVTYPE_ROBE"] = "ChestSlot",
    ["INVTYPE_WAIST"] = "WaistSlot",
    ["INVTYPE_LEGS"] = "LegsSlot",
    ["INVTYPE_FEET"] = "FeetSlot",
    ["INVTYPE_WRIST"] = "WristSlot",
    ["INVTYPE_HAND"] = "HandsSlot",
    ["INVTYPE_FINGER"] = "FingerSlot",
    ["INVTYPE_TRINKET"] = "TrinketSlot",
    ["INVTYPE_CLOAK"] = "BackSlot",
    ["INVTYPE_WEAPON"] = "MainHandSlot",
    ["INVTYPE_2HWEAPON"] = "MainHandSlot",
    ["INVTYPE_WEAPONMAINHAND"] = "MainHandSlot",
    ["INVTYPE_WEAPONOFFHAND"] = "SecondaryHandSlot",
    ["INVTYPE_HOLDABLE"] = "SecondaryHandSlot",
    ["INVTYPE_SHIELD"] = "SecondaryHandSlot",
}

-- ========================================
-- SCORE
-- ========================================
function LizardDMP:GetItemScore(link)
    if not link then return 0 end

    local primary = 0
    local secondary = 0

    if self.primaryStat then
        primary = LizardDMPTipScan:GetStatFromItem(link, self.primaryStat) or 0
    end

    if self.secondaryStat then
        secondary = LizardDMPTipScan:GetStatFromItem(link, self.secondaryStat) or 0
    end

    -- BOTH set → filter by primary, score by secondary
    if self.primaryStat and self.secondaryStat then
        if primary <= 0 then return 0 end
        return secondary
    end

    -- only secondary
    if not self.primaryStat and self.secondaryStat then
        return secondary
    end

    -- only primary
    if self.primaryStat and not self.secondaryStat then
        return primary
    end

    return 0
end

-- ========================================
-- EVALUATE
-- ========================================
function LizardDMP:EvaluateItem(link)
    if not link then return end

    local itemName, _, _, _, _, _, _, _, equipLoc = GetItemInfo(link)

    -- cache protection
    if not itemName then
        local itemID = tonumber(link:match("item:(%d+)"))
        if itemID then
            local f = CreateFrame("Frame")
            f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
            f:SetScript("OnEvent", function(_, _, receivedID)
                if receivedID == itemID then
                    LizardDMP:EvaluateItem(link)
                    f:UnregisterAllEvents()
                end
            end)
        end
        return
    end

    local slotName = INVTYPE_MAP[equipLoc]
    if not slotName then return end

    local score = self:GetItemScore(link)
    if score <= 0 then return end

    -- rings & trinkets keep top 2
    if slotName == "FingerSlot" or slotName == "TrinketSlot" then
        self.bestBySlot[slotName] = self.bestBySlot[slotName] or {}

        for _, data in ipairs(self.bestBySlot[slotName]) do
            if data.link == link then
                return
            end
        end

        table.insert(self.bestBySlot[slotName], {
            link = link,
            score = score,
        })

        table.sort(self.bestBySlot[slotName], function(a, b)
            return a.score > b.score
        end)

        while #self.bestBySlot[slotName] > 2 do
            table.remove(self.bestBySlot[slotName])
        end

        return
    end

    -- normal slots
    local current = self.bestBySlot[slotName]

    if not current or score > current.score then
        self.bestBySlot[slotName] = {
            link = link,
            score = score,
        }
    end
end

-- ========================================
-- SCAN
-- ========================================
function LizardDMP:ScanAllGear(isAuto)
    wipe(self.bestBySlot)

    -- equipped
    for slotID = 1, 19 do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            self:EvaluateItem(link)
        end
    end

    -- bags
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link then
                self:EvaluateItem(link)
            end
        end
    end

    -- ✅ only print for manual scans
    if not isAuto then
        print("|cff00ff00LizardDMP scan complete.|r")
    end
end

-- ========================================
-- EQUIP
-- ========================================
function LizardDMP:EquipAllBest()
    if InCombatLockdown() then
        print("|cffff0000Cannot swap gear in combat.|r")
        return
    end

    for slotName, data in pairs(self.bestBySlot) do
        if slotName == "FingerSlot" and type(data) == "table" then
            if data[1] then EquipItemByName(data[1].link, 11) end
            if data[2] then EquipItemByName(data[2].link, 12) end

        elseif slotName == "TrinketSlot" and type(data) == "table" then
            if data[1] then EquipItemByName(data[1].link, 13) end
            if data[2] then EquipItemByName(data[2].link, 14) end

        else
            if data and data.link then
                EquipItemByName(data.link)
            end
        end
    end

    print("|cff00ff00Equipped best gear.|r")
end

-- ========================================
-- SAVEDVARIABLES INIT (FINAL WRATH PATTERN)
-- ========================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")

initFrame:SetScript("OnEvent", function(self, event, addonName)
    if addonName ~= ADDON_NAME then return end

    -- ensure SV table exists AFTER load
    if not LizardDMPSaved then
        LizardDMPSaved = {}
    end

    -- ⭐ minimap default
    if LizardDMPSaved.minimapPos == nil then
        LizardDMPSaved.minimapPos = 220
    end

    -- restore runtime
    LizardDMP.primaryStat = LizardDMPSaved.primaryStat
    LizardDMP.secondaryStat = LizardDMPSaved.secondaryStat

    -- force WoW to mark SV as changed
    LizardDMPSaved.__touched = true

    self:UnregisterEvent("ADDON_LOADED")
end)

-- ========================================
-- AUTO SCAN ENGINE (bag-settle batching)
-- ========================================
local autoFrame = CreateFrame("Frame")
autoFrame:RegisterEvent("BAG_UPDATE")

local settleDelay = 0.35
local timeSinceLastUpdate = 0
local dirty = false

autoFrame:SetScript("OnEvent", function(self)
    if not LizardDMPSaved or not LizardDMPSaved.autoScan then
        return
    end

    -- mark bags dirty and start/update timer
    dirty = true
    timeSinceLastUpdate = 0

    self:SetScript("OnUpdate", function(frame, elapsed)
        if not dirty then return end

        timeSinceLastUpdate = timeSinceLastUpdate + elapsed

        -- wait until bags have been quiet for the delay
        if timeSinceLastUpdate < settleDelay then return end

        -- bags settled → run ONE scan
        dirty = false
        frame:SetScript("OnUpdate", nil)

        if LizardDMP and LizardDMP.ScanAllGear then
            LizardDMP:ScanAllGear(true)
        end
    end)
end)