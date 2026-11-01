param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Retribution-animation-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class RetributionArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 public static void Write(string dir){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)){
 double t=f*Math.PI*2/36;
 using(var g=Graphics.FromImage(im)){g.SmoothingMode=SmoothingMode.AntiAlias;
 // Retribution Aura: a luminous, engraved floor sigil with four curled corners.
 float pulse=(float)(.5+.5*Math.Sin(t));
 float auraScale=.88f+pulse*.24f;
 var aura=g.Save();g.TranslateTransform(512,765);g.ScaleTransform(auraScale,.38f*auraScale);
 for(int quarter=0;quarter<4;quarter++){
  var turn=g.Save();g.RotateTransform(quarter*90);
  PointF[] arm=new PointF[]{new PointF(-17,-32),new PointF(-17,-184),new PointF(-36,-207),new PointF(0,-241),new PointF(36,-207),new PointF(17,-184),new PointF(17,-32)};
  Line(g,Color.FromArgb(45,255,101,0),19,arm);
  Line(g,Color.FromArgb(225,255,136,20),6,arm);
  Line(g,Color.FromArgb((int)(150+pulse*70),255,214,74),2,arm);
  Line(g,Color.FromArgb(220,255,172,44),3,new PointF(-8,-68),new PointF(8,-77),new PointF(-7,-91),new PointF(8,-105),new PointF(-8,-119),new PointF(8,-133),new PointF(-7,-147),new PointF(7,-161));
  using(var gem=new Pen(Color.FromArgb(240,255,185,47),3))g.DrawEllipse(gem,-7,-215,14,14);
  // Pointed, curling gold flourishes fill the diagonal quadrants.
  using(var curl=new GraphicsPath()){
   curl.AddBezier(37,-38,61,-103,118,-56,83,-44);
   curl.AddBezier(83,-44,43,-30,89,-128,162,-162);
   curl.AddBezier(162,-162,132,-96,155,-50,185,-36);
   curl.AddBezier(185,-36,121,-55,86,-19,37,-38);
   using(var haze=new Pen(Color.FromArgb(40,255,156,0),22))g.DrawPath(haze,curl);
   using(var gold=new Pen(Color.FromArgb((int)(195+pulse*50),255,212,38),8))g.DrawPath(gold,curl);
   using(var hot=new Pen(Color.FromArgb(220,255,246,127),2))g.DrawPath(hot,curl);
  }
  Line(g,Color.FromArgb(225,255,198,36),5,new PointF(39,-59),new PointF(53,-151),new PointF(151,-168),new PointF(118,-112));
  g.Restore(turn);
 }
 g.Restore(aura);
 // Upright Templar greatsword, grounded beside the icon; gilded angular guard.
 var s=g.Save();g.TranslateTransform(291,718);g.RotateTransform(12);
 Poly(g,Color.FromArgb(255,143,106,36),new PointF(-25,-235),new PointF(-31,-65),new PointF(0,15),new PointF(31,-65),new PointF(25,-235));
 Poly(g,Color.FromArgb(255,255,233,150),new PointF(-15,-234),new PointF(-19,-66),new PointF(0,1),new PointF(0,-234));
 Poly(g,Color.FromArgb(255,198,174,95),new PointF(0,-234),new PointF(19,-234),new PointF(20,-65),new PointF(0,1));
 Line(g,Color.FromArgb(255,255,253,214),4,new PointF(0,-220),new PointF(0,-15));
 Poly(g,Color.FromArgb(255,208,153,41),new PointF(-76,-221),new PointF(-61,-258),new PointF(-28,-246),new PointF(0,-264),new PointF(28,-246),new PointF(61,-258),new PointF(76,-221),new PointF(25,-229),new PointF(0,-214),new PointF(-25,-229));
 Line(g,Color.FromArgb(255,244,209,111),15,new PointF(0,-261),new PointF(0,-363));
 for(int j=0;j<5;j++)Line(g,Color.FromArgb(255,111,79,38),5,new PointF(-7,-274-j*17),new PointF(7,-281-j*17));
 using(var b=new SolidBrush(Color.FromArgb(255,79,219,242)))g.FillEllipse(b,-13,-252,26,26);
 using(var pen=new Pen(Color.FromArgb(255,255,223,120),8))g.DrawEllipse(pen,-16,-388,32,32);
 g.Restore(s);
 // Silver Hand: a clearly separated silver gauntlet above the talent.
 var hand=g.Save();g.TranslateTransform(512,220+(float)Math.Sin(t)*5);
 // Warm radiance behind the silver fist, preserving its metallic detail.
 using(var auraShape=new GraphicsPath()){
  auraShape.AddEllipse(-90,-103,180,211);
  using(var light=new PathGradientBrush(auraShape)){
   light.CenterPoint=new PointF(0,-6);
   light.CenterColor=Color.FromArgb((int)(100+pulse*65),255,222,117);
   light.SurroundColors=new Color[]{Color.Transparent};g.FillPath(light,auraShape);
  }
 }
 for(int mote=0;mote<8;mote++){
  float age=(float)((f/36.0+mote*.125)%1),x=(float)Math.Sin(mote*4.3)*65,y=62-age*139;
  int alpha=(int)(Math.Sin(age*Math.PI)*160);
  using(var spark=new SolidBrush(Color.FromArgb(alpha,255,242,171)))g.FillEllipse(spark,x-2,y-3,4,6);
 }
 // Closed armored fist: four folded knuckle plates, thumb across the palm.
 Poly(g,Color.FromArgb(255,64,86,104),new PointF(-47,-41),new PointF(-33,-57),new PointF(37,-57),new PointF(53,-38),new PointF(47,20),new PointF(30,40),new PointF(-28,40),new PointF(-47,19));
 Poly(g,Color.FromArgb(255,163,185,200),new PointF(-39,-27),new PointF(42,-27),new PointF(36,20),new PointF(23,34),new PointF(-23,34),new PointF(-38,14));
 for(int finger=0;finger<4;finger++){
  float fx=-39+finger*20,fy=-49+(finger==0||finger==3?5:0);
  Poly(g,Color.FromArgb(255,218,231,237),new PointF(fx,fy),new PointF(fx+15,fy-3),new PointF(fx+17,fy+26),new PointF(fx+1,fy+29));
  Line(g,Color.FromArgb(255,250,252,243),3,new PointF(fx+2,fy+2),new PointF(fx+13,fy),new PointF(fx+14,fy+9));
  Line(g,Color.FromArgb(255,103,128,145),3,new PointF(fx+2,fy+18),new PointF(fx+15,fy+16));
 }
 Poly(g,Color.FromArgb(255,91,115,135),new PointF(-43,-12),new PointF(-27,-23),new PointF(12,-1),new PointF(5,20),new PointF(-15,16),new PointF(-39,4));
 Poly(g,Color.FromArgb(255,226,237,239),new PointF(-43,-16),new PointF(-28,-24),new PointF(13,-6),new PointF(8,8),new PointF(-13,7),new PointF(-37,-2));
 Poly(g,Color.FromArgb(255,99,123,145),new PointF(-29,35),new PointF(30,35),new PointF(38,70),new PointF(-38,70));
 Line(g,Color.FromArgb(255,234,237,220),6,new PointF(-31,39),new PointF(31,39));
 Line(g,Color.FromArgb(255,223,233,236),4,new PointF(-30,64),new PointF(30,64));
 Line(g,Color.FromArgb(255,222,233,238),4,new PointF(-17,44),new PointF(-21,60));
 Line(g,Color.FromArgb(255,222,233,238),4,new PointF(17,44),new PointF(21,60));g.Restore(hand);
 }im.Save(Path.Combine(dir,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[RetributionArt]::Write($destination)
Write-Output "Created Retribution animation: $destination"
