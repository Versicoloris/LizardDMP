LizardDMPTipScan = {}

local scanTip = CreateFrame("GameTooltip", "LizardDMPScanTip", nil, "GameTooltipTemplate")
scanTip:SetOwner(UIParent, "ANCHOR_NONE")

local STAT_PATTERNS = {
    ["Strength"] = {
        "%+(%d+) Strength",
    },
    ["Agility"] = {
        "%+(%d+) Agility",
    },
    ["Stamina"] = {
        "%+(%d+) Stamina",
    },
    ["Intellect"] = {
        "%+(%d+) Intellect",
    },
    ["Spirit"] = {
        "%+(%d+) Spirit",
    },

    ["Spell Power"] = {
        "Increases spell power by (%d+)",
        "Improves spell power by (%d+)",
        "Increases damage and healing by (%d+)",
        "%+(%d+) Spell Power",
        "%+(%d+) Damage and Healing",
    },

    ["Attack Power"] = {
    "Increases attack power by (%d+)",
    "Improves attack power by (%d+)",
    "%+(%d+) Attack Power",
    },
    
    ["Haste"] = {
        "Increases your haste rating by (%d+)",
        "Improves haste rating by (%d+)",
        "%+(%d+) Haste Rating",
    },

    ["Critical Strike"] = {
        "Increases your critical strike rating by (%d+)",
        "Improves critical strike rating by (%d+)",
        "%+(%d+) Critical Strike Rating",
    },

    ["Hit Rating"] = {
        "Increases your hit rating by (%d+)",
        "Improves hit rating by (%d+)",
        "%+(%d+) Hit Rating",
    },

    ["Expertise"] = {
        "Increases your expertise rating by (%d+)",
        "Improves expertise rating by (%d+)",
        "%+(%d+) Expertise Rating",
    },

    ["Armor Penetration"] = {
        "Increases your armor penetration rating by (%d+)",
        "Improves armor penetration rating by (%d+)",
        "%+(%d+) Armor Penetration Rating",
    },

    ["Resilience"] = {
        "Increases your resilience rating by (%d+)",
        "Improves resilience rating by (%d+)",
        "%+(%d+) Resilience Rating",
    },

    ["Defense"] = {
        "Increases defense rating by (%d+)",
        "Improves defense rating by (%d+)",
        "%+(%d+) Defense Rating",
    },

    ["Dodge"] = {
        "Increases your dodge rating by (%d+)",
        "Improves dodge rating by (%d+)",
        "%+(%d+) Dodge Rating",
    },

    ["Parry"] = {
        "Increases your parry rating by (%d+)",
        "Improves parry rating by (%d+)",
        "%+(%d+) Parry Rating",
    },
}

function LizardDMPTipScan:GetStatFromItem(link, statName)
    scanTip:ClearLines()
    scanTip:SetHyperlink(link)

    local patterns = STAT_PATTERNS[statName]
    if not patterns then return 0 end

    local total = 0

    for i = 2, scanTip:NumLines() do
        local text = _G["LizardDMPScanTipTextLeft"..i]:GetText()
        if text then
            for _, pattern in ipairs(patterns) do
                local value = text:match(pattern)
                if value then
                    total = total + tonumber(value)
                end
            end
        end
    end

    return total
end