from test_behavior import lua
lua.execute('''
local db=ThanksForTheBuffForeverDB
local timers={}
C_Timer={After=function(delay,fn) assert(delay==2); timers[#timers+1]=fn end}
ns.SetOption("enabled",true); ns.SetOption("group",true)
ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0); ns.SetOption("thanksDelay",2)
now=9000; auras={}; event("UNIT_AURA","player")
local count=#sent
auras={buff("target")}; event("UNIT_AURA","player")
assert(#sent==count and #timers==1,"thanks sent before delay")
auras={buff("target"),buff("target",1243)}; event("UNIT_AURA","player")
assert(#timers==1,"same player queued twice")
now=9002; timers[1](); assert(#sent==count+1)
local function queue()
 auras={}; event("UNIT_AURA","player"); auras={buff("target")}; event("UNIT_AURA","player")
end
queue(); ns.SetOption("enabled",false); ns.SetOption("enabled",true)
timers[#timers](); assert(#sent==count+1,"disabled pending thanks survived")
queue(); event("PLAYER_REGEN_DISABLED"); timers[#timers](); assert(#sent==count+1)
now=9010; event("PLAYER_REGEN_ENABLED"); now=9013; queue()
event("PLAYER_LEAVING_WORLD"); timers[#timers](); assert(#sent==count+1)
event("PLAYER_ENTERING_WORLD"); now=9020; queue()
group=false -- No alternate party token for the unavailable-caster case.
local oldGUID=UnitGUID; UnitGUID=function(u) if u=="target" then return "Changed" end return oldGUID(u) end
timers[#timers](); assert(#sent==count+1,"directed thanks sent after caster disappeared"); UnitGUID=oldGUID
-- A passing caster's unit token can change while the configured delay runs.
queue()
UnitGUID=function(u)
 if u=="target" then return "Changed" end
 if u=="nameplate7" then return "Player-Friend" end
 return oldGUID(u)
end
timers[#timers](); assert(#sent==count+2 and sent[#sent][2]=="nameplate7","lost caster after token changed")
UnitGUID=oldGUID
assert(ns.SetExtraEmotes(" thank, /bow ")); assert(db.extraEmoteText=="/thank, /bow")
ThanksForTheBuffForeverDB={}; event("ADDON_LOADED","ThanksForTheBuffForever"); assert(ThanksForTheBuffForeverDB.thanksDelay==2)
''')
print("PASS: delayed thanks, deduplication, cancellation, target validation, default delay and automatic slashes.")
