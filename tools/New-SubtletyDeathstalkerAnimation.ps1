param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Subtlety-Deathstalker-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class DeathstalkerArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;float pulse=(float)(.5+.5*Math.Sin(t));
  // Black smoke conceals the spell; slow violet undertones give it depth.
  var face=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  using(var veil=new SolidBrush(Color.FromArgb(178,3,3,9)))g.FillRectangle(veil,309,309,406,406);
  for(int lane=0;lane<10;lane++)for(int puff=0;puff<4;puff++){
   float age=(float)((f/36.0+puff*.241+lane*.079)%1),x=315+lane*44+(float)Math.Sin(t+lane+age*5)*12,y=313+age*420;
   Glow(g,x,y,43,Color.FromArgb((int)(Math.Sin(age*Math.PI)*110),7,4,15));
   Glow(g,x-7,y,22,Color.FromArgb((int)(Math.Sin(age*Math.PI)*23),50,23,66));
  }
  g.Restore(face);
  for(int edge=0;edge<4;edge++)for(int wisp=0;wisp<19;wisp++){
   float age=(float)((f/36.0+wisp*.0527+edge*.17)%1),wave=(float)Math.Sin(t+wisp)*12;
   float x=(edge==0||edge==3)?295+age*434:(edge==1?294:730)+wave;
   float y=edge==0?296+wave:edge==3?730+wave:300+age*410;
   Glow(g,x,y,42,Color.FromArgb(100,8,5,17));Glow(g,x-8,y,23,Color.FromArgb(27,45,22,63));
  }
  // Only the cowl and red eyes emerge; no head, torso or humanoid body.
  var upperDesign=g.Save();g.TranslateTransform(0,-52);
  Glow(g,512,265,110,Color.FromArgb(120,13,9,24));
  using(var cowl=new GraphicsPath()){
   cowl.AddPolygon(new PointF[]{new PointF(413,318),new PointF(421,244),new PointF(452,197),new PointF(490,183),new PointF(512,165),new PointF(535,183),new PointF(572,197),new PointF(603,244),new PointF(611,318),new PointF(568,298),new PointF(556,243),new PointF(512,218),new PointF(468,243),new PointF(456,298)});
   using(var cloth=new LinearGradientBrush(new PointF(432,195),new PointF(587,316),Color.FromArgb(255,35,38,49),Color.FromArgb(255,7,8,16)))g.FillPath(cloth,cowl);
   using(var edge=new Pen(Color.FromArgb(190,65,70,89),3))g.DrawPath(edge,cowl);
  }
  Poly(g,Color.FromArgb(255,2,3,9),new PointF(469,245),new PointF(512,219),new PointF(555,245),new PointF(565,294),new PointF(512,313),new PointF(459,294));
  // Wrapped mask joins the hood immediately below the glowing eyes.
  Poly(g,Color.FromArgb(255,35,29,46),new PointF(465,275),new PointF(490,271),new PointF(512,281),new PointF(535,271),new PointF(559,275),new PointF(551,301),new PointF(512,319),new PointF(474,302));
  Line(g,Color.FromArgb(180,74,61,91),2,new PointF(475,283),new PointF(512,294),new PointF(550,283));
  Line(g,Color.FromArgb(150,58,47,75),2,new PointF(482,295),new PointF(512,304),new PointF(542,295));
  for(int side=-1;side<=1;side+=2){
   Glow(g,512+side*26,264,19,Color.FromArgb((int)(95+pulse*65),162,5,22));
   Line(g,Color.FromArgb(245,233,20,38),4,new PointF(512+side*13,267),new PointF(512+side*39,259));
   Line(g,Color.FromArgb(230,255,104,106),1.5f,new PointF(512+side*18,265),new PointF(512+side*34,261));
   Line(g,Color.FromArgb(170,54,48,72),3,new PointF(512+side*13,198),new PointF(512+side*53,224),new PointF(512+side*71,287));
   // Shadow hands grip dark blades beside the hood, edged with violet magic.
   var weapon=g.Save();g.TranslateTransform(512+side*160,259);g.RotateTransform(side*34);
   // Reverse the blade around the grip; the hands keep their original placement.
   var bladeOrientation=g.Save();g.TranslateTransform(0,73);g.RotateTransform(180);g.TranslateTransform(0,-73);
   using(var blade=new GraphicsPath()){
    blade.AddBezier(-12,37,-29,-27,-20,-78,5,-138);
    blade.AddBezier(5,-138,6,-74,37,-31,13,37);blade.CloseFigure();
    using(var metal=new LinearGradientBrush(new PointF(-25,-35),new PointF(26,-35),Color.FromArgb(255,18,21,31),Color.FromArgb(255,65,75,91)))g.FillPath(metal,blade);
    using(var glow=new Pen(Color.FromArgb((int)(50+pulse*45),135,40,214),13))g.DrawPath(glow,blade);
    using(var edge=new Pen(Color.FromArgb(240,179,80,244),3))g.DrawPath(edge,blade);
   }
   Line(g,Color.FromArgb(170,108,81,149),2,new PointF(2,-126),new PointF(-6,-72),new PointF(7,-27),new PointF(2,28));
   Poly(g,Color.FromArgb(255,50,43,68),new PointF(-29,38),new PointF(-20,27),new PointF(0,36),new PointF(20,27),new PointF(29,38),new PointF(12,46),new PointF(-12,46));
   Line(g,Color.FromArgb(255,21,16,29),14,new PointF(0,49),new PointF(0,99));
   g.Restore(bladeOrientation);
   Poly(g,Color.FromArgb(245,22,20,32),new PointF(-34,59),new PointF(-16,51),new PointF(12,57),new PointF(23,75),new PointF(13,97),new PointF(-12,102),new PointF(-41,87));
   for(int finger=0;finger<4;finger++){
    float y=58+finger*9;
    Line(g,Color.FromArgb(250,47,44,61),7,new PointF(-17,y),new PointF(10,y-1),new PointF(16,y+5));
    Line(g,Color.FromArgb(140,88,74,108),1.5f,new PointF(-13,y-2),new PointF(7,y-2));
   }
   Line(g,Color.FromArgb(255,51,45,66),9,new PointF(-24,67),new PointF(-6,88),new PointF(9,86));
   for(int smoke=0;smoke<6;smoke++)Glow(g,-35-smoke*8,87+smoke*4,20,Color.FromArgb(90-smoke*10,10,6,21));
   g.Restore(weapon);
  }
  // Rolling shadow veils embrace the cowl, crown and gripping hands.
  for(int wisp=0;wisp<34;wisp++){
   float age=(float)((f/36.0+wisp*.02941)%1),angle=age*(float)(Math.PI*2);
   float x=512+(float)Math.Cos(angle)*119+(float)Math.Sin(t+wisp)*8;
   float y=246+(float)Math.Sin(angle)*85;
   float pulseMist=(float)(.5+.5*Math.Sin(t*2+wisp));
   Glow(g,x,y,28+pulseMist*13,Color.FromArgb(100,7,5,16));
   Glow(g,x-5,y,17,Color.FromArgb(25,58,28,78));
  }
  for(int side=-1;side<=1;side+=2)for(int wisp=0;wisp<7;wisp++){
   float age=(float)((f/36.0+wisp*.143)%1);
   float x=512+side*(67+age*67),y=297-age*80;
   Glow(g,x,y,24,Color.FromArgb((int)(Math.Sin(age*Math.PI)*90),9,5,20));
  }
  g.Restore(upperDesign);
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
[DeathstalkerArt]::Write($destination)
