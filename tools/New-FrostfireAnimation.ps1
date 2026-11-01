param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Frostfire-TwinMagic-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FrostfireArt {
 static PointF Flow(float p,int side,float offset){
  float q=1-p;
  float x=q*q*q*193+3*q*q*p*187+3*q*p*p*187;
  float y=q*q*q*715+3*q*q*p*440+3*q*p*p*235+p*p*p*298;
  return new PointF(512+side*(x+offset*(float)Math.Sin(p*Math.PI)),y);
 }
 static void Stroke(Graphics g,Color c,float width,PointF a,PointF b){using(var pen=new Pen(c,width)){pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLine(pen,a,b);}}
 static void Glow(Graphics g,float x,float y,float r,Color color){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=color;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  for(int side=-1;side<=1;side+=2){
   // Discrete material with open space between clusters; no continuous strip.
   for(int cluster=0;cluster<38;cluster++){
    float p=(float)((cluster*.02631+f/36.0)%1);
    float offset=(float)Math.Sin(cluster*7.31)*50;
    PointF root=Flow(p,side,offset);
    float flicker=(float)(.5+.5*Math.Sin(t*3+cluster*2.7));
    int alpha=(int)(70+flicker*150);
    if(side>0){
     Glow(g,root.X,root.Y,30,Color.FromArgb(50,255,58,0));
     float h=22+flicker*34,w=7+cluster%4*2.5f;
     float sway=(float)Math.Sin(t*3+cluster)*12;
     using(var flame=new GraphicsPath()){
      flame.AddBezier(root.X-w,root.Y,root.X-w*2,root.Y-h*.5f,root.X+sway,root.Y-h*.4f,root.X+sway,root.Y-h);
      flame.AddBezier(root.X+sway,root.Y-h,root.X+w*2,root.Y-h*.4f,root.X+w,root.Y-8,root.X-w,root.Y);flame.CloseFigure();
      using(var fire=new LinearGradientBrush(new PointF(root.X,root.Y),new PointF(root.X,root.Y-h),Color.FromArgb(alpha,255,177,31),Color.FromArgb(0,255,42,0)))g.FillPath(fire,flame);
     }
     Stroke(g,Color.FromArgb(alpha,255,234,126),2,new PointF(root.X,root.Y-4),new PointF(root.X+sway*.5f,root.Y-h*.5f));
     for(int coal=0;coal<6;coal++){
      float cx=root.X+(float)Math.Sin(cluster*3+coal*7)*12,cy=root.Y-coal*7;
      Glow(g,cx,cy,8,Color.FromArgb(alpha/2,255,67,0));
      using(var ember=new SolidBrush(Color.FromArgb(alpha,255,204,80)))g.FillPolygon(ember,new PointF[]{new PointF(cx-2,cy-4),new PointF(cx+3,cy-2),new PointF(cx+2,cy+3),new PointF(cx-3,cy+2)});
     }
    }else{
     for(int tooth=0;tooth<3;tooth++){
      float h=27+(cluster*13+tooth*17)%42,w=7+(cluster+tooth)%3*3.5f;
      float x=root.X+(tooth-1)*13,y=root.Y+tooth*5;
      PointF tip=new PointF(x-11+tooth*5,y-h),ridge=new PointF(x,y-h*.38f);
      PointF[] shape=new PointF[]{new PointF(x-w,y-3),new PointF(x-w,y-15),tip,new PointF(x+w,y-12),new PointF(x+w,y+3)};
      using(var glacier=new LinearGradientBrush(new PointF(x-w,y),new PointF(x+w,y-h),Color.FromArgb(210,25,103,171),Color.FromArgb(230,166,234,255)))g.FillPolygon(glacier,shape);
      using(var face=new SolidBrush(Color.FromArgb(190,192,245,255)))g.FillPolygon(face,new PointF[]{tip,ridge,new PointF(x+w,y+3),new PointF(x+w,y-12)});
      Stroke(g,Color.FromArgb(230,232,253,255),1.8f,tip,ridge);
      Stroke(g,Color.FromArgb(150,104,196,237),1,new PointF(x-w,y-3),ridge);
     }
    }
   }
   // Particles shed outward as the elements rise, replacing the braided tubes.
   for(int mote=0;mote<58;mote++){
    float age=(float)((f/36.0+mote*.173)%1),p=(float)((mote*.137+age*.24)%1);
    PointF source=Flow(p,side,0);
    float x=source.X+side*age*(25+mote%4*9),y=source.Y-age*(28+mote%5*9);
    int alpha=(int)(Math.Sin(age*Math.PI)*225);
    if(side<0){
     using(var ice=new SolidBrush(Color.FromArgb(alpha,167,235,255)))g.FillPolygon(ice,new PointF[]{new PointF(x,y-6),new PointF(x-3,y+4),new PointF(x+4,y+2)});
    }else{
     Stroke(g,Color.FromArgb(alpha/3,255,58,1),8,new PointF(x,y+7),new PointF(x,y));
     Stroke(g,Color.FromArgb(alpha,255,173+mote%3*25,40),2.5f,new PointF(x,y+4),new PointF(x+2,y-3));
    }
   }
  }
  // A small volatile meeting point above the artwork.
  for(int spark=0;spark<14;spark++){
   float age=(float)((f/36.0+spark*.073)%1),angle=spark*2.4f;
   float x=512+(float)Math.Cos(angle)*age*41,y=298+(float)Math.Sin(angle)*age*24;
   using(var brush=new SolidBrush(Color.FromArgb((int)((1-age)*190),spark%2==0?135:255,spark%2==0?228:177,spark%2==0?255:63)))g.FillEllipse(brush,x,y,3,5);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[FrostfireArt]::Write($destination)
