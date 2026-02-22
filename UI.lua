-- ================================
-- Primary stats
-- ================================
local PRIMARY_STATS = {
    "Strength",
    "Agility",
    "Stamina",
    "Intellect",
    "Spirit",
}

-- ================================
-- Secondary stats
-- ================================
local SECONDARY_STATS = {
    "Spell Power",
    "Haste",
    "Critical Strike",
    "Hit Rating",
    "Expertise",
    "Armor Penetration",
    "Resilience",
    "Defense",
    "Dodge",
    "Parry",
    "Attack Power",
}

-- ================================
-- Main Frame
-- ================================
local f = CreateFrame("Frame", "LizardDMPFrame", UIParent)
f:SetSize(260, 210)
f:SetPoint("CENTER")

f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 8, right = 8, top = 8, bottom = 8 }
})

f:SetMovable(true)
f:EnableMouse(true)
f:RegisterForDrag("LeftButton")

f:SetScript("OnDragStart", f.StartMoving)
f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()

    LizardDMPSaved.framePos = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end)

f:Hide()
tinsert(UISpecialFrames, "LizardDMPFrame")

-- ================================
-- Title
-- ================================
local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -12)
title:SetText("LizardDMP")

-- ================================
-- Close Button
-- ================================
local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", -5, -5)

-- ================================
-- Primary Dropdown
-- ================================
local primaryDD = CreateFrame("Frame", "LizardDMPPrimaryDropdown", f, "UIDropDownMenuTemplate")
primaryDD:SetPoint("TOPLEFT", 10, -40)

local function OnPrimarySelected(self)
    UIDropDownMenu_SetText(primaryDD, self.value)
    LizardDMP.primaryStat = self.value
    LizardDMPSaved.primaryStat = self.value
end

UIDropDownMenu_Initialize(primaryDD, function(self, level)
    local info = UIDropDownMenu_CreateInfo()

    -- None option
    info.text = "None"
    info.value = nil
    info.func = function()
        UIDropDownMenu_SetText(primaryDD, "None")
        LizardDMP.primaryStat = nil
        LizardDMPSaved.primaryStat = nil
    end
    UIDropDownMenu_AddButton(info)

    for _, stat in ipairs(PRIMARY_STATS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = stat
        info.value = stat
        info.func = OnPrimarySelected
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetWidth(primaryDD, 160)
UIDropDownMenu_SetText(primaryDD, "Primary (Optional)")

local primaryLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
primaryLabel:SetPoint("BOTTOMLEFT", primaryDD, "TOPLEFT", 20, 3)
primaryLabel:SetText("Primary")

-- ================================
-- Secondary Dropdown
-- ================================
local dropdown = CreateFrame("Frame", "LizardDMPStatDropdown", f, "UIDropDownMenuTemplate")
dropdown:SetPoint("TOPLEFT", 10, -90)

local function OnStatSelected(self)
    UIDropDownMenu_SetText(dropdown, self.value)
    LizardDMP.secondaryStat = self.value
    LizardDMPSaved.secondaryStat = self.value
end

UIDropDownMenu_Initialize(dropdown, function(self, level)
    for _, stat in ipairs(SECONDARY_STATS) do
        local info = UIDropDownMenu_CreateInfo()
        info.text = stat
        info.value = stat
        info.func = OnStatSelected
        UIDropDownMenu_AddButton(info)
    end
end)

UIDropDownMenu_SetWidth(dropdown, 160)
UIDropDownMenu_SetText(dropdown, "Secondary")

local label = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 20, 3)
label:SetText("Secondary")

-- ================================
-- Scan Button
-- ================================
local scanBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
scanBtn:SetSize(100, 24)
scanBtn:SetPoint("BOTTOMLEFT", 20, 20)
scanBtn:SetText("Scan")

scanBtn:SetScript("OnClick", function()
    LizardDMP:ScanAllGear()
end)

-- ================================
-- Equip Button
-- ================================
local equipBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
equipBtn:SetSize(100, 24)
equipBtn:SetPoint("BOTTOMRIGHT", -20, 20)
equipBtn:SetText("Equip")

equipBtn:SetScript("OnClick", function()
    LizardDMP:EquipAllBest()
end)

-- ================================
-- Auto Scan Checkbox (fixed layout)
-- ================================
local autoCheck = CreateFrame("CheckButton", "LizardDMPAutoScanCheck", f, "UICheckButtonTemplate")

-- anchor ABOVE the buttons, not on top of them
autoCheck:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 44)

autoCheck.text = autoCheck:CreateFontString(nil, "OVERLAY", "GameFontNormal")
autoCheck.text:SetPoint("LEFT", autoCheck, "RIGHT", 4, 0)
autoCheck.text:SetText("Auto-scan bags")

