from test_behavior import lua, root

lua.execute('''
UIParent={}; UISpecialFrames={}; widgets={}
function UIDropDownMenu_SetWidth(f,w) f.width=w end
function UIDropDownMenu_SetSelectedValue(f,v) f.selected=v end
function UIDropDownMenu_SetText(f,t) f.text=t end
function UIDropDownMenu_Initialize(f,fn) f.initialize=fn end
function UIDropDownMenu_CreateInfo() return {} end
local menu
function UIDropDownMenu_AddButton(info) table.insert(menu,info) end
function OpenTimingMenu(f) menu={}; f.initialize(); return menu end
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetText(t) self.text=t end
function methods:GetText() return self.text end
function methods:SetChecked(v) self.checked=v end
function methods:GetChecked() return self.checked end
function methods:Show() self.shown=true; if self.scripts.OnShow then self.scripts.OnShow(self) end end
function methods:CreateFontString() return CreateFrame("FontString") end
setmetatable(methods,{__index=function() return function() end end})
function CreateFrame(kind,name,parent,template)
 local f=setmetatable({scripts={},kind=kind,name=name,template=template},{__index=methods})
 table.insert(widgets,f)
 if name then _G[name]=f end
 if template=="BasicFrameTemplateWithInset" then f.TitleText=CreateFrame("FontString") end
 return f
end
Settings={RegisterCanvasLayoutCategory=function(panel,name) registeredPanel=panel; panel.GetID=function() return 123 end; return panel end,
 OpenToCategory=function(id) openedCategory=id; registeredPanel:Show() end,
 RegisterAddOnCategory=function(category) registeredCategory=category end}
''')
lua.execute('assert(loadstring(...))("ThanksForTheBuffForever",ns)', (root/'ThanksForTheBuffForever'/'Settings.lua').read_text())
lua.execute('''
widgets[1].scripts.OnEvent(widgets[1],"PLAYER_LOGIN")
assert(registeredPanel and registeredCategory==registeredPanel)
SlashCmdList.THANKSBUFFFOREVER("")
assert(ThanksForTheBuffForeverSettings.shown)
assert(#UISpecialFrames==0 and openedCategory==123,"slash did not open native category")
local checks={}
for _,w in ipairs(widgets) do if w.kind=="CheckButton" then table.insert(checks,w) end end
assert(#checks==15)
assert(checks[1].checked==false and checks[2].checked==true,"saved preferences not reflected")
checks[1]:SetChecked(true); checks[1].scripts.OnClick(checks[1]); assert(ThanksForTheBuffForeverDB.enabled)
checks[3]:SetChecked(true); checks[3].scripts.OnClick(checks[3]); assert(ThanksForTheBuffForeverDB.emote=="RANDOM")
assert(checks[3].checked and checks[5].checked,"random should show pool choices")
checks[5]:SetChecked(false); checks[5].scripts.OnClick(checks[5])
assert(ThanksForTheBuffForeverDB.emote=="RANDOM" and not ThanksForTheBuffForeverDB.randomEmotes.CHEER)
checks[3]:SetChecked(false); checks[3].scripts.OnClick(checks[3])
assert(ThanksForTheBuffForeverDB.emote=="CHEER" and checks[5].checked,"random off lost single choice")
checks[3]:SetChecked(true); checks[3].scripts.OnClick(checks[3])
assert(not checks[5].checked,"random pool was not saved")
SlashCmdList.THANKSBUFFFOREVER("off"); assert(not checks[1].checked)
SlashCmdList.THANKSBUFFFOREVER("bow"); assert(checks[6].checked and not checks[3].checked)
SlashCmdList.THANKSBUFFFOREVER("group off"); assert(not checks[2].checked)
for i,token in ipairs({"WAVE","NOD","KISS","DANCE"}) do
 SlashCmdList.THANKSBUFFFOREVER(token)
 assert(ThanksForTheBuffForeverDB.emote==token and checks[8+i].checked,"new choice unavailable")
end
local count=#widgets
SlashCmdList.THANKSBUFFFOREVER(""); assert(#widgets==count and #UISpecialFrames==0,"duplicate settings window")
for _,w in ipairs(widgets) do assert(w.template~="BasicFrameTemplateWithInset","standalone window created") end
checks[13]:SetChecked(false); checks[13].scripts.OnClick(checks[13]); assert(ThanksForTheBuffForeverDB.clickBuff==false)
for _,key in ipairs({"thanksDelay","thanksInterval","playerInterval"}) do
 local field=_G["ThanksForTheBuffForeverTiming_"..key]
 assert(field and field.template=="UIDropDownMenuTemplate")
 ns.SetOption(key,22)
 assert(field.text=="22 seconds (saved)","existing value hidden or changed")
 local items=OpenTimingMenu(field)
 assert(#items==5)
 for i,item in ipairs(items) do
  assert(item.value==i)
  item.func()
  assert(ThanksForTheBuffForeverDB[key]==i and field.selected==i,"selection did not save immediately")
 end
 ns.RefreshSettings(); assert(field.text=="5 seconds")
end
''')
lua.execute('''
EMOTE999_TOKEN="WAVE"; EMOTE999_CMD1="/wave"
local edit
for _,w in ipairs(widgets) do if w.kind=="EditBox" and not w.scripts.OnEditFocusLost then edit=w end end
assert(edit)
edit:SetText("wave"); edit.scripts.OnEnterPressed(edit)
assert(ThanksForTheBuffForeverDB.extraEmotes[1]=="WAVE")
edit:SetText("notarealemote"); edit.scripts.OnEnterPressed(edit)
assert(ThanksForTheBuffForeverDB.extraEmoteText=="/wave","invalid input replaced saved list")
edit.scripts.OnEscapePressed(edit); assert(edit:GetText()=="/wave")
''')
print('PASS: extra-emote field saves on Enter, rejects unknown commands, and restores saved text on Escape.')
print('PASS: native settings category, slash navigation, panel reuse, saved values, enable click, exclusive emote selection, and slash/GUI synchronization. Layout remains unverified in game.')
