from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.execute('''
now=0; combat=false; auras={}; sent={}; group=false; secret={}
SlashCmdList={}; C_Spell={GetSpellName=function(id) return "Buff"..id end}
C_UnitAuras={GetAuraDataByIndex=function(_,i) return auras[i] end}
function issecretvalue(v) return v == secret end
function GetTime() return now end
function InCombatLockdown() return combat end
function UnitGUID(u)
 if u=="player" then return "Player-Me" end
 if u=="target" then return "Player-Friend" end
 if u=="focus" then return "Player-Other" end
 if u=="party1" and group then return "Player-Friend" end
end
function UnitIsPlayer(u) return u=="player" or u=="target" or u=="focus" end
function DoEmote(e,u) table.insert(sent,{e,u}) end
function print() end
function CreateFrame()
 frame={RegisterEvent=function() end,RegisterUnitEvent=function() end,
 SetScript=function(self,_,f) self.event=f end}; return frame
end
function event(e,u) frame:event(e,u) end
function buff(source,id) return {name="Buff"..(id or 1459),spellId=id or 1459,sourceUnit=source} end
offered={}
ns={OfferBuffBack=function(unit,guid) table.insert(offered,{unit,guid}) end}
''')
for file in ('Buffs.lua', 'ThanksForTheBuffForever.lua'):
    lua.execute('assert(loadstring(...))("ThanksForTheBuffForever",ns)', (root/'ThanksForTheBuffForever'/file).read_text())
lua.execute('''
event("ADDON_LOADED","ThanksForTheBuffForever"); ns.SetOption("thanksDelay",0)
auras={buff("target")}; event("PLAYER_ENTERING_WORLD"); assert(#sent==0)
assert(#offered==0,"login buff offered back")
now=6; event("UNIT_AURA","player"); assert(#sent==0,"login buff thanked")
auras={}; event("UNIT_AURA","player")
auras={buff("target")}; event("UNIT_AURA","player")
assert(#sent==1 and sent[1][1]=="THANK" and sent[1][2]=="target")
assert(#offered==1 and offered[1][1]=="target" and offered[1][2]=="Player-Friend")
auras={}; event("UNIT_AURA","player"); auras={buff("target")}; event("UNIT_AURA","player")
assert(#sent==1,"same caster spam")
auras={buff("target"),buff("focus",1243)}; event("UNIT_AURA","player")
assert(#sent==1,"global cooldown ignored")
now=22; auras={}; event("UNIT_AURA","player"); auras={buff("focus")}; event("UNIT_AURA","player")
assert(#sent==2)
now=120; group=true; auras={}; event("UNIT_AURA","player"); auras={buff("target")}; event("UNIT_AURA","player")
assert(#sent==2,"group member thanked")
SlashCmdList.THANKSBUFFFOREVER("group on")
auras={}; event("UNIT_AURA","player"); auras={buff("target")}; event("UNIT_AURA","player"); assert(#sent==3)
now=240; combat=true; event("PLAYER_REGEN_DISABLED"); auras={buff("focus")}; event("UNIT_AURA","player"); assert(#sent==3)
combat=false; event("PLAYER_REGEN_ENABLED"); now=250; event("UNIT_AURA","player"); assert(#sent==3,"combat buff replayed")
auras={{name=secret,spellId=secret,sourceUnit=secret}}; event("UNIT_AURA","player"); assert(#sent==3)
auras={buff("player"),buff("player",999999)}; event("UNIT_AURA","player"); assert(#sent==3,"self buff")
SlashCmdList.THANKSBUFFFOREVER("off"); auras={buff("focus")}; event("UNIT_AURA","player"); assert(#sent==3)
SlashCmdList.THANKSBUFFFOREVER("on"); event("UNIT_AURA","player"); assert(#sent==3,"enable replayed buff")
SlashCmdList.THANKSBUFFFOREVER("bow"); now=350
auras={}; event("UNIT_AURA","player"); auras={buff("target")}; event("UNIT_AURA","player"); assert(#sent==4 and sent[4][1]=="BOW")
event("PLAYER_LEAVING_WORLD"); auras={buff("focus")}; now=450; event("UNIT_AURA","player"); assert(#sent==4)
event("PLAYER_ENTERING_WORLD"); now=460; event("UNIT_AURA","player"); assert(#sent==4)
ThanksForTheBuffForeverDB={enabled=false,group=true,emote="CHEER"}; event("ADDON_LOADED","ThanksForTheBuffForever"); ns.SetOption("thanksDelay",0)
assert(not ThanksForTheBuffForeverDB.enabled and ThanksForTheBuffForeverDB.group and ThanksForTheBuffForeverDB.emote=="CHEER")
''')
print('PASS: Lua 5.1 load; login/zone/combat baselines; cooldowns; group/self filtering; restricted fields; commands and saved settings.')

lua.execute('''
ThanksForTheBuffForeverDB={enabled=true,group=true,emote="RANDOM",randomEmotes={BOW=true,SALUTE=true}}
event("ADDON_LOADED","ThanksForTheBuffForever"); ns.SetOption("thanksDelay",0)
ns.ToggleEmote("BOW",false); ns.ToggleEmote("SALUTE",false)
assert(ThanksForTheBuffForeverDB.randomEmotes.SALUTE,"last selected emote removed")
now=1000; auras={}; event("UNIT_AURA","player")
for i=1,5 do
 now=now+100; auras={buff("target")}; event("UNIT_AURA","player")
 assert(sent[#sent][1]=="SALUTE","random used unchecked emote")
 auras={}; event("UNIT_AURA","player")
end
event("ADDON_LOADED","ThanksForTheBuffForever"); ns.SetOption("thanksDelay",0)
assert(ThanksForTheBuffForeverDB.randomEmotes.SALUTE and not ThanksForTheBuffForeverDB.randomEmotes.BOW)
-- Restore the fixture expected by settings checks.
ThanksForTheBuffForeverDB={enabled=false,group=true,emote="CHEER"}; event("ADDON_LOADED","ThanksForTheBuffForever"); ns.SetOption("thanksDelay",0)
''')
print('PASS: random selection uses checked pool, preserves it across initialization, and retains at least one emote.')
