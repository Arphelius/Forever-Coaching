param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/BeastMastery-PackLeader-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class PackLeaderArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Eyes(Graphics g,float x,float y,Color color,int species,double t){
  double phase=(t/(Math.PI*2)+species*.29)%1;
  float open=phase>.78&&phase<.87?.13f:1;
  for(int side=-1;side<=1;side+=2){
   var eye=g.Save();g.TranslateTransform(x+side*40,y);g.RotateTransform(-side*(species==1?23:17));g.ScaleTransform(1,open*.72f);
   using(var haze=new GraphicsPath()){haze.AddEllipse(-38,-17,76,34);using(var fill=new PathGradientBrush(haze)){fill.CenterColor=Color.FromArgb(55,color);fill.SurroundColors=new Color[]{Color.FromArgb(0,color)};g.FillPath(fill,haze);}}
   var outline=new PointF[]{new PointF(-31,-5),new PointF(-13,-11),new PointF(15,-8),new PointF(32,-3),new PointF(11,7),new PointF(-12,5)};
   Poly(g,Color.FromArgb(240,color),outline);
   if(species==1)Poly(g,Color.FromArgb(255,12,24,15),new PointF(-2,-12),new PointF(3,-2),new PointF(-1,8),new PointF(-5,-2));
   else using(var pupil=new SolidBrush(Color.FromArgb(255,13,20,22)))g.FillEllipse(pupil,-5,-11,11,20);
   Stroke(g,Color.FromArgb(255,17,27,22),8,new PointF(-33,-11),new PointF(-9,-14),new PointF(34,-8));
   Stroke(g,Color.FromArgb(220,238,255,207),2,new PointF(-22,-6),new PointF(-6,-9),new PointF(13,-6));
   g.Restore(eye);
  }
 }
 static void Arrow(Graphics g,float x,float y,float angle,double t,int index){
  var state=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
  Stroke(g,Color.FromArgb(255,141,119,67),6,new PointF(0,89),new PointF(0,-99));
  Stroke(g,Color.FromArgb(255,213,216,164),2,new PointF(-1,81),new PointF(-1,-99));
  Poly(g,Color.FromArgb(255,60,109,57),new PointF(-3,52),new PointF(-23,80),new PointF(-20,111),new PointF(-3,87));
  Poly(g,Color.FromArgb(255,124,178,75),new PointF(3,52),new PointF(20,80),new PointF(19,111),new PointF(3,87));
  using(var glow=new GraphicsPath()){glow.AddEllipse(-32,-153,64,83);using(var fill=new PathGradientBrush(glow)){fill.CenterColor=Color.FromArgb(110,113,255,56);fill.SurroundColors=new Color[]{Color.FromArgb(0,68,215,23)};g.FillPath(fill,glow);}}
  Poly(g,Color.FromArgb(255,160,202,129),new PointF(0,-150),new PointF(-19,-104),new PointF(0,-113),new PointF(19,-104));
  Stroke(g,Color.FromArgb(255,126,255,62),5,new PointF(0,-143),new PointF(0,-111));
  for(int drop=0;drop<3;drop++){
   float p=(float)((t/(Math.PI*2)+drop/3.0+index*.19)%1),dx=drop%2==0?-12:12,dy=-112+p*p*79;
   using(var venom=new SolidBrush(Color.FromArgb((int)((1-p)*220),129,245,60)))g.FillEllipse(venom,dx-3,dy,6,9);
  }
  g.Restore(state);
 }
 public static void Write(string output){for(int frame=0;frame<36;frame++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=frame*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // Different pack members watch from above and both flanks; eyes only.
  Eyes(g,512,273,Color.FromArgb(255,185,60),0,t);
  Eyes(g,237,390,Color.FromArgb(134,231,81),1,t);
  Eyes(g,752,402,Color.FromArgb(102,211,223),2,t);
  // Recurved hunting bow hugs the lower-left edge of the talent.
  // Anchor the upper limb against the button's left edge; the quiver hangs below.
  var equipment=g.Save();g.TranslateTransform(244,586);g.RotateTransform(24);g.TranslateTransform(-340,-586);
  using(var bow=new GraphicsPath()){
   bow.AddBezier(341,442,296,478,276,482,270,563);
   bow.AddBezier(270,563,249,621,282,681,331,716);
   using(var wood=new Pen(Color.FromArgb(255,102,65,35),18)){wood.StartCap=wood.EndCap=LineCap.Round;g.DrawPath(wood,bow);}
   using(var edge=new Pen(Color.FromArgb(255,205,163,83),5))g.DrawPath(edge,bow);
  }
  Stroke(g,Color.FromArgb(245,190,206,164),2,new PointF(341,442),new PointF(374,577),new PointF(331,716));
  for(int wrap=0;wrap<6;wrap++)Stroke(g,Color.FromArgb(255,179,147,97),5,new PointF(258,556+wrap*7),new PointF(278,562+wrap*7));
  // A strapped leather quiver sits immediately against the bow's lower limb.
  var quiver=g.Save();g.TranslateTransform(338,699);g.RotateTransform(-12);
  // Arrow shafts and feathers remain visibly seated inside the open quiver.
  for(int arrow=0;arrow<3;arrow++){
   float x=-17+arrow*16,top=-113-arrow%2*20;
   Stroke(g,Color.FromArgb(255,177,153,99),5,new PointF(x,38),new PointF(x,top));
   Poly(g,Color.FromArgb(255,93,143,60),new PointF(x-2,top+4),new PointF(x-14,top-12),new PointF(x-12,top-33),new PointF(x-2,top-19));
   Poly(g,Color.FromArgb(255,164,192,96),new PointF(x+2,top+4),new PointF(x+12,top-12),new PointF(x+12,top-33),new PointF(x+2,top-19));
  }
  Poly(g,Color.FromArgb(255,85,57,33),new PointF(-37,-38),new PointF(36,-38),new PointF(28,92),new PointF(-23,102));
  Poly(g,Color.FromArgb(255,123,86,46),new PointF(-31,-34),new PointF(-2,-30),new PointF(-4,91),new PointF(-20,94));
  Stroke(g,Color.FromArgb(255,179,139,72),9,new PointF(-38,-37),new PointF(36,-37));
  Stroke(g,Color.FromArgb(255,48,43,27),12,new PointF(-33,9),new PointF(31,14));
  Stroke(g,Color.FromArgb(255,188,157,85),4,new PointF(-34,5),new PointF(31,10));
  g.Restore(quiver);
  Stroke(g,Color.FromArgb(255,128,98,51),8,new PointF(276,623),new PointF(311,646));
  Stroke(g,Color.FromArgb(255,85,65,34),9,new PointF(270,593),new PointF(310,611),new PointF(343,626));
  // Poison wisps drift from the broadheads without obscuring the talent face.
  for(int mote=0;mote<12;mote++){
   float p=(float)((frame/36.0+mote*.137)%1),x=321+(float)Math.Sin(t+mote)*16,y=590-p*55;
   using(var mist=new SolidBrush(Color.FromArgb((int)(Math.Sin(p*Math.PI)*70),128,238,57)))g.FillEllipse(mist,x,y,5+mote%3*3,7+mote%3*3);
  }
  g.Restore(equipment);
  im.Save(Path.Combine(output,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[PackLeaderArt]::Write($destination)
Write-Output "Created Pack Leader animation: $destination"
