local addonName, ns = ...
local frame = CreateFrame("Frame")
local seen, cooldowns, names, ids = {}, {}, {}, {}
local ready, baseline, active = false, true, false
local quietUntil, lastThanks = 0, nil
local pendingThanks, thanksGeneration = {}, 0
local function CancelThanks()
    pendingThanks = {}
    thanksGeneration = thanksGeneration + 1
end
local lastIssue = "none"
local detectionStatus = "Waiting for a new supported buff."
local thanksStatus = "No thanks queued."
local backStatus = "No buff-back offer yet."
local emotes = { "THANK", "CHEER", "BOW", "SALUTE", "APPLAUD" }
local allowed = { THANK=true, CHEER=true, BOW=true, SALUTE=true, APPLAUD=true, RANDOM=true }
local function ParseExtras(text)
    local lookup, list, used = {}, {}, {}
    for _, token in ipairs(emotes) do lookup[token:lower()] = token end
    for i=1,1000 do
        local token = _G["EMOTE"..i.."_TOKEN"]
        if type(token) == "string" then
            lookup[token:lower()] = token
            for j=1,20 do
                local command = _G["EMOTE"..i.."_CMD"..j]
                if type(command) == "string" then lookup[command:lower():gsub("^/", "")] = token end
            end
        end
    end
    for part in text:gmatch("[^,]+") do
        local command = part:match("^%s*(.-)%s*$"):lower():gsub("^/", "")
        if command ~= "" then
            local token = lookup[command]
            if not token then return nil, "Unknown emote: " .. command end
            if not used[token] then list[#list+1] = token; used[token] = true end
        end
    end
    return list
end
function ns.SetExtraEmotes(text)
    if type(text) ~= "string" or #text>500 then return false, "Use up to 500 characters." end
    local list, issue = ParseExtras(text)
    if not list then return false, issue end
    local commands = {}
    for part in text:gmatch("[^,]+") do
        local command = part:match("^%s*(.-)%s*$"):lower():gsub("^/", "")
        if command ~= "" then commands[#commands+1] = "/" .. command end
    end
    ThanksForTheBuffForeverDB.extraEmoteText = table.concat(commands, ", ")
    ThanksForTheBuffForeverDB.extraEmotes = list
    return true, "Saved. Extra emotes are included when Random is on."
end

local function Public(value)
    return not issecretvalue or not issecretvalue(value)
end

local function PlainString(value)
    return Public(value) and type(value) == "string" and value ~= ""
end

local function Message(text)
    print("|cff80d0ffThanks for the Buff Forever:|r " .. text)
end

local function BuildBuffs()
    for _, id in ipairs(ns.buffIDs) do
        ids[id] = true
        local name
        if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(id)
        elseif GetSpellInfo then name = GetSpellInfo(id) end
        if PlainString(name) then names[name] = true end
    end
end

local function GetAura(index)
    if C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
        return C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
    elseif UnitBuff then
        local name, _, _, _, _, _, source, _, _, spellId = UnitBuff("player", index)
        if not Public(name) then return {} end
        if not name then return nil end
        return { name=name, sourceUnit=source, spellId=spellId }
    end
    lastIssue = "No supported buff-reading API on this client."
end

local function IsGroupMember(guid)
    for i=1,40 do
        local unit = i <= 4 and ("party" .. i) or nil
        if unit then
            local other = UnitGUID(unit)
            if Public(other) and other == guid then return true end
        end
        local other = UnitGUID("raid" .. i)
        if Public(other) and other == guid then return true end
    end
    return false
end

local function ResolveCaster(source, guid)
    local function Match(unit)
        local current = UnitGUID(unit)
        return Public(current) and current == guid
    end
    for _, unit in ipairs({source, "target", "focus", "mouseover"}) do
        if Match(unit) then return unit end
    end
    for i=1,40 do
        if i<=4 and Match("party"..i) then return "party"..i end
        if Match("raid"..i) then return "raid"..i end
        if Match("nameplate"..i) then return "nameplate"..i end
    end
end

local function Thank(unit, guid, now)
    local db = ThanksForTheBuffForeverDB
    if not db.enabled or (lastThanks and now-lastThanks < db.thanksInterval)
        or (cooldowns[guid] and now-cooldowns[guid] < db.playerInterval) then thanksStatus = "Disabled or waiting for a thanks cooldown."; return end
    if not db.group and IsGroupMember(guid) then thanksStatus = "Skipped a party or raid member."; return end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then thanksStatus = "Chat messaging is locked by the client."; return end
    -- Only use a currently resolvable unit. Names alone can produce an untargeted emote.
    unit = ResolveCaster(unit, guid)
    if not unit then thanksStatus = "Caster no longer available when the delay finished."; return end
    if type(DoEmote) ~= "function" then
        lastIssue = "DoEmote is unavailable on this client."
        return
    end
    local emote = db.emote
    if emote == "RANDOM" then
        local pool = {}
        for _, value in ipairs(emotes) do
            if db.randomEmotes[value] then pool[#pool+1] = value end
        end
        local included = {}
        for _, value in ipairs(pool) do included[value] = true end
        for _, value in ipairs(db.extraEmotes or {}) do
            if not included[value] then pool[#pool+1] = value; included[value] = true end
        end
        if #pool == 0 then return end
        emote = pool[math.random(#pool)]
    end
    -- Consume the cooldown even if the client rejects the emote; never retry in a loop.
    cooldowns[guid], lastThanks = now, now
    local ok = pcall(DoEmote, emote, unit)
    thanksStatus = ok and "Emote requested; check chat for delivery." or "Client rejected the emote."
    if not ok then lastIssue = "The client blocked an emote. Try again out of combat." end
end

local function QueueThanks(unit, guid, now)
    local delay = ThanksForTheBuffForeverDB.thanksDelay
    if not ThanksForTheBuffForeverDB.enabled or pendingThanks[guid] then return end
    if delay == 0 then Thank(unit, guid, now); return end
    local generation = thanksGeneration
    pendingThanks[guid] = true
    thanksStatus = "Thanks queued for " .. delay .. " seconds after the buff."
    C_Timer.After(delay, function()
        if generation ~= thanksGeneration then return end
        pendingThanks[guid] = nil
        if ready and active and not InCombatLockdown() then Thank(unit, guid, GetTime()) end
    end)
end

local function Scan()
    local now = GetTime()
    local current = {}
    for index=1,255 do
        local aura = GetAura(index)
        if not Public(aura) then break end
        if not aura then break end
        local name, spellId, unit = aura.name, aura.spellId, aura.sourceUnit
        if PlainString(name) and Public(spellId) and (ids[spellId] or names[name]) and not PlainString(unit) then
            detectionStatus = name .. ": the client did not provide an identifiable caster."
        end
        if PlainString(name) and Public(spellId) and PlainString(unit) then
            local isPlayer = UnitIsPlayer(unit)
            local guid, own = UnitGUID(unit), UnitGUID("player")
            if Public(spellId) and (ids[spellId] or names[name]) and (not Public(isPlayer) or not isPlayer or not PlainString(guid)) then
                detectionStatus = name .. ": the caster unit could not be resolved to a player."
            end
            if Public(isPlayer) and isPlayer and PlainString(guid) and PlainString(own) and guid ~= own then
                if ids[spellId] or names[name] then
                    local key = guid .. ":" .. name
                    current[key] = true
                    if not baseline and now >= quietUntil and not seen[key] then
                        detectionStatus = "Detected " .. name .. " from another player."
                        if ns.OfferBuffBack then
                            local ok, reason = pcall(ns.OfferBuffBack, unit, guid)
                            backStatus = ok and (reason or "Offer checked.") or "Buff-back check failed."
                        end
                        QueueThanks(unit, guid, now)
                    end
                end
            end
        end
    end
    seen, baseline = current, false
    for guid, thankedAt in pairs(cooldowns) do
        if now-thankedAt >= 3600 then cooldowns[guid] = nil end
    end
end

local function SafeScan()
    if not ready or not active then return end
    if InCombatLockdown() then baseline = true; detectionStatus = "Buff detection skipped during combat."; return end
    local ok = pcall(Scan)
    if not ok then
        baseline = true
        lastIssue = "Buff data was unavailable or restricted; skipped this update."
    end
end

local function Init()
    if type(ThanksForTheBuffForeverDB) ~= "table" then ThanksForTheBuffForeverDB = {} end
    local db = ThanksForTheBuffForeverDB
    CancelThanks()
    for key, default in pairs({thanksDelay=2, thanksInterval=15, playerInterval=90}) do
        local value = db[key]
        if type(value) ~= "number" or value ~= value or value < 0 or value > 3600 then value = default end
        db[key] = math.floor(value)
    end
    if type(db.enabled) ~= "boolean" then db.enabled = true end
    if type(db.group) ~= "boolean" then db.group = false end
    if type(db.emote) ~= "string" or not allowed[db.emote] then db.emote = "THANK" end
    if type(db.randomEmotes) ~= "table" then
        db.randomEmotes = {}
        for _, value in ipairs(emotes) do db.randomEmotes[value] = true end
    end
    local count = 0
    for _, value in ipairs(emotes) do
        db.randomEmotes[value] = db.randomEmotes[value] == true
        if db.randomEmotes[value] then count = count + 1 end
    end
    if count == 0 then db.randomEmotes.THANK = true end
    if not allowed[db.singleEmote or ""] or db.singleEmote == "RANDOM" then db.singleEmote = "THANK" end
    if db.emote ~= "RANDOM" then db.singleEmote = db.emote end
    if type(db.extraEmoteText) ~= "string" then db.extraEmoteText = "" end
    if not ns.SetExtraEmotes(db.extraEmoteText) then db.extraEmotes = {} end
    BuildBuffs()
    ready = true
end

-- Both slash commands and the settings window use the same live settings path.
function ns.SetOption(key, value)
    if not ready then return end
    if key == "enabled" or key == "group" or key == "clickBuff" then
        if type(value) ~= "boolean" then return end
    elseif key == "thanksDelay" or key == "thanksInterval" or key == "playerInterval" then
        if type(value) ~= "number" or value ~= value or value < 0 or value > 3600 or value ~= math.floor(value) then return end
    elseif key == "emote" then
        if not allowed[value] then return end
    else return end
    ThanksForTheBuffForeverDB[key] = value
    if key == "emote" and value ~= "RANDOM" then ThanksForTheBuffForeverDB.singleEmote = value end
    if key == "enabled" then CancelThanks(); baseline = true; SafeScan() end
    if key == "thanksDelay" then CancelThanks() end
    if key == "clickBuff" and ns.RefreshClickBuff then ns.RefreshClickBuff() end
    if ns.RefreshSettings then ns.RefreshSettings() end
end

function ns.ToggleEmote(value, checked)
    if not ready or not allowed[value] then return end
    local db = ThanksForTheBuffForeverDB
    if value == "RANDOM" then
        ns.SetOption("emote", checked and "RANDOM" or db.singleEmote)
    elseif db.emote ~= "RANDOM" then
        ns.SetOption("emote", value)
    else
        local count = 0
        for _, emote in ipairs(emotes) do if db.randomEmotes[emote] then count=count+1 end end
        if checked or not db.randomEmotes[value] or count > 1 then
            db.randomEmotes[value] = checked and true or false
        end
        if ns.RefreshSettings then ns.RefreshSettings() end
    end
end

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" and unit == addonName then Init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        CancelThanks()
        active, baseline, quietUntil = true, true, GetTime() + 5
        SafeScan()
    elseif event == "PLAYER_LEAVING_WORLD" then CancelThanks(); active, baseline = false, true
    elseif event == "PLAYER_REGEN_DISABLED" then CancelThanks(); baseline = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        baseline, quietUntil = true, GetTime() + 2
        SafeScan()
    elseif event == "UNIT_AURA" and Public(unit) and unit == "player" then SafeScan() end
end)
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterUnitEvent("UNIT_AURA", "player")

SLASH_THANKSBUFFFOREVER1 = "/tftbf"
SLASH_THANKSBUFFFOREVER2 = "/buffthanks"
SlashCmdList.THANKSBUFFFOREVER = function(msg)
    if not ready then return end
    local command = (msg or ""):upper():match("^%s*(.-)%s*$")
    local db = ThanksForTheBuffForeverDB
    if command == "" or command == "OPTIONS" or command == "SETTINGS" then
        if ns.OpenSettings then ns.OpenSettings() end
    elseif command == "ON" or command == "OFF" then
        ns.SetOption("enabled", command == "ON")
        Message(db.enabled and "Enabled." or "Disabled.")
    elseif command == "GROUP ON" or command == "GROUP OFF" then
        ns.SetOption("group", command == "GROUP ON")
        Message(db.group and "Party and raid buffs included." or "Only players outside your group.")
    elseif allowed[command] then
        ns.SetOption("emote", command)
        Message("Emote: " .. command:lower() .. ".")
    elseif command == "STATUS" then
        Message((db.enabled and "On" or "Off") .. "; emote " .. db.emote:lower() .. "; group " .. (db.group and "on" or "off") .. ".")
        Message("Cooldowns: " .. db.thanksInterval .. " seconds overall, " .. db.playerInterval .. " seconds per player. Last issue: " .. lastIssue)
        Message("Delay before thanks: " .. db.thanksDelay .. " seconds. " .. thanksStatus)
        Message("Detection: " .. detectionStatus)
        Message("Last buff-back check: " .. backStatus)
        if ns.GetClickBuffStatus then Message("Buff helper: " .. ns.GetClickBuffStatus()) end
    else
        Message("/tftbf on | off | thank | cheer | bow | salute | applaud | random")
        Message("/tftbf group on | group off | status")
    end
end
