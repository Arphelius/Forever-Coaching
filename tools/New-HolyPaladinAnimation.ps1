param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/HolyPaladin-animation-v34'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class HolyPaladinArt {
 static void Line(Graphics g,Color c,float width,params PointF[] p){using(var pen=new Pen(c,width)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void HolyFireMaterial(Bitmap image,double t){
  for(int y=0;y<1024;y++)for(int x=0;x<1024;x++){
   Color c=image.GetPixel(x,y);if(c.A<3||c.R<160||c.R<c.B*1.12f)continue;
   // Preserve the original golden cores, blending orange into their softer edges.
   float gold=c.G/255f;
   float eddy=(float)(.5+.5*Math.Sin(x*.026+Math.Sin(y*.023-t*2)*1.3+t*2));
   float heat=Math.Max(0,Math.Min(1,gold*.82f+eddy*.18f));
   int green=(int)(96+heat*154),blue=(int)(6+heat*heat*143);
   image.SetPixel(x,y,Color.FromArgb(c.A,255,green,blue));
  }
 }
 public static void Write(string dir){
  for(int frame=0;frame<36;frame++)using(var image=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)){
   double t=frame*Math.PI*2/36;float breath=(float)(.5+.5*Math.Sin(t));
   using(var g=Graphics.FromImage(image)){
    g.SmoothingMode=SmoothingMode.AntiAlias;
    var crownPosition=g.Save();g.TranslateTransform(0,-55);
    // Concentrated crown of sunlight rises from just above the talent.
    using(var halo=new GraphicsPath()){
     halo.AddEllipse(402,157,220,294);
     using(var glow=new PathGradientBrush(halo)){
      glow.CenterPoint=new PointF(512,350);
      glow.CenterColor=Color.FromArgb((int)(165+breath*50),255,234,113);
      glow.SurroundColors=new Color[]{Color.Transparent};g.FillPath(glow,halo);
     }
    }
    for(int ray=0;ray<17;ray++){
     float offset=ray-8,pulse=(float)(.5+.5*Math.Sin(t*2+ray*1.73));
     float rootX=512+offset*13,rootY=392+(ray%3)*9;
     float tipX=512+offset*6+(float)Math.Sin(t+ray*2.1)*10;
     float tipY=72+Math.Abs(offset)*15+(ray*37)%67-pulse*24;
     float w=12+(ray*13)%17,midY=(rootY+tipY)*.5f;
     float bend=(float)Math.Sin(t*2+ray)*14;
     using(var light=new GraphicsPath()){
      light.AddPolygon(new PointF[]{
       new PointF(rootX-w,rootY),new PointF(rootX-w-7,rootY-44),
       new PointF(rootX-w*.5f+bend,midY+35),new PointF(rootX-w-12,midY+10),
       new PointF(tipX-7,midY-23),new PointF(tipX-13,tipY+57),new PointF(tipX,tipY),
       new PointF(tipX+9,tipY+59),new PointF(tipX+5,midY-12),
       new PointF(rootX+w+8+bend,midY+22),new PointF(rootX+w*.5f,midY+31),
       new PointF(rootX+w+5,rootY-30),new PointF(rootX+w,rootY)});
      using(var fill=new LinearGradientBrush(new PointF(rootX,rootY),new PointF(tipX,tipY),Color.FromArgb((int)(60+pulse*40),255,231,111),Color.FromArgb(8,255,247,185)))g.FillPath(fill,light);
     }
    }
    g.Restore(crownPosition);
    var wings=g.Save();g.TranslateTransform(512,512);g.ScaleTransform(.82f,.82f);g.TranslateTransform(-512,-512);
    // Long upward-sweeping feathers form wings of sunlight, without armor.
    for(int side=-1;side<=1;side+=2){
     for(int feather=0;feather<9;feather++){
      float lift=(float)Math.Sin(t+feather*.22)*12;
      float rootX=512+side*(145+feather*5),rootY=479+feather*7;
      float tipX=512+side*(390-feather*16),tipY=161+feather*29+lift;
      using(var wing=new GraphicsPath()){
       wing.AddBezier(rootX,rootY,512+side*330,rootY-80,tipX-side*15,tipY+125,tipX,tipY);
       wing.AddBezier(tipX,tipY,tipX-side*77,tipY+136,rootX+side*19,rootY-57,rootX,rootY);
       using(var fire=new LinearGradientBrush(new PointF(rootX,rootY),new PointF(tipX,tipY),Color.FromArgb(245,255,123,4),Color.FromArgb(205,255,232,66)))g.FillPath(fire,wing);
       using(var edge=new Pen(Color.FromArgb(190,255,224,73),3))g.DrawPath(edge,wing);
      }
      Line(g,Color.FromArgb(130,255,250,189),4,new PointF(rootX,rootY-12),new PointF(rootX+side*70,rootY-95),new PointF(tipX,tipY+16));
     }
    }
    // Small overlapping light feathers give the broad wings a finer texture.
    for(int side=-1;side<=1;side+=2)for(int feather=0;feather<12;feather++){
     float p=feather/11f;
     float x=512+side*(176+p*171),y=493-p*270+(feather%2)*9;
     float length=31+feather%3*7;
     float flutter=(float)Math.Sin(t+feather*.83)*3;
     using(var plume=new GraphicsPath()){
      plume.AddBezier(x,y,x+side*8,y-length*.6f,x+side*18,y-length+flutter,x+side*23,y-length-9+flutter);
      plume.AddBezier(x+side*23,y-length-9+flutter,x+side*20,y-7,x+side*9,y+6,x,y);plume.CloseFigure();
      using(var shadow=new Pen(Color.FromArgb(175,174,86,11),4))g.DrawPath(shadow,plume);
      using(var light=new LinearGradientBrush(new PointF(x,y),new PointF(x+side*23,y-length-9),Color.FromArgb(215,255,218,113),Color.FromArgb(255,255,253,228)))g.FillPath(light,plume);
     }
     Line(g,Color.FromArgb(245,255,254,233),2.5f,new PointF(x+side*3,y-2),new PointF(x+side*20,y-length-5+flutter));
    }
    // Dense rising sparks and flame wisps travel along the golden wings.
    for(int side=-1;side<=1;side+=2)for(int spark=0;spark<30;spark++){
     float age=(float)((frame/36.0+spark*.137)%1);
     float x=512+side*(175+age*197)+(float)Math.Sin(t*2+spark)*15,y=551-age*357;
     int alpha=(int)(Math.Sin(age*Math.PI)*225);
     Line(g,Color.FromArgb(alpha/2,255,120,0),9,new PointF(x,y+17),new PointF(x+side*5,y));
     Line(g,Color.FromArgb(alpha,255,226,79),2,new PointF(x,y+10),new PointF(x+side*5,y));
    }
    g.Restore(wings);
    // Holy-fire sparks rise between the wings and resolve into small crosses.
    for(int mote=0;mote<25;mote++){
     float p=(float)((frame/36.0+mote*.137)%1),x=512+(float)Math.Sin(mote*4.1+t)* (65+p*150),y=743-p*489;
     int alpha=(int)(Math.Sin(p*Math.PI)*235);float size=4+mote%3*2;
     Line(g,Color.FromArgb(alpha,255,246,189),3,new PointF(x-size,y),new PointF(x+size,y));
     Line(g,Color.FromArgb(alpha,255,246,189),3,new PointF(x,y-size*1.5f),new PointF(x,y+size*1.5f));
    }
   }
   // Feather all foreground effects away from the rank badge, avoiding a hard cut.
   for(int y=610;y<862;y++)for(int x=548;x<852;x++){
    float dx=Math.Max(0,Math.Max(580-x,x-820));
    float dy=Math.Max(0,Math.Max(642-y,y-830));
    float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/32);
    fade=fade*fade*(3-2*fade);
    Color c=image.GetPixel(x,y);
    if(c.A>0)image.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));
   }
   HolyFireMaterial(image,t);
   image.Save(Path.Combine(dir,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
  }
 }
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[HolyPaladinArt]::Write($destination)
[IO.File]::WriteAllText((Join-Path $destination 'animation.json'),'{"fps":12,"frames":36,"durationSeconds":3,"width":1024,"height":1024,"alpha":true}')
Write-Output "Created Holy Paladin animation: $destination"
