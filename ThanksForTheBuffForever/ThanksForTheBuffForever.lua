local addonName, ns = ...
local frame = CreateFrame("Frame")
local seen, cooldowns, names, ids = {}, {}, {}, {}
local ready, baseline, active = false, true, false
local quietUntil, nextThanks = 0, 0
local lastIssue = "none"
local emotes = { "THANK", "CHEER", "BOW", "SALUTE", "APPLAUD" }
local allowed = { THANK=true, CHEER=true, BOW=true, SALUTE=true, APPLAUD=true, RANDOM=true }

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

local function Thank(unit, guid, now)
    local db = ThanksForTheBuffForeverDB
    if not db.enabled or now < nextThanks or (cooldowns[guid] and now < cooldowns[guid]) then return end
    if not db.group and IsGroupMember(guid) then return end
    if C_ChatInfo and C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then return end
    -- Only use a currently resolvable unit. Names alone can produce an untargeted emote.
    local current = UnitGUID(unit)
    if not Public(current) or current ~= guid then return end
    if type(DoEmote) ~= "function" then
        lastIssue = "DoEmote is unavailable on this client."
        return
    end
    local emote = db.emote == "RANDOM" and emotes[math.random(#emotes)] or db.emote
    -- Consume the cooldown even if the client rejects the emote; never retry in a loop.
    cooldowns[guid], nextThanks = now + 90, now + 15
    local ok = pcall(DoEmote, emote, unit)
    if not ok then lastIssue = "The client blocked an emote. Try again out of combat." end
end

local function Scan()
    local now = GetTime()
    local current = {}
    for index=1,255 do
        local aura = GetAura(index)
        if not Public(aura) then break end
        if not aura then break end
        local name, spellId, unit = aura.name, aura.spellId, aura.sourceUnit
        if PlainString(name) and Public(spellId) and PlainString(unit) then
            local isPlayer = UnitIsPlayer(unit)
            local guid, own = UnitGUID(unit), UnitGUID("player")
            if Public(isPlayer) and isPlayer and PlainString(guid) and PlainString(own) and guid ~= own then
                if ids[spellId] or names[name] then
                    local key = guid .. ":" .. name
                    current[key] = true
                    if not baseline and now >= quietUntil and not seen[key] then Thank(unit, guid, now) end
                end
            end
        end
    end
    seen, baseline = current, false
    for guid, expires in pairs(cooldowns) do
        if expires <= now then cooldowns[guid] = nil end
    end
end

local function SafeScan()
    if not ready or not active then return end
    if InCombatLockdown() then baseline = true; return end
    local ok = pcall(Scan)
    if not ok then
        baseline = true
        lastIssue = "Buff data was unavailable or restricted; skipped this update."
    end
end

local function Init()
    if type(ThanksForTheBuffForeverDB) ~= "table" then ThanksForTheBuffForeverDB = {} end
    local db = ThanksForTheBuffForeverDB
    if type(db.enabled) ~= "boolean" then db.enabled = true end
    if type(db.group) ~= "boolean" then db.group = false end
    if type(db.emote) ~= "string" or not allowed[db.emote] then db.emote = "THANK" end
    BuildBuffs()
    ready = true
end

frame:SetScript("OnEvent", function(_, event, unit)
    if event == "ADDON_LOADED" and unit == addonName then Init()
    elseif event == "PLAYER_ENTERING_WORLD" then
        active, baseline, quietUntil = true, true, GetTime() + 5
        SafeScan()
    elseif event == "PLAYER_LEAVING_WORLD" then active, baseline = false, true
    elseif event == "PLAYER_REGEN_DISABLED" then baseline = true
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
    if command == "ON" or command == "OFF" then
        db.enabled = command == "ON"
        baseline = true
        SafeScan()
        Message(db.enabled and "Enabled." or "Disabled.")
    elseif command == "GROUP ON" or command == "GROUP OFF" then
        db.group = command == "GROUP ON"
        Message(db.group and "Party and raid buffs included." or "Only players outside your group.")
    elseif allowed[command] then
        db.emote = command
        Message("Emote: " .. command:lower() .. ".")
    elseif command == "STATUS" then
        Message((db.enabled and "On" or "Off") .. "; emote " .. db.emote:lower() .. "; group " .. (db.group and "on" or "off") .. ".")
        Message("Cooldowns: 15 seconds overall, 90 seconds per player. Last issue: " .. lastIssue)
    else
        Message("/tftbf on | off | thank | cheer | bow | salute | applaud | random")
        Message("/tftbf group on | group off | status")
    end
end