autoCheck:SetScript("OnClick", function(self)
    if LizardDMPSaved then
        LizardDMPSaved.autoScan = self:GetChecked() and true or false
    end
end)
-- ================================
-- Sync dropdown text
-- ================================
function SyncDropdownText()
    -- pull directly from saved table (race-proof)
    local savedPrimary = LizardDMPSaved and LizardDMPSaved.primaryStat
    local savedSecondary = LizardDMPSaved and LizardDMPSaved.secondaryStat

    -- Primary dropdown
    if savedPrimary then
        UIDropDownMenu_SetText(primaryDD, savedPrimary)
        LizardDMP.primaryStat = savedPrimary
    else
        UIDropDownMenu_SetText(primaryDD, "None")
        LizardDMP.primaryStat = nil
    end

    -- Secondary dropdown
    if savedSecondary then
        UIDropDownMenu_SetText(dropdown, savedSecondary)
        LizardDMP.secondaryStat = savedSecondary
    else
        UIDropDownMenu_SetText(dropdown, "Secondary")
        LizardDMP.secondaryStat = nil
    end

        -- sync checkbox
    if LizardDMPSaved and autoCheck then
        autoCheck:SetChecked(LizardDMPSaved.autoScan and true or false)
    end
end

-- ================================
-- Restore frame position + sync
-- ================================
local posLoader = CreateFrame("Frame")
posLoader:RegisterEvent("PLAYER_LOGIN")
posLoader:SetScript("OnEvent", function()
    if LizardDMPSaved and LizardDMPSaved.framePos then
        local p = LizardDMPSaved.framePos
        f:ClearAllPoints()
        f:SetPoint(p.point, UIParent, p.relativePoint, p.x, p.y)
    end

    -- Wrath-safe defer (next frame)
    local delay = CreateFrame("Frame")
    delay:SetScript("OnUpdate", function(self)
        SyncDropdownText()
        self:SetScript("OnUpdate", nil)
    end)
end)

-- ================================
-- Slash Toggle
-- ================================
SLASH_LIZARDDMP1 = "/ldmp"
SlashCmdList["LIZARDDMP"] = function()
    if LizardDMPFrame:IsShown() then
        LizardDMPFrame:Hide()
    else
        LizardDMPFrame:Show()
    end
end

-- ========================================
-- MINIMAP BUTTON (Wrath-safe)
-- ========================================
local mini = CreateFrame("Button", "LizardDMP_MinimapButton", Minimap)
mini:SetSize(32, 32)
mini:SetFrameStrata("MEDIUM")
mini:SetMovable(true)
mini:RegisterForDrag("LeftButton")
mini:RegisterForClicks("LeftButtonUp", "RightButtonUp")

-- icon
mini.icon = mini:CreateTexture(nil, "BACKGROUND")
mini.icon:SetTexture("Interface\\Icons\\INV_Misc_MonsterScales_12")
mini.icon:SetSize(20, 20)
mini.icon:SetTexCoord(0.10, 0.90, 0.10, 0.90)
mini.icon:SetPoint("CENTER", mini, "CENTER", 0, 0)

-- border
mini.border = mini:CreateTexture(nil, "OVERLAY")
mini.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
mini.border:SetSize(54, 54)
mini.border:SetPoint("TOPLEFT")

-- ========================================
-- POSITIONING
-- ========================================
local function LizardDMP_UpdateMinimapPos()
    local angle = LizardDMPSaved and LizardDMPSaved.minimapPos or 220
    local radius = 80

    local x = math.cos(math.rad(angle)) * radius
    local y = math.sin(math.rad(angle)) * radius

    mini:ClearAllPoints()
    mini:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

mini:SetScript("OnDragStart", function(self)
    self.dragging = true
    self:SetScript("OnUpdate", function(frame)
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = UIParent:GetScale()

        px, py = px / scale, py / scale

        local angle = math.deg(math.atan2(py - my, px - mx))
        if angle < 0 then angle = angle + 360 end

        LizardDMPSaved.minimapPos = angle
        LizardDMP_UpdateMinimapPos()
    end)
end)

mini:SetScript("OnDragStop", function(self)
    self.dragging = false
    self:SetScript("OnUpdate", nil)
end)

-- ========================================
-- CLICKS
-- ========================================
mini:SetScript("OnClick", function(self, button)
    if button == "LeftButton" then
        -- toggle window
        if LizardDMPFrame:IsShown() then
            LizardDMPFrame:Hide()
        else
            LizardDMPFrame:Show()
        end

    elseif button == "RightButton" then
        if LizardDMP then
            LizardDMP:ScanAllGear(true)
            LizardDMP:EquipAllBest()
        end
    end
end)

-- ========================================
-- TOOLTIP
-- ========================================
mini:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("|cff00ff00LizardDMP|r")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Left Click: Open window", 1, 1, 1)
    GameTooltip:AddLine("Right Click: Scan + Equip", 1, 1, 1)
    GameTooltip:AddLine(" ")

    local p = LizardDMP and LizardDMP.primaryStat or "None"
    local s = LizardDMP and LizardDMP.secondaryStat or "None"

    GameTooltip:AddLine("Primary: |cffffff00"..tostring(p).."|r")
    GameTooltip:AddLine("Secondary: |cffffff00"..tostring(s).."|r")

    GameTooltip:Show()
end)

mini:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ========================================
-- INITIAL POSITION
-- ========================================
local miniInit = CreateFrame("Frame")
miniInit:RegisterEvent("PLAYER_LOGIN")
miniInit:SetScript("OnEvent", function()
    LizardDMP_UpdateMinimapPos()
end)