from test_behavior import lua

lua.execute('''
ns.SetOption("enabled",true); ns.SetOption("group",true)
ns.SetOption("directThanks",true); ns.SetOption("thanksDelay",0)
ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
now=60000; auras={}; event("PLAYER_ENTERING_WORLD"); now=60006
local count=#sent; local offers=#offered
local oldGUID,oldPlayer=UnitGUID,UnitIsPlayer
UnitGUID=function(u) if u=="nameplate7" then return "Player-Giver" end return oldGUID(u) end
UnitIsPlayer=function(u) return u=="nameplate7" or oldPlayer(u) end
local calls=0
C_UnitAuras.GetAuraCasterGUID=function(unit,id)
 assert(unit=="player" and id==101); calls=calls+1; return "Player-Giver"
end
UnitTokenFromGUID=function(guid) assert(guid=="Player-Giver"); return "nameplate7" end
ns.RuleEmote=function(unit) assert(unit=="nameplate7"); return "LAUGH",1 end
local function apply(source)
 auras={}; event("UNIT_AURA","player")
 auras={{name="Buff1459",spellId=1459,auraInstanceID=101,sourceUnit=source}}
 event("UNIT_AURA","player")
end
apply(nil)
assert(#sent==count+1 and sent[#sent][1]=="LAUGH" and sent[#sent][2]=="nameplate7")
assert(#offered==offers+1 and offered[#offered][2]=="Player-Giver")
event("UNIT_AURA","player"); assert(#sent==count+1,"duplicate thanks")
apply("unresolved"); assert(#sent==count+2,"stale source not recovered")
UnitTokenFromGUID=function() return "target" end
apply(nil); assert(#sent==count+3 and sent[#sent][2]=="nameplate7","GUID mismatch not corrected by scan")
UnitTokenFromGUID=nil
apply(nil); assert(#sent==count+4,"manual GUID scan failed without native resolver")
UnitGUID=oldGUID; UnitIsPlayer=oldPlayer
apply(nil); assert(#sent==count+4,"unknown caster thanked")
C_UnitAuras.GetAuraCasterGUID=function() return secret end
apply(nil); assert(#sent==count+4,"restricted GUID used")
C_UnitAuras.GetAuraCasterGUID=function() error("unavailable") end
apply(nil); assert(#sent==count+4,"lookup error triggered thanks")
C_UnitAuras.GetAuraCasterGUID=function() error("must not query restricted instance") end
auras={{name="Buff1459",spellId=1459,auraInstanceID=secret}}
event("UNIT_AURA","player"); assert(#sent==count+4)
C_UnitAuras.GetAuraCasterGUID=function() return "Player-Me" end
apply(nil); assert(#sent==count+4,"self GUID thanked")
auras={{name="Campfire Nearby",spellId=1283391,auraInstanceID=101,sourceUnit="target"}}
event("UNIT_AURA","player"); assert(#sent==count+4,"campfire thanked")
assert(calls>=4)
''')
print('PASS: aura GUID recovery, rule emote and Buff Back identity, stale/mismatched tokens, missing APIs, restricted data, self and campfire exclusion.')
