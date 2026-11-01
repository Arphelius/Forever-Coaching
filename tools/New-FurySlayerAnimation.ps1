param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Fury-Slayer-v1'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SlayerArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new[]{Color.Transparent};g.FillPath(b,p);}}}
 static PointF Orbit(double a,float r){return P(512+(float)Math.Cos(a)*r,512+(float)Math.Sin(a)*r*.88f);}
 static void Blade(Graphics g,double phase){var s=g.Save();g.TranslateTransform(512,512);g.RotateTransform((float)(phase*180/Math.PI));g.TranslateTransform(166,0);g.RotateTransform(28);
  // Broad, hooked steel blades with blackened spines and incandescent cutting edges.
  using(var blade=new GraphicsPath()){
   blade.AddBezier(-24,-34,-65,-112,-45,-187,61,-251);
   blade.AddBezier(61,-251,30,-188,49,-131,5,-29);blade.CloseFigure();
   using(var fill=new LinearGradientBrush(P(-55,-150),P(39,-132),Color.FromArgb(255,26,26,35),Color.FromArgb(255,177,173,153)))g.FillPath(fill,blade);
   using(var edge=new Pen(Color.FromArgb(255,80,64,47),4))g.DrawPath(edge,blade);
  }
  using(var edge=new GraphicsPath()){edge.AddBezier(61,-251,30,-188,49,-131,5,-29);
   using(var glow=new Pen(Color.FromArgb(65,255,61,1),23))g.DrawPath(glow,edge);
   using(var gold=new Pen(Color.FromArgb(255,255,127,21),8))g.DrawPath(gold,edge);
   using(var white=new Pen(Color.FromArgb(255,255,228,137),3))g.DrawPath(white,edge);
  }
  Line(g,Color.FromArgb(230,224,203,154),3,P(-26,-66),P(-29,-113),P(-14,-167),P(38,-222));
  Poly(g,Color.FromArgb(255,42,26,30),P(-25,-118),P(1,-137),P(-5,-162),P(18,-181),P(3,-139),P(-9,-126));
  Poly(g,Color.FromArgb(255,87,52,30),P(-48,-40),P(-23,-54),P(0,-39),P(34,-54),P(53,-34),P(15,-17),P(-19,-20));
  Line(g,Color.FromArgb(255,225,161,71),4,P(-43,-39),P(-19,-43),P(0,-31),P(31,-42),P(48,-34));
  Line(g,Color.FromArgb(255,29,22,24),22,P(-3,-18),P(-3,58));
  for(int i=0;i<7;i++)Line(g,Color.FromArgb(255,126,68,47),3,P(-13,-10+i*9),P(7,-3+i*9));
  Poly(g,Color.FromArgb(255,171,112,53),P(-16,58),P(-3,75),P(12,58),P(-3,48));
  // Gauntlets connect the weapons to the icon's sides.
  Poly(g,Color.FromArgb(255,50,35,32),P(-26,0),P(-7,-11),P(15,2),P(22,30),P(1,42),P(-25,28));
  for(int i=0;i<3;i++)Line(g,Color.FromArgb(240,165,109,65),3,P(-21,5+i*8),P(4,11+i*8),P(11,7+i*8));
  g.Restore(s);
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f/36.0*Math.PI*4;
  float rage=(float)(.5+.5*Math.Sin(t*2));
  // Rage burns through the artwork while the two blades carve a continuous whirlwind.
  var face=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  using(var heat=new SolidBrush(Color.FromArgb((int)(19+rage*20),167,18,6)))g.FillRectangle(heat,309,309,406,406);
  Glow(g,512,512,224,Color.FromArgb((int)(30+rage*42),228,38,2));g.Restore(face);
  for(int side=0;side<2;side++){
   double head=t+side*Math.PI-.8;
   for(int strip=0;strip<4;strip++)for(int step=0;step<48;step++){
    float u=step/48f,v=(step+1)/48f;double a=head-u*2.35,b=head-v*2.35;
    float ripple=(float)Math.Sin(a*9-t*3+strip)*5;
    float radius=252+strip*12+ripple,width=(21-strip*3)*(1-u)*(1-u)+1;
    int alpha=(int)((1-u)*(strip==0?170:100));
    Poly(g,Color.FromArgb(alpha,255,strip==0?121:52,strip==0?21:5),Orbit(a,radius-width),Orbit(a,radius+width),Orbit(b,radius+width*.94f),Orbit(b,radius-width*.94f));
    if(strip==0&&step<31)Line(g,Color.FromArgb((int)((1-u)*220),255,219,124),3*(1-u)+1,Orbit(a,radius),Orbit(b,radius));
   }
  }
  for(int spark=0;spark<48;spark++){
   float age=(float)((f/36.0*2+spark*.137)%1);double a=t-spark*.29-age*.6;
   PointF q=Orbit(a,256+age*76+(spark%4)*6);
   float alpha=(float)Math.Sin(age*Math.PI);Glow(g,q.X,q.Y,5+spark%3,Color.FromArgb((int)(alpha*180),255,122+spark%4*22,21));
   if(spark%3==0){PointF tail=Orbit(a-.05,256+age*76+(spark%4)*6);Line(g,Color.FromArgb((int)(alpha*190),255,201,91),2,q,tail);}
  }
  // The icon acts as the body: paired weapons rotate in opposing hands.
  Blade(g,t);Blade(g,t+Math.PI);
  for(int yy=642;yy<819;yy++)for(int xx=592;xx<821;xx++){
   float dx=Math.Max(0,Math.Max(620-xx,xx-793)),dy=Math.Max(0,Math.Max(670-yy,yy-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(xx,yy);if(c.A>0)im.SetPixel(xx,yy,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[SlayerArt]::Write($destination)
