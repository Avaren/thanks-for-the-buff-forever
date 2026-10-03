local _, ns = ...
local panel, category, enabled, group, status, clickBuff, extraEmotes, extraStatus
local choices, waits = {}, {}
local options = {
    { "RANDOM", "Random from selected" },
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
    if not panel or not ThanksForTheBuffForeverDB then return end
    local db = ThanksForTheBuffForeverDB
    enabled:SetChecked(db.enabled)
    group:SetChecked(db.group)
    clickBuff:SetChecked(db.clickBuff ~= false)
    if extraEmotes and not extraEmotes:HasFocus() then extraEmotes:SetText(db.extraEmoteText or "") end
    for key, field in pairs(waits) do
        UIDropDownMenu_SetSelectedValue(field, db[key])
        local value = db[key]
        local label = value .. (value == 1 and " second" or " seconds")
        if value < 1 or value > 5 then label = label .. " (saved)" end
        UIDropDownMenu_SetText(field, label)
    end
    status:SetText(db.enabled and "Automatic thanks: |cff40ff80ON|r" or "Automatic thanks: |cffff7070OFF|r")
    for value, button in pairs(choices) do
        local checked = db.emote == value
        if db.emote == "RANDOM" and value ~= "RANDOM" then checked = db.randomEmotes[value] end
        button:SetChecked(checked)
    end
end

local function RegisterPanel()
    if panel then return end
    panel = CreateFrame("Frame", "ThanksForTheBuffForeverSettings")
    panel.name = "Thanks for the Buff Forever"
    Text(panel, panel.name, 16, -16, "GameFontNormalLarge")
    enabled = Check(panel, "Enable automatic thanks", 16, -50, function(value) ns.SetOption("enabled", value) end)
    status = Text(panel, "", 50, -83)
    group = Check(panel, "Also thank party and raid members", 16, -106, function(value) ns.SetOption("group", value) end)
    Text(panel, "Emotes - Random uses your checked choices (keep at least one)", 20, -151, "GameFontNormal")
    for index, option in ipairs(options) do
        local value = option[1]
        local column, row = math.floor((index - 1) / 3), (index - 1) % 3
        choices[value] = Check(panel, option[2], 16 + column * 260, -174 - row * 30,
            function(checked) ns.ToggleEmote(value, checked) end)
    end
    Text(panel, "Extra random emotes (comma-separated)", 20, -273, "GameFontNormal")
    extraEmotes = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    extraEmotes:SetSize(360, 24)
    extraEmotes:SetPoint("TOPLEFT", 24, -296)
    extraEmotes:SetAutoFocus(false)
    extraEmotes:SetMaxLetters(500)
    extraStatus = Text(panel, "Type wave, smile, dance. Slashes are added on save.", 20, -327, "GameFontHighlightSmall")
    local function SaveExtras()
        local ok, message = ns.SetExtraEmotes(extraEmotes:GetText())
        extraStatus:SetText(message)
        extraStatus:SetTextColor(ok and .5 or 1, ok and 1 or .35, ok and .5 or .35)
        if ok then extraEmotes:ClearFocus(); extraEmotes:SetText(ThanksForTheBuffForeverDB.extraEmoteText) end
    end
    extraEmotes:SetScript("OnEnterPressed", SaveExtras)
    extraEmotes:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(ThanksForTheBuffForeverDB.extraEmoteText or "")
        extraStatus:SetText("Edits cancelled.")
    end)
    local save = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    save:SetSize(80,24)
    save:SetPoint("TOPLEFT", 398, -296)
    save:SetText("Save")
    save:SetScript("OnClick", SaveExtras)
    Text(panel, "Thanks timing (choose 1-5 seconds)", 20, -350, "GameFontNormal")
    local function WaitField(key, label, x, y)
        Text(panel, label, x, y - 8, "GameFontHighlightSmall")
        local field = CreateFrame("Frame", "ThanksForTheBuffForeverTiming_" .. key, panel, "UIDropDownMenuTemplate")
        field:SetPoint("TOPLEFT", x+155, y+2)
        UIDropDownMenu_SetWidth(field, 130)
        waits[key] = field
        UIDropDownMenu_Initialize(field, function()
            for seconds=1,5 do
                local value = seconds
                local info = UIDropDownMenu_CreateInfo()
                info.text = value .. (value == 1 and " second" or " seconds")
                info.value = value
                info.checked = ThanksForTheBuffForeverDB[key] == value
                info.func = function() ns.SetOption(key, value) end
                UIDropDownMenu_AddButton(info)
            end
        end)
    end
    WaitField("thanksDelay", "Delay before thanks", 20, -371)
    WaitField("thanksInterval", "Between any thanks", 20, -405)
    WaitField("playerInterval", "For the same player", 20, -439)
    Text(panel, "Buff helpers", 20, -481, "GameFontNormal")
    clickBuff = Check(panel, "Show missing buff on target frame", 16, -505, function(value) ns.SetOption("clickBuff", value) end)
    Text(panel, "Select a friendly player and click the rounded spell icon.", 20, -541, "GameFontHighlightSmall")
    Text(panel, "Mouseover key: Key Bindings > Thanks for the Buff Forever.", 20, -565, "GameFontHighlightSmall")
    Text(panel, "Buff back appears for 10 seconds when someone buffs you.", 20, -589, "GameFontHighlightSmall")
    Text(panel, "Checkboxes save automatically. Extra emotes: Enter or Save.", 20, -625, "GameFontHighlightSmall")
    panel:SetScript("OnShow", ns.RefreshSettings)
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
    elseif InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
    ns.RefreshSettings()
end

function ns.OpenSettings()
    if not ThanksForTheBuffForeverDB then return end
    RegisterPanel()
    if category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(category:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(panel)
    end
end

local register = CreateFrame("Frame")
register:RegisterEvent("PLAYER_LOGIN")
register:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    RegisterPanel()
end)
