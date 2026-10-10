from test_behavior import lua

lua.execute('''
ns.SetOption("enabled",true); ns.SetOption("group",true)
ns.SetOption("thanksDelay",0); ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
now=40000; auras={}; event("PLAYER_ENTERING_WORLD"); now=40006
local count=#sent
local offers=0
local originalOffer=ns.OfferBuffBack
ns.OfferBuffBack=function() offers=offers+1 end
for _,source in ipairs({"missing","player","target"}) do
 auras={{name="Honorless Target",spellId=2479,expirationTime=40036,sourceUnit=source~="missing" and source or nil}}
 event("UNIT_AURA","player")
 auras[1].expirationTime=40050; event("UNIT_AURA","player")
 assert(#sent==count and offers==0,"Honorless Target triggered thanks or Buff Back")
end
auras={{name="Localized system effect",spellId=2479,sourceUnit="target"}}
event("UNIT_AURA","player"); assert(#sent==count and offers==0)
auras={{name="Honorless Target",spellId=secret,sourceUnit="target"}}
event("UNIT_AURA","player"); assert(#sent==count and offers==0)
ns.OfferBuffBack=originalOffer
auras={{name="New Forever Buff",spellId=999999,sourceUnit="target",expirationTime=40100}}
event("UNIT_AURA","player"); assert(#sent==count+1,"unlisted helpful buff rejected")
event("UNIT_AURA","player"); assert(#sent==count+1,"unchanged buff thanked again")
auras[1].expirationTime=40200; event("UNIT_AURA","player")
assert(#sent==count+2,"refresh not thanked")
auras={{name="Another new buff",spellId=secret,sourceUnit="target"}}
event("UNIT_AURA","player"); assert(#sent==count+3,"unneeded spell ID blocked thanks")
auras={{name="Self effect",spellId=999998,sourceUnit="player"}}
event("UNIT_AURA","player"); assert(#sent==count+3,"self effect thanked")
auras={{name="Unknown caster",spellId=999997}}
event("UNIT_AURA","player"); assert(#sent==count+3,"unidentified effect thanked")
for _,name in ipairs({"Food","Drink","Well Fed","Ghost","Resurrection Sickness","Swift Brown Steed","Elixir effect","Equipment proc"}) do
 for _,source in ipairs({"missing","unresolved","player"}) do
  auras={{name=name,spellId=999997,sourceUnit=source~="missing" and source or nil}}
  event("UNIT_AURA","player"); assert(#sent==count+3,name.." triggered thanks")
 end
end
auras={buff(nil)}
event("UNIT_AURA","player"); assert(#sent==count+3,"directed thanks became untargeted")
ns.SetOption("directThanks",false); ns.SetOption("emote","CHEER")
auras={}; event("UNIT_AURA","player"); auras={buff(nil)}
event("UNIT_AURA","player"); assert(#sent==count+4 and sent[#sent][1]=="CHEER" and sent[#sent][2]=="none","fallback ignored chosen emote")
auras={{name="Buff1459",spellId=secret}}
auras[1].expirationTime=50000
event("UNIT_AURA","player"); assert(#sent==count+5,"known gift name fallback missing")
''')
print('PASS: arbitrary helpful buffs, refreshes, restricted spell IDs, self and unknown-caster exclusions.')
