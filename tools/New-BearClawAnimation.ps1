param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Bear-DruidOfTheClaw-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class BearClawArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Fang(Graphics g,float x,float y,float side,float length){
  using(var shape=new GraphicsPath()){
   shape.AddBezier(x-18,y,x-17,y+side*length*.45f,x+2,y+side*length*.9f,x+16,y+side*length);
   shape.AddBezier(x+16,y+side*length,x+20,y+side*length*.46f,x+23,y+side*length*.19f,x+16,y);shape.CloseFigure();
   using(var ivory=new LinearGradientBrush(new PointF(x-18,y),new PointF(x+16,y+side*length),Color.FromArgb(255,169,150,103),Color.FromArgb(255,255,242,199)))g.FillPath(ivory,shape);
  }
  Stroke(g,Color.FromArgb(255,255,245,207),3,new PointF(x-10,y+side*10),new PointF(x-3,y+side*length*.51f),new PointF(x+13,y+side*length*.88f));
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  // Keep the approved fanged mouth, without the circular brown muzzle.
  Fang(g,347,365,1,120);Fang(g,653,365,1,120);
  Fang(g,350,662,-1,90);Fang(g,642,658,-1,85);
  for(int tooth=0;tooth<7;tooth++){
   float tx=401+tooth*35,ty=326+Math.Abs(tooth-3)*7;
   Fang(g,tx,ty,1,31+tooth%2*9);
   if(tooth<6)Fang(g,tx,712-Math.Abs(tooth-3)*4,-1,25+tooth%2*9);
  }
  // Swipe upper-left to lower-right; the entire hand faces into the stroke.
  float progress=Math.Max(0,Math.Min(1,(f-6)/7f));
  float fade=f<6?0:f<=17?1:Math.Max(0,(27-f)/10f);
  var scratch=g.Save();g.ExcludeClip(new Rectangle(653,655,100,94));
  // Match the user's drawing: fingertips upper-left, palm lower-right,
  // with the whole hand dragging down-right instead of pointing into its travel.
  if(f>=4&&f<=19){
   float visibility=f<6?(f-3)/3f:f>14?(20-f)/6f:1;
   int alpha=(int)(visibility*255);
   float px=320+(568-320)*progress+(float)Math.Sin(progress*Math.PI)*24,py=396+(650-396)*progress;
   float spacing=43-5*progress,stepY=12+2*progress;
   var hand=g.Save();g.TranslateTransform(px,py);
   using(var palm=new GraphicsPath()){
    palm.AddBezier(28,81,25,32,146,-7,189,27);
    palm.AddBezier(189,27,218,48,254,120,256,176);
    palm.AddBezier(256,176,221,202,198,223,171,243);
    palm.AddBezier(171,243,94,213,64,174,28,81);palm.CloseFigure();
    using(var skin=new LinearGradientBrush(new PointF(61,32),new PointF(229,221),Color.FromArgb(alpha,124,88,56),Color.FromArgb(alpha,42,33,28)))g.FillPath(skin,palm);
   }
   for(int finger=0;finger<4;finger++){
    float cx=finger*spacing+47,cy=-finger*stepY+57;
    var knuckle=g.Save();g.TranslateTransform(cx,cy);g.RotateTransform(-34);
    using(var flesh=new LinearGradientBrush(new PointF(-22,-32),new PointF(24,42),Color.FromArgb(alpha,141,104,67),Color.FromArgb(alpha,74,53,37)))g.FillEllipse(flesh,-23,-33,46,80);
    Stroke(g,Color.FromArgb((int)(visibility*175),57,40,30),3,new PointF(-15,8),new PointF(0,12),new PointF(15,8));g.Restore(knuckle);
   }
   for(int tuft=0;tuft<32;tuft++){
    float x=69+tuft%8*19,y=91+tuft/8*23;
    Stroke(g,Color.FromArgb((int)(visibility*135),tuft%2==0?157:56,tuft%2==0?115:42,tuft%2==0?72:31),2,new PointF(x,y),new PointF(x+12,y+22));
   }
   g.Restore(hand);
  }
  for(int claw=0;claw<4;claw++){
   float sx=320+claw*43,sy=396-claw*12,ex=568+claw*38,ey=650-claw*14;
   float x=sx+(ex-sx)*progress+(float)Math.Sin(progress*Math.PI)*24,y=sy+(ey-sy)*progress;
   if(fade>0){
    var cut=new PointF[20];for(int j=0;j<20;j++){float u=progress*j/19f;cut[j]=new PointF(sx+(ex-sx)*u+(float)Math.Sin(u*Math.PI)*24,sy+(ey-sy)*u);}
    Stroke(g,Color.FromArgb((int)(fade*240),21,18,18),14,cut);
    Stroke(g,Color.FromArgb((int)(fade*215),216,131,50),5,cut);
    Stroke(g,Color.FromArgb((int)(fade*200),255,217,137),2,cut);
   }
   if(f>=6&&f<=14){
    int alpha=f==14?130:255;
    var clawState=g.Save();g.TranslateTransform(x,y);g.RotateTransform(146);
    using(var talon=new GraphicsPath()){
     talon.AddBezier(-23,-103,-48,-70,-29,-22,0,9);
     talon.AddBezier(0,9,15,-26,22,-66,9,-100);talon.CloseFigure();
     using(var ivory=new LinearGradientBrush(new PointF(-20,-100),new PointF(0,9),Color.FromArgb(alpha,85,81,67),Color.FromArgb(alpha,255,240,201)))g.FillPath(ivory,talon);
    }
    Stroke(g,Color.FromArgb(alpha,255,246,219),3,new PointF(-16,-87),new PointF(-20,-48),new PointF(-3,-4));
    g.Restore(clawState);
   }
  }
  g.Restore(scratch);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[BearClawArt]::Write($destination)
Write-Output "Created bear claw animation: $destination"
