from test_behavior import lua

lua.execute('''
EMOTE999_TOKEN="WAVE"; EMOTE999_CMD1="/wave"; EMOTE999_CMD2="/hello"
local db=ThanksForTheBuffForeverDB
assert(ns.SetExtraEmotes(" /wave, HELLO, wave, thank "))
assert(#db.extraEmotes==2 and db.extraEmotes[1]=="WAVE" and db.extraEmotes[2]=="THANK")
assert(not ns.SetExtraEmotes("/say hello")); assert(#db.extraEmotes==2)
assert(not ns.SetExtraEmotes("/run print(1)")); assert(#db.extraEmotes==2)
db.randomEmotes={THANK=true}; ns.SetOption("emote","RANDOM"); ns.SetOption("enabled",true)
local originalRandom=math.random
math.random=function(n) assert(n==2,"duplicate increased random weight"); return 2 end
now=5000; auras={}; event("UNIT_AURA","player")
auras={buff("target")}; event("UNIT_AURA","player")
assert(sent[#sent][1]=="WAVE","extra emote not used")
math.random=originalRandom
event("ADDON_LOADED","ThanksForTheBuffForever"); assert(#db.extraEmotes==2)
assert(ns.SetExtraEmotes("")); assert(#db.extraEmotes==0)
''')
print('PASS: extra-emote aliases, whitespace/slashes, validation, deduplication, random delivery, saved reload and blank clearing.')
