"""Draw original addon artwork with Pillow; no generated image models.
Run: uv run --with pillow tools/Draw-AddonIcon.py
"""
from pathlib import Path
from io import BytesIO
import math
import zipfile
import xml.etree.ElementTree as ET
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output' / 'branding'
OUT.mkdir(parents=True, exist_ok=True)
SCALE = 4
SIZE = 512

def layer():
    return Image.new('RGBA', (SIZE*SCALE, SIZE*SCALE))

def path(points):
    return [(round(x*SCALE), round(y*SCALE)) for x,y in points]

def polygon(im, points, fill):
    ImageDraw.Draw(im).polygon(path(points), fill=fill)

def line(im, points, fill, width):
    ImageDraw.Draw(im).line(path(points), fill=fill, width=round(width*SCALE), joint='curve')

def ellipse(im, box, fill, outline=None, width=1):
    ImageDraw.Draw(im).ellipse(tuple(round(v*SCALE) for v in box), fill=fill, outline=outline, width=round(width*SCALE))

def curve(a,b,c,d):
    return [((1-t)**3*a[0]+3*(1-t)**2*t*b[0]+3*(1-t)*t*t*c[0]+t**3*d[0],
             (1-t)**3*a[1]+3*(1-t)**2*t*b[1]+3*(1-t)*t*t*c[1]+t**3*d[1]) for t in [i/40 for i in range(41)]]

layers=[]
shadow=layer()
polygon(shadow, [(147,69),(397,69),(374,382),(330,444),(81,444),(109,347)], (0,0,0,165))
shadow=shadow.filter(ImageFilter.GaussianBlur(7*SCALE))
layers.append(('Drop shadow',shadow))

paper=layer()
body=curve((134,78),(198,84),(304,65),(369,79))+curve((369,79),(353,164),(331,279),(333,386))+curve((333,386),(278,411),(166,417),(112,396))+curve((112,396),(117,309),(151,150),(134,78))
polygon(paper,body,'#402719')
inner=curve((147,89),(214,96),(301,78),(355,88))+curve((355,88),(339,181),(318,286),(322,380))+curve((322,380),(265,400),(174,402),(127,388))+curve((127,388),(131,296),(164,157),(147,89))
polygon(paper,inner,'#c28b45')
inside=curve((156,96),(222,101),(301,86),(345,95))+curve((345,95),(328,192),(309,287),(313,374))+curve((313,374),(255,389),(179,392),(138,383))+curve((138,383),(142,292),(172,159),(156,96))
polygon(paper,inside,'#efd49a')
line(paper,curve((169,108),(220,113),(292,96),(330,104)),'#fff0c4',5)
line(paper,curve((155,135),(164,225),(136,313),(142,366)),'#ffedba',4)
layers.append(('Parchment',paper))

roll=layer()
top=curve((112,81),(109,45),(148,45),(171,58))+curve((171,58),(228,66),(322,45),(371,57))+curve((371,57),(400,60),(407,99),(384,111))+curve((384,111),(322,97),(234,124),(168,110))+curve((168,110),(139,119),(111,110),(112,81))
polygon(roll,top,'#41281b')
topinner=curve((122,81),(122,59),(146,56),(166,68))+curve((166,68),(233,78),(324,55),(371,68))+curve((371,68),(387,71),(393,91),(379,100))+curve((379,100),(313,88),(234,113),(169,99))+curve((169,99),(142,109),(123,101),(122,81))
polygon(roll,topinner,'#d7aa62')
line(roll,curve((167,73),(233,84),(325,62),(370,75)),'#fff0ba',6)
ellipse(roll,(122,65,160,103),'#986332','#4a2d1c',4)
ellipse(roll,(133,75,150,94),'#573621')
bottom=curve((104,368),(145,382),(254,377),(320,367))+curve((320,367),(358,350),(377,390),(357,421))+curve((357,421),(291,441),(163,432),(104,429))+curve((104,429),(72,428),(72,373),(104,368))
polygon(roll,bottom,'#41281b')
bottominner=curve((105,381),(154,395),(257,390),(324,380))+curve((324,380),(345,365),(365,391),(349,409))+curve((349,409),(273,427),(166,419),(105,416))+curve((105,416),(86,414),(85,386),(105,381))
polygon(roll,bottominner,'#d2a05b')
line(roll,curve((112,391),(177,406),(270,397),(318,390)),'#ffe9af',6)
ellipse(roll,(320,377,355,413),'#a37038','#4a2d1c',4)
ellipse(roll,(332,386,345,403),'#5f3a22')
layers.append(('Rolled edges',roll))

ink=layer()
for y,length in [(143,109),(164,87),(316,72),(336,94)]:
    line(ink,[(186,y),(186+length,y-3)],'#ad844e',5)
layers.append(('Guide markings',ink))

check=layer()
checkpoints=[(173,237),(207,210),(245,247),(338,153),(373,186),(247,310)]
polygon(check,[(x+2,y+9) for x,y in checkpoints], '#73431e')
polygon(check,checkpoints,'#432a1b')
polygon(check,[(184,237),(207,222),(245,263),(339,166),(359,186),(246,294)],'#efb72e')
polygon(check,[(184,237),(207,222),(245,263),(339,166),(345,176),(245,278),(205,237),(191,245)],'#ffe58a')
line(check,[(198,248),(246,291),(351,185)],'#ce871b',5)
layers.append(('Gold checkmark',check))

merged=layer()
for name,im in layers:
    merged.alpha_composite(im)
merged=merged.resize((SIZE,SIZE),Image.Resampling.LANCZOS)
merged.save(OUT/'forever-coaching-icon-512.png')
for size in (256,128,64):
    merged.resize((size,size),Image.Resampling.LANCZOS).save(OUT/f'forever-coaching-icon-{size}.png')

# WoW textures require a supported game format; preserve transparency in RGBA TGA.
media = ROOT / 'addons' / 'ForeverCoaching' / 'Media'
media.mkdir(parents=True, exist_ok=True)
merged.resize((256,256),Image.Resampling.LANCZOS).save(media/'ForeverCoachingIcon.tga', compression=None)

def png(im):
    stream=BytesIO(); im.save(stream,format='PNG'); return stream.getvalue()

root=ET.Element('image',{'version':'0.0.3','w':str(SIZE),'h':str(SIZE),'name':'Forever Coaching icon'})
stack=ET.SubElement(root,'stack')
with zipfile.ZipFile(OUT/'forever-coaching-icon.ora','w') as archive:
    archive.writestr('mimetype','image/openraster',compress_type=zipfile.ZIP_STORED)
    for i,(name,im) in enumerate(reversed(layers)):
        src=f'data/layer{i}.png'
        archive.writestr(src,png(im.resize((SIZE,SIZE),Image.Resampling.LANCZOS)))
        ET.SubElement(stack,'layer',{'name':name,'src':src,'opacity':'1.0','visibility':'visible','composite-op':'svg:src-over','x':'0','y':'0'})
    archive.writestr('stack.xml',ET.tostring(root,encoding='utf-8',xml_declaration=True))
    archive.writestr('mergedimage.png',png(merged))
    archive.writestr('Thumbnails/thumbnail.png',png(merged.resize((256,256),Image.Resampling.LANCZOS)))

preview=Image.new('RGBA',(800,550),'#252525')
preview.alpha_composite(merged,(15,15))
preview.alpha_composite(merged.resize((128,128),Image.Resampling.LANCZOS),(590,75))
preview.alpha_composite(merged.resize((64,64),Image.Resampling.LANCZOS),(620,265))
preview.convert('RGB').save(OUT/'icon-preview.png')
print(OUT)
