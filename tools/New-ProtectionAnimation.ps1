param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Protection-animation-v15'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ProtectionArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Bevel;g.DrawLines(pen,p);}}
 static float Power;
 static void Plate(Graphics g,PointF[] p){
  using(var b=new LinearGradientBrush(new PointF(300,180),new PointF(700,750),Color.FromArgb(255,103,67,39),Color.FromArgb(255,29,27,31)))g.FillPolygon(b,p);
  Line(g,Color.FromArgb(255,203,113,23),8,p);
  Line(g,Color.FromArgb(255,255,197,43),2,p);
  using(var fill=new SolidBrush(Color.FromArgb((int)(12+Power*22),255,141,6)))g.FillPolygon(fill,p);
  Line(g,Color.FromArgb((int)(45+Power*35),255,110,0),30,p);
  Line(g,Color.FromArgb((int)(185+Power*65),255,214,24),5,p);
 }

 public static void Write(string dir){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)){
 double t=f*Math.PI*2/36;Power=(float)(.5+.5*Math.Sin(t));
 using(var g=Graphics.FromImage(im)){g.SmoothingMode=SmoothingMode.AntiAlias;
 // Living holy fire silhouettes the armor, with no detached weapons or bubble.
 for(int side=-1;side<=1;side+=2){
  var armor=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
  for(int flame=0;flame<16;flame++){
   float y=267+flame*23,x=202+(float)Math.Sin(flame*.6)*21;
   float pulse=(float)(.5+.5*Math.Sin(t*2+flame*1.7)),h=36+pulse*42;
   using(var fire=new GraphicsPath()){
    fire.AddBezier(x-14,y,x-29,y-h*.4f,x+15,y-h*.5f,x+22,y-h);
    fire.AddBezier(x+22,y-h,x+30,y-h*.3f,x+21,y,x-14,y);fire.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(x,y),new PointF(x,y-h),Color.FromArgb(125,255,119,0),Color.FromArgb(0,255,220,47)))g.FillPath(fill,fire);
   }
  }
  // Compact stacked pauldrons connect directly to the helmet and talent body.
  for(int layer=2;layer>=0;layer--){
   float x=147+layer*5,y=310+layer*48;
   Plate(g,new PointF[]{new PointF(x-41,y+21),new PointF(x-12,y-37),new PointF(x+14,y-77),new PointF(x+26,y-29),new PointF(x+73,y-43),new PointF(x+47,y-7),new PointF(x+92,y+35),new PointF(x+45,y+16),new PointF(x+52,y+66),new PointF(x+13,y+42),new PointF(x-41,y+21)});
   Line(g,Color.FromArgb(245,255,226,61),4,new PointF(x-22,y+14),new PointF(x+15,y-39),new PointF(x+21,y-7),new PointF(x+54,y+10));
  }
  Plate(g,new PointF[]{new PointF(183,450),new PointF(213,469),new PointF(191,568),new PointF(159,618),new PointF(175,539),new PointF(169,493),new PointF(183,450)});
  g.Restore(armor);
 }
 // Blackened bronze helm with a narrow fiery visor and radiant central crest.
 Plate(g,new PointF[]{new PointF(448,300),new PointF(427,237),new PointF(444,199),new PointF(476,179),new PointF(491,195),new PointF(512,143),new PointF(533,195),new PointF(548,179),new PointF(580,199),new PointF(597,237),new PointF(576,300),new PointF(545,322),new PointF(512,304),new PointF(479,322),new PointF(448,300)});
 using(var dark=new SolidBrush(Color.FromArgb(255,23,20,25)))g.FillPolygon(dark,new PointF[]{new PointF(448,229),new PointF(489,241),new PointF(512,224),new PointF(535,241),new PointF(576,229),new PointF(554,276),new PointF(530,285),new PointF(512,312),new PointF(494,285),new PointF(470,276)});
 Line(g,Color.FromArgb(255,255,175,26),5,new PointF(462,243),new PointF(490,254),new PointF(496,275));
 Line(g,Color.FromArgb(255,255,175,26),5,new PointF(562,243),new PointF(534,254),new PointF(528,275));
 Line(g,Color.FromArgb(100,255,128,0),20,new PointF(512,158),new PointF(512,307));
 Line(g,Color.FromArgb(255,255,222,56),5,new PointF(512,158),new PointF(512,307));
 // A tapered crown of light gathers above the forged crest.
 for(int flame=0;flame<9;flame++){
  float x=456+flame*14,h=45+(flame*23)%63+(float)Math.Sin(t*2+flame)*11;
  using(var light=new GraphicsPath()){
   light.AddBezier(x-10,206,x-15,176,x+5,180-h*.6f,x+3,180-h);
   light.AddBezier(x+3,180-h,x+20,172,x+9,191,x+10,206);light.CloseFigure();
   using(var fill=new LinearGradientBrush(new PointF(x,206),new PointF(x,180-h),Color.FromArgb(95,255,194,22),Color.FromArgb(0,255,235,97)))g.FillPath(fill,light);
  }
 }
 // Restore the translucent shield of light directly over the talent.
 using(var shield=new GraphicsPath()){
  shield.AddPolygon(new PointF[]{new PointF(326,360),new PointF(512,312),new PointF(698,360),new PointF(677,532),new PointF(612,637),new PointF(512,711),new PointF(412,637),new PointF(347,532)});
  using(var fill=new LinearGradientBrush(new PointF(350,340),new PointF(660,700),Color.FromArgb(40,255,241,159),Color.FromArgb(70,255,161,32)))g.FillPath(fill,shield);
  using(var glow=new Pen(Color.FromArgb(45,255,177,36),30))g.DrawPath(glow,shield);
  using(var rim=new Pen(Color.FromArgb(235,255,223,106),10))g.DrawPath(rim,shield);
  using(var core=new Pen(Color.FromArgb(245,255,252,207),3))g.DrawPath(core,shield);
 }
 for(int band=0;band<4;band++){
  float p=(float)((f/36.0+band*.25)%1),y=660-p*290;
  Line(g,Color.FromArgb((int)(Math.Sin(p*Math.PI)*95),255,249,189),7,new PointF(410,y-25),new PointF(512,y),new PointF(614,y-25));
 }
 }im.Save(Path.Combine(dir,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[ProtectionArt]::Write($destination)
Write-Output "Created Protection animation: $destination"
