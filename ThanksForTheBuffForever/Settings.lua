local _, ns = ...
local window, enabled, group, status
local choices = {}
local options = {
    { "RANDOM", "Random friendly emote" },
    { "THANK", "Thank" }, { "CHEER", "Cheer" },
    { "BOW", "Bow" }, { "SALUTE", "Salute" }, { "APPLAUD", "Applaud" },
}

local function Text(parent, text, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Check(parent, text, x, y, callback)
    local button = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    button:SetSize(28, 28)
    button:SetPoint("TOPLEFT", x, y)
    local label = Text(parent, text, x + 34, y - 7)
    button:SetScript("OnClick", function(self) callback(self:GetChecked() and true or false) end)
    return button
end

function ns.RefreshSettings()
    if not window or not ThanksForTheBuffForeverDB then return end
    local db = ThanksForTheBuffForeverDB
    enabled:SetChecked(db.enabled)
    group:SetChecked(db.group)
    status:SetText(db.enabled and "Automatic thanks: |cff40ff80ON|r" or "Automatic thanks: |cffff7070OFF|r")
    for value, button in pairs(choices) do button:SetChecked(db.emote == value) end
end

function ns.OpenSettings()
    if not ThanksForTheBuffForeverDB then return end
    if not window then
        window = CreateFrame("Frame", "ThanksForTheBuffForeverSettings", UIParent, "BasicFrameTemplateWithInset")
        window:SetSize(450, 450)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetClampedToScreen(true)
        window:EnableMouse(true)
        window:SetMovable(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window.TitleText:SetText("Thanks for the Buff Forever")
        table.insert(UISpecialFrames, "ThanksForTheBuffForeverSettings")
        enabled = Check(window, "Enable automatic thanks", 20, -45, function(value) ns.SetOption("enabled", value) end)
        status = Text(window, "", 54, -80)
        group = Check(window, "Also thank party and raid members", 20, -105, function(value) ns.SetOption("group", value) end)
        Text(window, "Choose an emote", 24, -151, "GameFontNormal")
        for index, option in ipairs(options) do
            local value = option[1]
            choices[value] = Check(window, option[2], 20, -172 - (index - 1) * 30,
                function() ns.SetOption("emote", value) end)
        end
        Text(window, "Random picks from Thank, Cheer, Bow, Salute, and Applaud.", 24, -365, "GameFontHighlightSmall")
        Text(window, "Waits 15 seconds between thanks; 90 seconds per player.", 24, -386, "GameFontHighlightSmall")
        Text(window, "Changes save automatically. No thanks are sent in combat.", 24, -407, "GameFontHighlightSmall")
        window:SetScript("OnShow", ns.RefreshSettings)
    end
    window:Show()
    ns.RefreshSettings()
end

-- A discoverable entry in the game's AddOns settings opens the same window.
local register = CreateFrame("Frame")
register:RegisterEvent("PLAYER_LOGIN")
register:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    local panel = CreateFrame("Frame")
    panel.name = "Thanks for the Buff Forever"
    Text(panel, panel.name, 16, -16, "GameFontNormalLarge")
    Text(panel, "Turn automatic thanks on or off, and choose your emote.", 16, -48)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetSize(180, 28)
    button:SetPoint("TOPLEFT", 16, -80)
    button:SetText("Open settings")
    button:SetScript("OnClick", ns.OpenSettings)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end)
