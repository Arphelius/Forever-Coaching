param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Demonology-Diabolist-v4'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class DiabolistArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 public static void Write(string output){for(int f=0;f<108;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/108;float pulse=(float)(.5+.5*Math.Sin(t));g.SmoothingMode=SmoothingMode.AntiAlias;
  float progress=f/107f,reach=Math.Min(1,Math.Max(0,(progress-.05f)/.28f));reach=reach*reach*(3-2*reach);
  // Two vertical fel portals flank the spell; huge hands reach inward from them.
  for(int side=-1;side<=1;side+=2){
   float portalX=512+side*303;
   using(var gate=new GraphicsPath()){
    gate.AddEllipse(portalX-40,392,80,216);
    using(var voidFill=new SolidBrush(Color.FromArgb(200,9,30,10)))g.FillPath(voidFill,gate);
    using(var haze=new Pen(Color.FromArgb(65,81,205,11),26))g.DrawPath(haze,gate);
    using(var rim=new Pen(Color.FromArgb(230,153,246,35),5))g.DrawPath(rim,gate);
   }
   for(int ring=0;ring<5;ring++)using(var swirl=new Pen(Color.FromArgb(115,105+ring*22,229,27),2))g.DrawArc(swirl,portalX-31+ring*3,405+ring*9,62-ring*6,190-ring*18,(float)(t*180/Math.PI)+ring*61,120);
   if(reach>0){
    var hand=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
    float palm=303-reach*72;
    Poly(g,Color.FromArgb(255,26,46,40),new PointF(309,458),new PointF(palm+11,444),new PointF(palm-22,459),new PointF(palm-32,512),new PointF(palm+2,552),new PointF(310,547));
    Line(g,Color.FromArgb(140,85,112,57),4,new PointF(298,467),new PointF(palm+4,459),new PointF(palm-14,478));
    for(int finger=0;finger<4;finger++){
     float y=463+finger*22,tip=palm-26-reach*(28+finger%2*9);
     Line(g,Color.FromArgb(255,35,58,45),18,new PointF(palm-5,y),new PointF(tip,y+10),new PointF(tip+5,y+28));
     Line(g,Color.FromArgb(190,90,117,57),3,new PointF(palm-8,y-4),new PointF(tip,y+8));
     Poly(g,Color.FromArgb(255,160,176,91),new PointF(tip-2,y+23),new PointF(tip+12,y+25),new PointF(tip+14,y+45));
    }
    Line(g,Color.FromArgb(255,44,66,47),20,new PointF(palm+15,530),new PointF(palm-12,552),new PointF(palm-44,539));
    Glow(g,palm-26,512,44,Color.FromArgb(75,102,207,19));g.Restore(hand);
   }
  }
  // Fel fire pours around the outside of the spell, preserving the central face.
  for(int side=-1;side<=1;side+=2)for(int fire=0;fire<23;fire++){
   float age=(float)((f/108.0+fire*.0435)%1),x=512+side*(211+(float)Math.Sin(age*5+fire)*25),y=740-age*450;
   float h=26+fire%4*11,wave=(float)Math.Sin(t*2+fire)*13;
   Glow(g,x,y,27,Color.FromArgb(65,74,143,13));
   using(var flame=new GraphicsPath()){
    flame.AddBezier(x-12,y,x-24,y-h*.5f,x+wave,y-h*.5f,x+wave,y-h);
    flame.AddBezier(x+wave,y-h,x+24,y-10,x+9,y+8,x-12,y);flame.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(x,y),new PointF(x,y-h),Color.FromArgb(150,131,219,19),Color.FromArgb(0,211,255,89)))g.FillPath(fill,flame);
   }
  }
  Glow(g,512,240,116,Color.FromArgb(90,81,134,10));
  for(int side=-1;side<=1;side+=2){
   var demon=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   // Massive swept bronze horns curve around the dark green demonic face.
   using(var horn=new GraphicsPath()){
    horn.AddBezier(48,235,129,278,161,183,113,112);
    horn.AddBezier(113,112,126,181,96,209,64,180);horn.CloseFigure();
    using(var metal=new LinearGradientBrush(new PointF(80,130),new PointF(125,254),Color.FromArgb(255,94,78,39),Color.FromArgb(255,161,98,48)))g.FillPath(metal,horn);
    using(var rim=new Pen(Color.FromArgb(210,181,140,64),3))g.DrawPath(rim,horn);
   }
   for(int rib=0;rib<4;rib++)Line(g,Color.FromArgb(130,63,57,32),3,new PointF(98+rib*5,171+rib*15),new PointF(119+rib*4,163+rib*18));
   Poly(g,Color.FromArgb(255,27,49,45),new PointF(0,177),new PointF(35,191),new PointF(57,183),new PointF(80,221),new PointF(62,264),new PointF(34,286),new PointF(19,310),new PointF(0,304));
   Line(g,Color.FromArgb(180,76,96,56),3,new PointF(14,195),new PointF(38,215),new PointF(67,223),new PointF(44,252));
   Glow(g,34,235,21,Color.FromArgb((int)(140+pulse*70),143,235,15));
   Line(g,Color.FromArgb(255,200,255,61),5,new PointF(14,235),new PointF(31,228),new PointF(49,232));
   Poly(g,Color.FromArgb(255,13,24,23),new PointF(12,257),new PointF(42,255),new PointF(29,284),new PointF(6,292));
   for(int tooth=0;tooth<3;tooth++)Poly(g,Color.FromArgb(240,204,218,123),new PointF(10+tooth*10,258),new PointF(17+tooth*10,258),new PointF(13+tooth*10,268));
   g.Restore(demon);
  }
  Line(g,Color.FromArgb(255,60,83,48),4,new PointF(512,187),new PointF(503,232),new PointF(512,250),new PointF(521,232),new PointF(512,187));
  Glow(g,512,278,18,Color.FromArgb((int)(90+pulse*65),132,218,18));
  // Fel embers rise from the hands and disappear into the horns.
  for(int ember=0;ember<33;ember++){
   float age=(float)((f/108.0+ember*.137)%1),side=ember%2==0?-1:1;
   float x=512+side*(221-age*70)+(float)Math.Sin(t+ember)*15,y=669-age*470;
   Glow(g,x,y,4+ember%3,Color.FromArgb((int)(Math.Sin(age*Math.PI)*190),167,245,35));
  }
  // After the grip closes, the demon annihilates the spell in a widening fel blast.
  float blast=Math.Max(0,Math.Min(1,(progress-.43f)/.14f));
  float sustain=progress<.74f?1:Math.Max(0,1-(progress-.74f)/.14f);
  if(blast>0&&sustain>0){
   for(int layer=0;layer<4;layer++)using(var beam=new GraphicsPath()){
    float w=(74-layer*15)*blast,endY=280+blast*420;
    beam.AddPolygon(new PointF[]{new PointF(501,277),new PointF(523,277),new PointF(512+w,endY),new PointF(512-w,endY)});
    Color hot=layer<2?Color.FromArgb((int)(sustain*90),104+layer*38,235,20):Color.FromArgb((int)(sustain*135),220,255,112);
    using(var fill=new LinearGradientBrush(new PointF(512,277),new PointF(512,endY),hot,Color.FromArgb((int)(sustain*65),66,173,9)))g.FillPath(fill,beam);
   }
   Glow(g,512,278,23+blast*15,Color.FromArgb((int)(sustain*220),185,255,54));
   Glow(g,512,660,45+blast*73,Color.FromArgb((int)(sustain*155),132,238,20));
  }
  if(progress>.56f){
   float ruin=Math.Min(1,(progress-.56f)/.22f);
   var impact=g.Save();g.SetClip(new Rectangle(309,309,406,406));
   using(var scorch=new SolidBrush(Color.FromArgb((int)(ruin*155),9,19,7)))g.FillRectangle(scorch,309,309,406,406);
   for(int crack=0;crack<9;crack++){
    double angle=crack*Math.PI*2/9;float r=ruin*250;
    PointF[] split=new PointF[]{new PointF(512,548),new PointF(512+(float)Math.Cos(angle)*r*.4f,548+(float)Math.Sin(angle)*r*.4f),new PointF(512+(float)Math.Cos(angle+.16)*r*.7f,548+(float)Math.Sin(angle+.16)*r*.7f),new PointF(512+(float)Math.Cos(angle)*r,548+(float)Math.Sin(angle)*r)};
    Line(g,Color.FromArgb(65,106,214,13),13,split);Line(g,Color.FromArgb((int)(ruin*185),159,238,35),2,split);
   }
   g.Restore(impact);
  }
  for(int y=642;y<819;y++)for(int x=592;x<821;x++){
   float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));
   float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(x,y);
   if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[DiabolistArt]::Write($destination)
