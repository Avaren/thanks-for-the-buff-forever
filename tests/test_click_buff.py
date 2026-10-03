from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute(r'''
ns={}; frames={}; now=10; combat=false; hovered=false; mine="MAGE"
known={[1459]=true,[1460]=true,[19740]=true,[19742]=true}
units={player={guid="me",class="MAGE"},nameplate1={guid="friend",class="PRIEST"}}
units.target=units.nameplate1
ThanksForTheBuffForeverDB={clickBuff=true}
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetAttribute(k,v) assert(not combat,"insecure combat write"); self.attrs[k]=v end
function methods:Show() assert(not combat); self.shown=true end
function methods:Hide() assert(not combat); self.shown=false end
function methods:IsShown() return self.shown end
function methods:IsMouseOver() return hovered end
function methods:GetEffectiveScale() return 1 end
function methods:GetRect() return rawget(self,"left") or 300,rawget(self,"bottom") or 400,rawget(self,"width") or 122,rawget(self,"height") or 21 end
function methods:SetPoint(...) self.point={...} end
function methods:SetSize(w,h) self.width=w; self.height=h end
function methods:CreateTexture() return CreateFrame() end
function methods:CreateMaskTexture() return CreateFrame() end
function methods:CreateFontString() return CreateFrame() end
function methods:SetText(text) self.text=text end
setmetatable(methods,{__index=function() return function() end end})
function CreateFrame(_,name,_,template)
 local f=setmetatable({scripts={},attrs={},shown=true,template=template},{__index=methods})
 table.insert(frames,f); if name then _G[name]=f end; return f
end
UIParent=CreateFrame(); plate=CreateFrame(); plate.namePlateUnitToken="nameplate1"
TargetFrame=CreateFrame(); container=CreateFrame(); auraFrame=CreateFrame(); auraFrame.width=21
TargetFrame.GetAuraContainer=function() return container end
container.buffAuraGroup={GetFramesByIndex=function() return {auraFrame} end}
container.debuffAuraGroup={GetFramesByIndex=function() return {} end}
container.GetFlowLayoutMaximumLineSize=function() return 122 end
C_NamePlate={GetNamePlates=function() return {plate} end}
C_SpellBook={IsSpellKnown=function(id) return known[id] end}
C_Spell={GetSpellInfo=function(id) return {name="Spell"..id,iconID=id} end}
auras={}; secret={}
function issecretvalue(v) return v==secret end
C_UnitAuras={GetAuraDataByIndex=function(unit,index) return (auras[unit] or {})[index] end}
GameTooltip={IsOwned=function() return false end,Hide=function() end}
function RegisterStateDriver(f,state,driver) f[state.."Driver"]=driver end
function UnitGUID(u) return units[u] and units[u].guid end
function UnitClass(u) return "Class", u=="player" and mine or (units[u] and units[u].class) end
function UnitIsPlayer(u) return units[u] ~= nil and not units[u].npc end
function UnitCanAssist(_,u) return units[u] and not units[u].enemy end
function UnitIsDeadOrGhost(u) return units[u] and units[u].dead end
function UnitIsUnit(a,b) return UnitGUID(a)==UnitGUID(b) end
function UnitName(u) return UnitGUID(u) end
function InCombatLockdown() return combat end
function GetTime() return now end
''')
lua.execute('assert(loadstring(...))("ThanksForTheBuffForever",ns)', (root/'ThanksForTheBuffForever'/'ClickBuff.lua').read_text(encoding='utf-8'))
lua.execute('''
events=frames[#frames]; events.scripts.OnEvent()
b=ThanksForTheBuffForeverClickBuff
assert(b.shown and b.attrs.unit=="target" and b.attrs.spell=="Spell1460")
assert(b.width==36 and b.point[4]==324 and b.point[5]==385,"next buff slot")
assert(b.combatDriver=="[combat] yes; no")
m=ThanksForTheBuffForeverMouseover
units.mouseover=nil; m.scripts.PreClick(m); assert(m.attrs.type1==nil,"binding fell back to target")
units.mouseover=units.target; m.scripts.PreClick(m)
assert(m.attrs.unit=="mouseover" and m.attrs.spell=="Spell1460" and m.attrs.type1=="spell")
auras.mouseover={{name="Spell1460",spellId=1460}}; m.scripts.PreClick(m); assert(m.attrs.type1==nil)
auras.mouseover={}; units.mouseover={guid="enemy",class="PRIEST",enemy=true}
m.scripts.PreClick(m); assert(m.attrs.type1==nil)
units.mouseover={guid="dead",class="PRIEST",dead=true}; m.scripts.PreClick(m); assert(m.attrs.type1==nil)
units.mouseover=units.target; auras.mouseover={{name=secret,spellId=secret}}
m.scripts.PreClick(m); assert(m.attrs.type1==nil)
auras.mouseover={}; combat=true; m.scripts.PreClick(m); combat=false
m.scripts.PreClick(m); assert(m.attrs.type1=="spell")

auras.target={{name="Another rank",spellId=1459}}
ns.RefreshClickBuff(); assert(not b.shown and b.attrs.type1==nil)
auras.target={}; ns.RefreshClickBuff(); assert(b.shown)
auras.target={{name="Spell1460",spellId=999999}}
b.scripts.PreClick(b); assert(b.attrs.type1==nil,"late buff before click")
ns.RefreshClickBuff(); assert(not b.shown)
auras.target={{name="Unrelated",spellId=999999}}
ns.RefreshClickBuff(); assert(b.shown)
auras.target={{name=secret,spellId=secret}}
ns.RefreshClickBuff(); assert(not b.shown)
auras.target={}; ns.RefreshClickBuff(); assert(b.shown)
units.target={guid="replacement",class="PRIEST"}
b.scripts.PreClick(b); assert(b.attrs.type1==nil,"target switched before click")
ns.RefreshClickBuff(); assert(b.shown)
units.target.enemy=true; ns.RefreshClickBuff(); assert(not b.shown)
units.target.enemy=false; units.target.dead=true; ns.RefreshClickBuff(); assert(not b.shown)
units.target.dead=false; units.target.class="WARRIOR"; ns.RefreshClickBuff(); assert(b.shown,"warrior excluded")
units.target.class="ROGUE"; ns.RefreshClickBuff(); assert(b.shown,"rogue excluded")
units.target=units.player; ns.RefreshClickBuff(); assert(b.shown,"self excluded")
units.target={guid="replacement",class="PRIEST"}; ns.RefreshClickBuff()
assert(ns.GetClickBuffStatus():find("Offering"))
auras.target={{name="Spell1460",spellId=1460}}; ns.RefreshClickBuff()
assert(not b.shown and ns.GetClickBuffStatus():find("already has"))
auras.target={}; ns.RefreshClickBuff()
units.target.class="WARRIOR"; mine="PALADIN"; events.scripts.OnEvent(); assert(b.attrs.spell=="Spell19740")
units.target.class="PRIEST"; events.scripts.OnEvent(); assert(b.attrs.spell=="Spell19742")
-- Row wrapping, collision avoidance, empty row, top placement and frame visibility.
auraFrame.left=396; ns.RefreshClickBuff(); assert(b.point[4]==300 and b.point[5]==361)
debuff=CreateFrame(); debuff.left=300; debuff.bottom=376; debuff.width=21
container.debuffAuraGroup.GetFramesByIndex=function() return {debuff} end
ns.RefreshClickBuff(); assert(b.point[4]==261,"covered a real debuff")
container.debuffAuraGroup.GetFramesByIndex=function() return {} end
container.buffAuraGroup.GetFramesByIndex=function() return {} end
ns.RefreshClickBuff(); assert(b.point[4]==300 and b.point[5]==385)
TargetFrame.buffsOnTop=true; ns.RefreshClickBuff(); assert(b.point[5]==400)
TargetFrame.shown=false; ns.RefreshClickBuff(); assert(not b.shown)
TargetFrame.shown=true; ns.RefreshClickBuff(); assert(b.shown)
ThanksForTheBuffForeverDB.clickBuff=false; ns.RefreshClickBuff(); assert(not b.shown)
ThanksForTheBuffForeverDB.clickBuff=true; ns.RefreshClickBuff(); assert(b.shown)
combat=true; ns.RefreshClickBuff(); b.scripts.PreClick(b); events.scripts.OnEvent()
combat=false; units.target=nil; units.mouseover=units.nameplate1
ns.RefreshClickBuff(); assert(not b.shown,"mouseover still activates helper")
units.target=units.nameplate1; mine="ROGUE"; events.scripts.OnEvent(); assert(not b.shown)
''')
print('PASS: target-only selection, missing buffs, rank matching, target-switch protection, aura-row placement/wrapping/collision, hidden target frame, class presets, settings and no insecure combat writes. Live rendering and casting remain unverified.')
