from test_behavior import lua

lua.execute('''
SlashCmdList.THANKSBUFFFOREVER("log clear")
ns.SetOption("enabled",true); ns.SetOption("group",true)
ns.SetOption("thanksDelay",0); ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
now=20000; auras={}; event("PLAYER_ENTERING_WORLD"); now=20006
local function contains(text)
 for _,line in ipairs(ThanksForTheBuffForeverDB.log) do
  if line:find(text,1,true) then return true end
 end
end
auras={buff("target")}; event("UNIT_AURA","player")
assert(contains("[QUEUE]") and contains("[EMOTE_REQUEST]") and contains("delivery not confirmed"))
auras={}; event("UNIT_AURA","player")
local oldEmote=DoEmote
DoEmote=function() error("test emote rejection") end
auras={buff("target")}; event("UNIT_AURA","player")
assert(contains("[EMOTE_ERROR]") and contains("test emote rejection"))
DoEmote=oldEmote
frame:event("UI_ERROR_MESSAGE",123,"Target is too low level")
assert(contains("Target is too low level"))
local oldRead=C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex=function() error("test aura failure") end
event("UNIT_AURA","player")
assert(contains("[SCAN_ERROR]") and contains("test aura failure"))
C_UnitAuras.GetAuraDataByIndex=oldRead
ns.Log("SECRET",secret); assert(contains("<restricted>"))
for i=1,450 do ns.Log("BOUND",i) end
assert(#ThanksForTheBuffForeverDB.log==400)
event("ADDON_LOADED","ThanksForTheBuffForever")
assert(contains("[BOUND]") and contains("[INIT]"),"log lost on initialization")
SlashCmdList.THANKSBUFFFOREVER("log off")
local last=ThanksForTheBuffForeverDB.log[400]
ns.Log("IGNORED","paused"); assert(ThanksForTheBuffForeverDB.log[400]==last)
SlashCmdList.THANKSBUFFFOREVER("log on")
assert(contains("[LOGGING]"))
SlashCmdList.THANKSBUFFFOREVER("log")
SlashCmdList.THANKSBUFFFOREVER("log clear")
assert(#ThanksForTheBuffForeverDB.log==0)
''')
print('PASS: logged requests/errors, restricted-value handling, 400-entry cap, persistence, pause and clear.')

