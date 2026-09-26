from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

out=Path(__file__).resolve().parents[1]/'media'
out.mkdir(exist_ok=True)
im=Image.new('RGB',(512,512),'#142939')
d=ImageDraw.Draw(im)
d.rounded_rectangle((45,60,435,358),radius=64,fill='#f5e8c7',outline='#d4aa52',width=10)
d.polygon([(110,345),(110,425),(212,348)],fill='#f5e8c7')
font=ImageFont.truetype('C:/Windows/Fonts/arialbd.ttf',150)
d.text((240,202),'TY',font=font,fill='#193849',anchor='mm')
d.polygon([(405,314),(421,354),(464,371),(421,388),(405,432),(388,388),(346,371),(388,354)],fill='#f2bb4e')
im.save(out/'icon.png')
print(out/'icon.png')
