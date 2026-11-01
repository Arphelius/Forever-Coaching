param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Balance-ElunesChosen-v4'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class BalanceEclipseArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // A soft eclipse shadow darkens the talent without replacing its artwork.
  using(var shadow=new GraphicsPath()){shadow.AddEllipse(306,307,412,412);using(var fill=new PathGradientBrush(shadow)){fill.CenterColor=Color.FromArgb(55,12,13,44);fill.SurroundColors=new Color[]{Color.FromArgb(0,23,21,55)};g.FillPath(fill,shadow);}}
  // Moonlight and sunlight pour from the eclipse onto opposite parts of the icon.
  for(int side=-1;side<=1;side+=2){
   Color light=side==-1?Color.FromArgb(127,153,255):Color.FromArgb(255,190,54);
   for(int sheet=0;sheet<3;sheet++){
    float x=512+side*(58+sheet*14),bottom=512+side*(91+sheet*46);
    using(var beam=new GraphicsPath()){
     beam.AddPolygon(new PointF[]{new PointF(x-10,285),new PointF(x+10,285),new PointF(bottom+35,721),new PointF(bottom-35,721)});
     using(var fill=new LinearGradientBrush(new PointF(x,285),new PointF(bottom,721),Color.FromArgb(85,light),Color.FromArgb(10,light)))g.FillPath(fill,beam);
    }
   }
   for(int ray=0;ray<7;ray++){
    float p=(float)((f/36.0+ray/7.0)%1),x=512+side*(49+ray*16),y=344+p*329;
    Stroke(g,Color.FromArgb((int)(Math.Sin(p*Math.PI)*65),light),13,new PointF(x-side*13,y-48),new PointF(x+side*10,y+23));
    Stroke(g,Color.FromArgb((int)(Math.Sin(p*Math.PI)*230),light),ray%3==0?6:4,new PointF(x-side*13,y-48),new PointF(x+side*10,y+23));
   }
  }
  // Left half is total eclipse; right half remains the unveiled golden sun.
  var eclipse=g.Save();g.SetClip(new Rectangle(350,65,162,320));
  using(var rim=new SolidBrush(Color.FromArgb(255,170,203,255)))g.FillEllipse(rim,397,117,230,230);
  using(var moon=new LinearGradientBrush(new PointF(405,140),new PointF(512,325),Color.FromArgb(255,24,28,62),Color.FromArgb(255,7,12,31)))g.FillEllipse(moon,405,125,214,214);
  g.Restore(eclipse);
  var solar=g.Save();g.SetClip(new Rectangle(512,65,175,320));
  using(var disk=new GraphicsPath()){
   disk.AddEllipse(397,117,230,230);
   using(var sun=new PathGradientBrush(disk)){sun.CenterPoint=new PointF(547,204);sun.CenterColor=Color.FromArgb(255,255,248,184);sun.SurroundColors=new Color[]{Color.FromArgb(255,244,145,26)};g.FillPath(sun,disk);}
  }
  for(int curl=0;curl<3;curl++)using(var flare=new Pen(Color.FromArgb(90,255,255,199),3))g.DrawArc(flare,472+curl*18,155+curl*20,91-curl*12,116-curl*18,(float)(t*180/Math.PI)+curl*90,165);
  g.Restore(solar);
  using(var lunarRim=new Pen(Color.FromArgb(250,172,223,255),6))g.DrawArc(lunarRim,401,121,222,222,90,180);
  using(var solarRim=new Pen(Color.FromArgb(245,255,218,112),5))g.DrawArc(solarRim,398,118,228,228,270,180);
  // Small stars drift around the talent, keeping its rank clear.
  for(int star=0;star<18;star++){
   double a=star*Math.PI*2/18;float r=246+(float)Math.Sin(t+star)*13,x=512+(float)Math.Cos(a)*r,y=515+(float)Math.Sin(a)*r;
   if(x>640&&y>640)continue;
   int alpha=(int)(130+100*(.5+.5*Math.Sin(t+star*2)));
   Color c=star%2==0?Color.FromArgb(alpha,181,217,255):Color.FromArgb(alpha,255,214,136);
   Stroke(g,c,2,new PointF(x-4,y),new PointF(x+4,y));Stroke(g,c,2,new PointF(x,y-5),new PointF(x,y+5));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[BalanceEclipseArt]::Write($destination)
Write-Output "Created Balance eclipse: $destination"
