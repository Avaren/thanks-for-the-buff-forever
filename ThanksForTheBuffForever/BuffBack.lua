local _, ns = ...
local button, pending, elapsed
elapsed = 0
local function Public(v) return not issecretvalue or not issecretvalue(v) end
local function Resolve()
    if not pending or GetTime() >= pending.expires then pending=nil; return end
    local function Match(unit)
        local guid = UnitGUID(unit)
        return Public(guid) and guid == pending.guid
    end
    for _, unit in ipairs({pending.source,"target","focus","mouseover"}) do
        if Match(unit) then return unit end
    end
    for i=1,40 do
        if i<=4 and Match("party"..i) then return "party"..i end
        if Match("raid"..i) then return "raid"..i end
        if Match("nameplate"..i) then return "nameplate"..i end
    end
end
local function Hide()
    if button and not InCombatLockdown() then
        button:SetAttribute("type1",nil)
        button:Hide()
    end
end
local function Prepare()
    local unit = Resolve()
    local spell = unit and ns.GetMissingBuff(unit)
    if not spell then return end
    button:SetAttribute("unit",unit)
    button:SetAttribute("spell",spell.castName)
    -- One hardware click selects the GUID-checked caster and buffs that unit.
    local selectTarget = ThanksForTheBuffForeverDB.targetBuffBack ~= false and ("/target [@" .. unit .. ",help,nodead]\n") or ""
    button:SetAttribute("macrotext1", selectTarget .. "/cast [@" .. unit .. ",help,nodead] " .. spell.castName)
    button:SetAttribute("type1","macro")
    return unit,spell
end
local function Refresh()
    if not button or InCombatLockdown() then return end
    button:SetAttribute("type1",nil)
    local ok,unit,spell = pcall(Prepare)
    if not ok or not unit then Hide(); return end
    button.icon:SetTexture(spell.icon)
    button:Show()
end
function ns.OfferBuffBack(unit,guid)
    if InCombatLockdown() or not Public(unit) or type(unit)~="string"
        or not Public(guid) or type(guid)~="string" then return end
    -- Keep a visible offer stable even if another player buffs us while clicking.
    if pending and GetTime()<pending.expires then return "Keeping the existing ten-second offer." end
    local spell, reason = ns.GetMissingBuff(unit)
    if not spell then return reason or "No missing supported buff available for this player." end
    pending={source=unit,guid=guid,expires=GetTime()+10}
    Refresh()
    return "Offered " .. spell.name .. " for ten seconds."
end
local events=CreateFrame("Frame")
for _,event in ipairs({"PLAYER_LOGIN","PLAYER_REGEN_DISABLED","PLAYER_LEAVING_WORLD"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent",function(_,event)
    if event~="PLAYER_LOGIN" then pending=nil; Hide(); return end
    if button or InCombatLockdown() then return end
    local holder=CreateFrame("Frame",nil,UIParent,"SecureHandlerStateTemplate")
    holder:SetAllPoints(UIParent)
    RegisterStateDriver(holder,"visibility","[combat] hide; show")
    button=CreateFrame("Button","ThanksForTheBuffForeverBuffBack",holder,
        "SecureActionButtonTemplate,SecureHandlerStateTemplate")
    button:SetSize(36,36)
    button:SetPoint("CENTER",UIParent,"CENTER",0,-180)
    button:SetClampedToScreen(true)
    button:SetFrameStrata("DIALOG")
    button:RegisterForClicks("AnyDown","AnyUp")
    button:SetAttribute("checkselfcast",false)
    button:SetAttribute("checkfocuscast",false)
    button:SetAttribute("checkmouseovercast",false)
    button:SetAttribute("_onstate-combat",[[if newstate == "yes" then self:SetAttribute("type1",nil) end]])
    RegisterStateDriver(button,"combat","[combat] yes; no")
    ns.StyleBuffButton(button)
    button:SetScript("OnEnter",function(self)
        local unit = Resolve()
        local spell = unit and ns.GetMissingBuff(unit)
        if not spell then return end
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
        GameTooltip:SetText(spell.castName,1,1,1)
        GameTooltip:AddLine("Buff back: " .. (UnitName(unit) or "player"),1,.82,0)
        GameTooltip:AddLine((ThanksForTheBuffForeverDB.targetBuffBack ~= false and "Click to target and buff. " or "Click to buff. ") .. math.ceil(pending.expires-GetTime()) .. " seconds left.",.65,.75,.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function() GameTooltip:Hide() end)
    button:HookScript("OnHide",function() if GameTooltip:IsOwned(button) then GameTooltip:Hide() end end)
    button:SetScript("PreClick",function(self)
        if InCombatLockdown() then return end
        self:SetAttribute("type1",nil)
        local ok,unit=pcall(Prepare)
        if not ok or not unit then Hide() end
    end)
    button:Hide()
end)
events:SetScript("OnUpdate",function(_,dt)
    elapsed=elapsed+dt
    if elapsed<.1 then return end
    elapsed=0
    Refresh()
end)
