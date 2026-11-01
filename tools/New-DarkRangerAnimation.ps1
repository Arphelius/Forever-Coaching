param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Marksmanship-DarkRanger-v3'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class DarkRangerArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // Shroud drifts around the edges, leaving the central talent readable.
  for(int wisp=0;wisp<26;wisp++){
   double a=wisp*Math.PI*2/26;
   float x=512+(float)Math.Cos(a)*(230+(float)Math.Sin(t+wisp)*22),y=512+(float)Math.Sin(a)*229+(float)Math.Cos(t+wisp*2)*13;
   using(var mist=new GraphicsPath()){mist.AddEllipse(x-96,y-77,192,154);using(var fill=new PathGradientBrush(mist)){fill.CenterColor=Color.FromArgb(150,8,8,16);fill.SurroundColors=new Color[]{Color.FromArgb(0,8,7,15)};g.FillPath(fill,mist);}}
  }
  // A deep peaked cowl wraps the upper corners, with a visible inner opening.
  using(var hood=new GraphicsPath()){
   hood.AddBezier(296,503,279,345,361,201,503,166);
   hood.AddBezier(503,166,635,207,716,344,720,501);
   hood.AddLine(720,501,669,459);
   hood.AddBezier(669,459,644,335,573,284,509,277);
   hood.AddBezier(509,277,430,294,365,358,349,467);hood.CloseFigure();
   using(var cloth=new LinearGradientBrush(new PointF(300,220),new PointF(700,495),Color.FromArgb(255,59,43,69),Color.FromArgb(255,17,22,31)))g.FillPath(cloth,hood);
  }
  Stroke(g,Color.FromArgb(245,110,82,119),7,new PointF(309,461),new PointF(335,346),new PointF(408,258),new PointF(503,186),new PointF(595,258),new PointF(676,369),new PointF(705,474));
  Stroke(g,Color.FromArgb(255,33,28,45),13,new PointF(360,402),new PointF(414,316),new PointF(509,270),new PointF(596,320),new PointF(652,406));
  // Mask joins both cowl edges directly beneath a narrow red-eyed opening.
  var mask=g.Save();g.TranslateTransform(509,473);g.ScaleTransform(.92f,.86f);g.TranslateTransform(-509,-493);
  Poly(g,Color.FromArgb(250,35,34,48),new PointF(329,441),new PointF(412,432),new PointF(507,415),new PointF(598,434),new PointF(686,440),new PointF(663,514),new PointF(513,563),new PointF(355,518));
  Stroke(g,Color.FromArgb(255,95,78,110),5,new PointF(344,445),new PointF(427,449),new PointF(507,432),new PointF(591,450),new PointF(671,445));
  Stroke(g,Color.FromArgb(210,74,64,87),4,new PointF(369,493),new PointF(512,539),new PointF(648,492));
  g.Restore(mask);
  for(int side=-1;side<=1;side+=2){
   var eye=g.Save();g.TranslateTransform(509+side*65,387);g.RotateTransform(-side*12);
   using(var glow=new GraphicsPath()){glow.AddEllipse(-45,-24,90,48);using(var fill=new PathGradientBrush(glow)){fill.CenterColor=Color.FromArgb(110,224,14,35);fill.SurroundColors=new Color[]{Color.FromArgb(0,93,0,16)};g.FillPath(fill,glow);}}
   Poly(g,Color.FromArgb(255,227,32,48),new PointF(-33,-5),new PointF(-10,-10),new PointF(30,-4),new PointF(10,7),new PointF(-14,5));
   Stroke(g,Color.FromArgb(255,255,151,137),3,new PointF(-19,-3),new PointF(14,-3));g.Restore(eye);
  }
  // A recurved dark bow is drawn toward the right; the arrow is nocked to it.
  using(var bow=new GraphicsPath()){
   bow.AddBezier(698,367,708,431,791,433,797,526);
   bow.AddBezier(797,526,803,602,731,644,710,701);
   using(var body=new Pen(Color.FromArgb(255,44,35,48),20)){body.StartCap=body.EndCap=LineCap.Round;g.DrawPath(body,bow);}
   using(var edge=new Pen(Color.FromArgb(255,147,111,156),5))g.DrawPath(edge,bow);
  }
  Stroke(g,Color.FromArgb(230,177,151,198),2,new PointF(698,367),new PointF(633,526),new PointF(710,701));
  Stroke(g,Color.FromArgb(255,124,103,135),6,new PointF(633,526),new PointF(930,526));
  Poly(g,Color.FromArgb(255,103,62,127),new PointF(640,526),new PointF(667,509),new PointF(694,509),new PointF(672,526),new PointF(694,543),new PointF(667,543));
  Poly(g,Color.FromArgb(255,211,183,231),new PointF(947,526),new PointF(907,507),new PointF(916,526),new PointF(907,545));
  // Purple-black energy coils along the arrow and gathers on its broadhead.
  for(int ribbon=0;ribbon<3;ribbon++){
   var p=new PointF[32];for(int j=0;j<32;j++){float x=680+j*8;p[j]=new PointF(x,526+(float)Math.Sin(j*.47-t*3+ribbon*2)* (7+ribbon*3));}
   Stroke(g,Color.FromArgb(38,148,55,207),17,p);Stroke(g,Color.FromArgb(170,185,109,234),3,p);
  }
  for(int mote=0;mote<12;mote++){
   float p=(float)((f/36.0+mote*.137)%1),x=865+p*70,y=526+(float)Math.Sin(t*2+mote)* (13+p*20);
   using(var spark=new SolidBrush(Color.FromArgb((int)(Math.Sin(p*Math.PI)*200),198,139,245)))g.FillEllipse(spark,x,y,4,4);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[DarkRangerArt]::Write($destination)
Write-Output "Created Dark Ranger animation: $destination"
