from test_buff_back import lua

lua.execute('''
mine="MAGE"; units.target={guid="lowbie",class="PRIEST",level=3}
auras.target={}; events.scripts.OnEvent()
ns.RefreshClickBuff()
assert(b.attrs.spell=="Spell1459(Rank 1)","low target received highest rank")
ns.OfferBuffBack("target","lowbie")
assert(back.attrs.macrotext1:find("Spell1459%(Rank 1%)"),"buff back lost explicit rank")
units.target.level=4; ns.RefreshClickBuff()
assert(b.attrs.spell=="Spell1460(Rank 2)","boundary did not select higher rank")
back.scripts.PreClick(back)
assert(back.attrs.macrotext1:find("Spell1460%(Rank 2%)"),"buff back did not recalculate")
units.target.level=3; b.scripts.PreClick(b)
assert(b.attrs.type1==nil,"stale higher rank remained clickable")
units.target.level=secret; ns.RefreshClickBuff(); assert(not b.shown)
back.scripts.PreClick(back); assert(back.attrs.type1==nil)
units.target.level=-1; ns.RefreshClickBuff(); assert(not b.shown)
units.target.level=60; known[1460]=false; events.scripts.OnEvent()
assert(b.attrs.spell=="Spell1459(Rank 1)","unlearned rank offered")
''')
print('PASS: recipient level boundaries, explicit ranks for both buttons, stale rank rejection, unknown levels and unlearned ranks.')
