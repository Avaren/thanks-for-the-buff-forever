from test_behavior import lua, root

lua.execute('''
UIParent={}; UISpecialFrames={}; widgets={}
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetText(t) self.text=t end
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
Settings={RegisterCanvasLayoutCategory=function(panel,name) registeredPanel=panel; return panel end,
 RegisterAddOnCategory=function(category) registeredCategory=category end}
''')
lua.execute('assert(loadstring(...))("ThanksForTheBuffForever",ns)', (root/'ThanksForTheBuffForever'/'Settings.lua').read_text())
lua.execute('''
widgets[1].scripts.OnEvent(widgets[1],"PLAYER_LOGIN")
assert(registeredPanel and registeredCategory==registeredPanel)
SlashCmdList.THANKSBUFFFOREVER("")
assert(ThanksForTheBuffForeverSettings.shown)
assert(#UISpecialFrames==1)
local checks={}
for _,w in ipairs(widgets) do if w.kind=="CheckButton" then table.insert(checks,w) end end
assert(#checks==8)
assert(checks[1].checked==false and checks[2].checked==true,"saved preferences not reflected")
checks[1]:SetChecked(true); checks[1].scripts.OnClick(checks[1]); assert(ThanksForTheBuffForeverDB.enabled)
checks[3]:SetChecked(true); checks[3].scripts.OnClick(checks[3]); assert(ThanksForTheBuffForeverDB.emote=="RANDOM")
assert(checks[3].checked and not checks[5].checked,"emote choices not exclusive")
SlashCmdList.THANKSBUFFFOREVER("off"); assert(not checks[1].checked)
SlashCmdList.THANKSBUFFFOREVER("bow"); assert(checks[6].checked and not checks[3].checked)
SlashCmdList.THANKSBUFFFOREVER("group off"); assert(not checks[2].checked)
SlashCmdList.THANKSBUFFFOREVER(""); assert(#UISpecialFrames==1,"window duplicated")
''')
print('PASS: settings entry, window reuse, saved values, enable click, exclusive emote selection, and slash/GUI synchronization. Layout remains unverified in game.')
