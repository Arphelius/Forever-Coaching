param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Shadow-Voidweaver-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class VoidweaverArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 static PointF Orbit(double a,int orb){return new PointF(512+(float)Math.Cos(a)*(orb==0?180:261),480+(float)Math.Sin(a)*(orb==0?304:190));}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  float surge=(float)(.5+.5*Math.Sin(t*2));
  // A shadowed brow with two dark, cyan-rimmed eyes above the talent.
  var topDesign=g.Save();g.TranslateTransform(0,30);
  Glow(g,512,276,133,Color.FromArgb(135,28,9,59));
  for(int side=-1;side<=1;side+=2){
   var eyeState=g.Save();g.TranslateTransform(512+side*51,278);g.RotateTransform(-side*14);
   using(var eye=new GraphicsPath()){
    eye.AddBezier(-36,0,-17,-22,18,-18,36,-5);eye.AddBezier(36,-5,15,17,-18,16,-36,0);eye.CloseFigure();
    using(var haze=new Pen(Color.FromArgb((int)(90+surge*65),36,149,246),23))g.DrawPath(haze,eye);
    using(var dark=new SolidBrush(Color.FromArgb(255,3,5,16)))g.FillPath(dark,eye);
    using(var rim=new Pen(Color.FromArgb(250,97,221,255),4))g.DrawPath(rim,eye);
   }
   Line(g,Color.FromArgb(160,118,68,205),4,new PointF(-38,-12),new PointF(-4,-24),new PointF(32,-16));
   g.Restore(eyeState);
  }
  // Branching void antlers cradle the upper orb, close to the brow.
  for(int side=-1;side<=1;side+=2){
   var antler=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   for(int haze=0;haze<8;haze++)Glow(g,55+haze*8,276-haze*10,23,Color.FromArgb(32,35,13,75));
   PointF[] branch=new PointF[]{new PointF(45,282),new PointF(61,256),new PointF(89,239),new PointF(102,210),new PointF(99,182)};
   Line(g,Color.FromArgb(110,30,17,66),17,branch);Line(g,Color.FromArgb(235,25,29,64),9,branch);Line(g,Color.FromArgb(170,66,151,214),2,branch);
   float charge=(float)((f/36.0+side*.17+1)%1);
   Glow(g,45+charge*59,282-charge*100,17,Color.FromArgb(200,70,166,242));
   Line(g,Color.FromArgb((int)(65+surge*105),105,113,252),3,branch);
   Line(g,Color.FromArgb(210,39,43,89),6,new PointF(82,245),new PointF(121,234),new PointF(139,211));
   Line(g,Color.FromArgb(145,69,157,208),2,new PointF(82,245),new PointF(121,234),new PointF(139,211));
   Line(g,Color.FromArgb(220,37,39,84),5,new PointF(100,211),new PointF(121,193),new PointF(124,176));
   g.Restore(antler);
  }
  // A dark current joins the side singularities around the icon's lower edge.
  g.Restore(topDesign);
  for(int filament=0;filament<9;filament++)using(var connection=new GraphicsPath()){
   float wave=(float)Math.Sin(t+filament*.7)*9,shift=(filament-4)*4;
   connection.AddBezier(309,486,291+shift,652,406,727+wave,512,719+shift);
   connection.AddBezier(512,719+shift,644,731-wave,734-shift,644,715,486);
   using(var shadow=new Pen(Color.FromArgb(55,31,10,59),29))g.DrawPath(shadow,connection);
   using(var energy=new Pen(Color.FromArgb((int)(90+surge*55),65+filament*7,66+filament*8,170+filament*8),3))g.DrawPath(energy,connection);
  }
  for(int orb=0;orb<3;orb++){
   double direction=orb==1?-1:1,a=-Math.PI/2+orb*Math.PI*2/3;
   PointF head=orb==0?new PointF(512,240):orb==1?new PointF(301,480):new PointF(723,480);
   var orbSize=g.Save();g.TranslateTransform(head.X,head.Y);g.ScaleTransform(1.65f,1.65f);g.TranslateTransform(-head.X,-head.Y);
   Glow(g,head.X,head.Y,67+surge*8,Color.FromArgb(165,44,53,173));
   Glow(g,head.X,head.Y,44+surge*5,Color.FromArgb(215,38,185,242));
   using(var dark=new SolidBrush(Color.FromArgb(255,2,5,17)))g.FillEllipse(dark,head.X-23,head.Y-23,46,46);
   using(var rim=new Pen(Color.FromArgb(235,89,224,255),3))g.DrawEllipse(rim,head.X-25,head.Y-25,50,50);
   // Billowing void clouds and luminous eddies engulf the orbs.
   for(int cloud=0;cloud<22;cloud++){
    double angle=cloud*Math.PI*2/22+t;
    float swell=(float)(.5+.5*Math.Sin(t*2+cloud*1.7)),r=28+swell*9;
    float x=head.X+(float)Math.Cos(angle)*r,y=head.Y+(float)Math.Sin(angle)*r;
    Glow(g,x,y,19+swell*8,Color.FromArgb(135,19,8,43));
    Glow(g,x,y,10+swell*7,Color.FromArgb(105,67,107,205));
   }
   for(int eddy=0;eddy<4;eddy++)using(var curl=new GraphicsPath()){
    float r=29+eddy*3;
    curl.AddArc(head.X-r,head.Y-r,r*2,r*2,(float)(t*180/Math.PI)+eddy*90,64);
    using(var haze=new Pen(Color.FromArgb(80,47,117,220),11))g.DrawPath(haze,curl);
    using(var light=new Pen(Color.FromArgb(185,96,212,255),2.5f))g.DrawPath(light,curl);
   }
   g.Restore(orbSize);
  }
  // Feather the foreground off the points badge.
  for(int y=642;y<819;y++)for(int x=592;x<821;x++){
   float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));
   float alpha=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(x,y);
   if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*alpha),c.R,c.G,c.B));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[VoidweaverArt]::Write($destination)
