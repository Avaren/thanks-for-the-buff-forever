from test_behavior import lua

lua.execute('''
ns.SetOption("enabled",true); ns.SetOption("group",true)
ns.SetOption("thanksDelay",0); ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
now=10000; auras={}; event("UNIT_AURA","player")
local count=#sent
auras={buff("target")}; auras[1].expirationTime=11800
event("UNIT_AURA","player"); assert(#sent==count+1)
event("UNIT_AURA","player"); assert(#sent==count+1,"unchanged aura thanked twice")
auras[1].expirationTime=11800.1
event("UNIT_AURA","player"); assert(#sent==count+1,"tiny timing change thanked")
now=10010; auras[1].expirationTime=11810
event("UNIT_AURA","player"); assert(#sent==count+2,"refreshed buff not thanked")
event("UNIT_AURA","player"); assert(#sent==count+2,"refresh thanked twice")
auras[1].expirationTime=secret
event("UNIT_AURA","player"); assert(#sent==count+2,"restricted time thanked")
event("PLAYER_ENTERING_WORLD"); now=10020
event("UNIT_AURA","player"); assert(#sent==count+2,"login buff replayed")
''')
print('PASS: buff refresh detection, duplicate suppression, restricted expiration and login baseline.')
