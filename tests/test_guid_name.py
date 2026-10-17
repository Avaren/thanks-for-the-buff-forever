from test_behavior import lua

lua.execute('''
ns.SetOption("enabled",true); ns.SetOption("group",false)
ns.SetOption("directThanks",true); ns.SetOption("thanksDelay",1)
ns.SetOption("thanksInterval",0); ns.SetOption("playerInterval",0)
local timers={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
now=60000; auras={}; event("PLAYER_ENTERING_WORLD"); now=60006
local count=#sent
local giver="Player-1234-00000001"
C_UnitAuras.GetAuraCasterGUID=function() return giver end
GetPlayerInfoByGUID=function(guid)
 assert(guid==giver)
 return "Mage","MAGE","Human","Human",2,"Passingmage",""
end
local function apply()
 auras={}; event("UNIT_AURA","player")
 auras={{name="Arcane Intellect",spellId=1461,auraInstanceID=101,expirationTime=61800}}
 event("UNIT_AURA","player")
end
apply(); assert(#sent==count and #timers==1)
timers[#timers](); assert(#sent==count+1 and sent[#sent][2]=="Passingmage","logged nil-source GUID case failed")
event("UNIT_AURA","player"); assert(#timers==1,"duplicate queued")
GetPlayerInfoByGUID=function() return nil,nil,nil,nil,nil,"Passingmage","OtherRealm" end
apply(); timers[#timers](); assert(sent[#sent][2]=="Passingmage-OtherRealm")
count=#sent
GetPlayerInfoByGUID=function() return nil,nil,nil,nil,nil,secret,"" end
apply(); timers[#timers](); assert(#sent==count,"restricted name used")
GetPlayerInfoByGUID=function() error("unavailable") end
apply(); timers[#timers](); assert(#sent==count,"failed lookup used")
giver="Player-Me"; local queued=#timers
apply(); assert(#timers==queued,"self GUID queued")
giver="Creature-123"; apply(); assert(#timers==queued,"NPC GUID queued")
giver="Player-Friend"; group=true
GetPlayerInfoByGUID=function() return nil,nil,nil,nil,nil,"Groupmate","" end
apply(); timers[#timers](); assert(#sent==count,"excluded group thanked")
''')
print('PASS: saved-log reproduction, delayed GUID-name thanks, realm qualification, duplicate/self/group/NPC and restricted-data filtering.')

lua.execute('''
group=false
local timers={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
local giver="Player-4619-0151353A"
C_UnitAuras.GetAuraCasterGUID=function() return giver end
GetPlayerInfoByGUID=function() return nil,nil,nil,nil,nil,"Passingpriest","" end
local function renew()
 auras={}; event("UNIT_AURA","player")
 auras={{name="Renew",spellId=6076,auraInstanceID=202,expirationTime=now+15}}
 event("UNIT_AURA","player")
end
local count=#sent
renew(); assert(#timers==1,"Renew with verified caster GUID was discarded")
timers[1](); assert(#sent==count+1 and sent[#sent][2]=="Passingpriest")
event("UNIT_AURA","player"); assert(#timers==1,"unchanged Renew queued twice")
for _,invalid in ipairs({"Player-Me","Creature-123",""}) do
 giver=invalid; renew(); assert(#timers==1,"self/NPC/unidentified Renew queued")
end
ns.SetOption("directThanks",false)
renew(); assert(#timers==1,"unidentified Renew bypassed known-gift filtering")
''')
print('PASS: saved Renew GUID case targets its giver; duplicate, self, NPC and unknown effects remain excluded.')
