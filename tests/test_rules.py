from test_settings import lua, root

lua.execute('assert(loadstring(...))("ThanksForTheBuffForever",ns)', (root/'ThanksForTheBuffForever'/'Rules.lua').read_text(encoding='utf-8'))
lua.execute('''
ns.InitRules()
local db=ThanksForTheBuffForeverDB
function UnitClass() return "Mage","MAGE" end
function UnitRace() return "Gnome","Gnome" end
function UnitSex() return 3 end
assert(ns.SaveRule(nil,"MAGE","ANY","ANY"," /thank, thank "))
assert(#db.rules[1].emotes==1 and db.rules[1].text=="thank")
assert(ns.SaveRule(nil,"MAGE","3","Gnome","wave"))
assert(ns.RuleEmote("target")=="WAVE","specific rule lost")
function UnitSex() return 2 end
assert(ns.RuleEmote("target")=="THANK","class fallback lost")
function UnitSex() return secret end
assert(ns.RuleEmote("target")=="THANK","restricted gender matched")
function UnitClass() return "Priest","PRIEST" end
assert(ns.RuleEmote("target")==nil,"unmatched rule overrode default")
assert(not ns.SaveRule(nil,"MAGE","ANY","ANY","bow"),"duplicate accepted")
assert(not ns.SaveRule(nil,"PRIEST","ANY","ANY","notanemote"))
assert(not ns.SaveRule(nil,"PRIEST","ANY","ANY"," , "))
assert(not ns.SaveRule(nil,"INVALID","ANY","ANY","thank"))
ns.InitRules(); assert(#db.rules==2,"saved rules lost")
assert(ns.SaveRule(1,"PRIEST","ANY","ANY","bow"))
ns.SetOption("enabled",true); ns.SetOption("group",true); ns.SetOption("thanksDelay",0)
ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
now=50000; auras={}; event("PLAYER_ENTERING_WORLD"); now=50006
auras={buff("target")}; event("UNIT_AURA","player")
assert(sent[#sent][1]=="BOW","real thanks path ignored rule")
ns.DeleteRule(2); assert(#db.rules==1)
-- Open from settings and reuse the same window; add/edit/remove through UI callbacks.
local advanced
for _,widget in ipairs(widgets) do if widget.text=="Advanced" then advanced=widget end end
assert(advanced); advanced.scripts.OnClick()
assert(ThanksForTheBuffForeverAdvanced.shown)
local count=#widgets; ns.OpenAdvanced(); assert(#widgets==count,"duplicate window")
local input,add,editButton,remove
for _,widget in ipairs(widgets) do
 if widget.kind=="EditBox" then input=widget end
 if widget.text=="Add rule" then add=widget end
 if widget.text=="Edit" and not editButton then editButton=widget end
 if widget.text=="Remove" and not remove then remove=widget end
end
input:SetText("wave, bow"); add.scripts.OnClick(); assert(#db.rules==2)
editButton.scripts.OnClick(); input:SetText("cheer"); add.scripts.OnClick()
assert(db.rules[1].text=="cheer")
remove.scripts.OnClick(); assert(#db.rules==1)
assert(#UISpecialFrames==1)
''')
print('PASS: class/gender/race matching, specificity, fallback, validation, save/reload, actual thanks selection and advanced UI add/edit/remove/reuse.')
