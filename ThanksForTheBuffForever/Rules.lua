local _, ns = ...
local classes = {{"ANY","Any class"},{"DRUID","Druid"},{"HUNTER","Hunter"},{"MAGE","Mage"},
    {"PALADIN","Paladin"},{"PRIEST","Priest"},{"ROGUE","Rogue"},{"SHAMAN","Shaman"},{"WARLOCK","Warlock"},{"WARRIOR","Warrior"}}
local genders = {{"ANY","Any gender"},{"2","Male"},{"3","Female"}}
local races = {{"ANY","Any race"},{"Dwarf","Dwarf"},{"Gnome","Gnome"},{"Human","Human"},
    {"NightElf","Night elf"},{"Orc","Orc"},{"Tauren","Tauren"},{"Troll","Troll"},{"Scourge","Undead"}}
local function Label(options, value)
    for _, option in ipairs(options) do if option[1] == value then return option[2] end end
end
local function Validate(class, gender, race, text)
    if not Label(classes,class) or not Label(genders,gender) or not Label(races,race) then return nil,"Choose valid filters." end
    if type(text) ~= "string" or #text > 500 then return nil,"Use up to 500 characters." end
    local pool, issue = ns.ParseEmotes(text)
    if not pool then return nil,issue end
    if #pool == 0 then return nil,"Enter at least one emote." end
    local commands = {}
    for _, token in ipairs(pool) do commands[#commands+1] = token:lower() end
    return {class=class,gender=gender,race=race,text=table.concat(commands,", "),emotes=pool}
end
function ns.InitRules()
    local db = ThanksForTheBuffForeverDB
    local clean = {}
    if type(db.rules) == "table" then
        for _, rule in ipairs(db.rules) do
            if type(rule) == "table" then
                local valid = Validate(rule.class,rule.gender,rule.race,rule.text)
                if valid and #clean < 100 then clean[#clean+1] = valid end
            end
        end
    end
    db.rules = clean
end
function ns.SaveRule(index, class, gender, race, text)
    local rules = ThanksForTheBuffForeverDB.rules
    local rule, issue = Validate(class,gender,race,text)
    if not rule then return false,issue end
    if index and not rules[index] then return false,"That rule no longer exists." end
    for i, other in ipairs(rules) do
        if i ~= index and other.class == class and other.gender == gender and other.race == race then
            return false,"Those filters already have a rule. Edit it below."
        end
    end
    if not index and #rules >= 100 then return false,"Limit reached: 100 rules." end
    rules[index or (#rules+1)] = rule
    ns.Log("RULE_SAVED",class,gender,race,rule.text)
    return true,"Rule saved."
end
function ns.DeleteRule(index)
    local rules = ThanksForTheBuffForeverDB.rules
    if rules[index] then table.remove(rules,index); ns.Log("RULE_DELETED",index) end
end
local function Public(v) return not issecretvalue or not issecretvalue(v) end
function ns.RuleEmote(unit)
    local rules = ThanksForTheBuffForeverDB.rules or {}
    if #rules == 0 then return end
    local _, class = UnitClass(unit)
    local _, race = UnitRace(unit)
    local sex = UnitSex(unit)
    class = Public(class) and class or nil
    race = Public(race) and race or nil
    local gender = Public(sex) and tostring(sex) or nil
    local best, score, bestIndex = nil,-1,nil
    for index, rule in ipairs(rules) do
        if (rule.class == "ANY" or rule.class == class) and (rule.gender == "ANY" or rule.gender == gender)
            and (rule.race == "ANY" or rule.race == race) then
            local specificity = (rule.class ~= "ANY" and 1 or 0) + (rule.gender ~= "ANY" and 1 or 0) + (rule.race ~= "ANY" and 1 or 0)
            if specificity > score then best,score,bestIndex = rule,specificity,index end
        end
    end
    if best then return best.emotes[math.random(#best.emotes)],bestIndex end
end

local window, refresh
function ns.OpenAdvanced()
    if window then window:Show(); refresh(); return end
    window = CreateFrame("Frame","ThanksForTheBuffForeverAdvanced",UIParent,"BasicFrameTemplateWithInset")
    window:SetSize(640,570)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true); window:EnableMouse(true); window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart",window.StartMoving)
    window:SetScript("OnDragStop",window.StopMovingOrSizing)
    window.TitleText:SetText("Advanced emote rules")
    table.insert(UISpecialFrames,"ThanksForTheBuffForeverAdvanced")
    local function Text(text,x,y,width)
        local label = window:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        label:SetPoint("TOPLEFT",x,y); label:SetWidth(width or 600); label:SetJustifyH("LEFT"); label:SetText(text)
        return label
    end
    local function Button(text,x,y,width,fn)
        local button = CreateFrame("Button",nil,window,"UIPanelButtonTemplate")
        button:SetSize(width,24); button:SetPoint("TOPLEFT",x,y); button:SetText(text); button:SetScript("OnClick",fn)
        return button
    end
    Text("Choose who buffed you, then add the emotes to use.",20,-42)
    local fields = {}
    local function Dropdown(key,title,options,x)
        Text(title,x+16,-70,160)
        local field = CreateFrame("Frame",nil,window,"UIDropDownMenuTemplate")
        field:SetPoint("TOPLEFT",x,-88); UIDropDownMenu_SetWidth(field,164)
        field.value = "ANY"; fields[key] = field
        UIDropDownMenu_Initialize(field,function()
            for _,option in ipairs(options) do
                local value,label = option[1],option[2]
                local info = UIDropDownMenu_CreateInfo()
                info.text=label; info.value=value; info.checked=field.value==value
                info.func=function() field.value=value; UIDropDownMenu_SetText(field,label) end
                UIDropDownMenu_AddButton(info)
            end
        end)
        UIDropDownMenu_SetText(field,options[1][2])
    end
    Dropdown("class","Class",classes,4); Dropdown("gender","Gender",genders,212); Dropdown("race","Race",races,420)
    Text("Emotes (comma-separated)",20,-132)
    local edit = CreateFrame("EditBox",nil,window,"InputBoxTemplate")
    edit:SetSize(590,26); edit:SetPoint("TOPLEFT",24,-152); edit:SetAutoFocus(false); edit:SetMaxLetters(500)
    Text("Example: thank, wave, bow. One is picked at random.",20,-183)
    local status = Text("",20,-244)
    local editing, page = nil,1
    local save
    local function Reset()
        editing=nil; edit:SetText(""); edit:ClearFocus(); save:SetText("Add rule")
    end
    local function Save()
        local ok,message=ns.SaveRule(editing,fields.class.value,fields.gender.value,fields.race.value,edit:GetText())
        status:SetText(message)
        if ok then Reset(); page=math.max(1,math.ceil(#ThanksForTheBuffForeverDB.rules/5)); refresh() end
    end
    save=Button("Add rule",20,-209,110,Save)
    Button("Cancel edit",140,-209,110,function() Reset(); status:SetText("") end)
    edit:SetScript("OnEnterPressed",Save)
    edit:SetScript("OnEscapePressed",function(self) self:ClearFocus() end)
    Text("More filters take priority. Ties use the first rule below. No match uses normal settings.",20,-269)
    local rows={}
    for i=1,5 do
        local row={}
        local y=-300-(i-1)*43
        row.text=Text("",20,y,410)
        row.edit=Button("Edit",440,y,75,function()
            local rule=ThanksForTheBuffForeverDB.rules[row.index]
            if not rule then return end
            editing=row.index; edit:SetText(rule.text); save:SetText("Save rule")
            for key,options in pairs({class=classes,gender=genders,race=races}) do
                fields[key].value=rule[key]; UIDropDownMenu_SetText(fields[key],Label(options,rule[key]))
            end
            status:SetText("Editing rule " .. row.index)
        end)
        row.delete=Button("Remove",525,y,90,function()
            ns.DeleteRule(row.index); Reset(); refresh(); status:SetText("Rule removed.")
        end)
        rows[i]=row
    end
    local pageText=Text("",255,-535,150)
    local previous=Button("Previous",20,-527,100,function() page=page-1; refresh() end)
    local nextPage=Button("Next",515,-527,100,function() page=page+1; refresh() end)
    refresh=function()
        local rules=ThanksForTheBuffForeverDB.rules
        local pages=math.max(1,math.ceil(#rules/5)); page=math.max(1,math.min(page,pages))
        pageText:SetText("Page " .. page .. " / " .. pages)
        previous:SetEnabled(page>1); nextPage:SetEnabled(page<pages)
        for i,row in ipairs(rows) do
            row.index=(page-1)*5+i
            local rule=rules[row.index]
            row.edit:SetShown(rule~=nil); row.delete:SetShown(rule~=nil)
            local preview = rule and (#rule.text > 60 and (rule.text:sub(1,57) .. "...") or rule.text)
            row.text:SetText(rule and (Label(classes,rule.class) .. " / " .. Label(genders,rule.gender) .. " / " .. Label(races,rule.race) .. "\n" .. preview) or "")
            row.text:SetHeight(36)
        end
        if #rules==0 then rows[1].text:SetText("No rules yet. Your normal emotes are used.") end
    end
    refresh(); window:Show()
end
