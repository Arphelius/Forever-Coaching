param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Enhancement-Totemic-v3'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class PaintedTotem {
 public static void Write(string source,string output){using(var art=Image.FromFile(source)){
 for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;g.InterpolationMode=InterpolationMode.HighQualityBicubic;
  // Animate the elemental silhouette while keeping the connected carved trunk rigid.
  for(int x=0;x<1024;x+=8){float weight=Math.Max(0,Math.Abs(x-512)/512f-.22f);
   float offset=(float)Math.Sin(t*2+x*.012)*weight*13;
   g.DrawImage(art,new RectangleF(x,offset,8,1024),new RectangleF(x*art.Width/1024f,0,8*art.Width/1024f,art.Height),GraphicsUnit.Pixel);
  }
  // Orb trails circle the totem, with separate phases and opposing directions.
  Color[] colors={Color.FromArgb(255,161,36),Color.FromArgb(192,247,255),Color.FromArgb(34,177,255),Color.FromArgb(90,241,53)};
  for(int orb=0;orb<4;orb++){
   double a=(orb%2==0?t:-t)+orb*Math.PI/2;
   float cx=512+(float)Math.Cos(a)*327,cy=534+(float)Math.Sin(a)*306;
   for(int tail=12;tail>=1;tail--){double b=a+(orb%2==0?-1:1)*tail*.055;float bx=512+(float)Math.Cos(b)*327,by=534+(float)Math.Sin(b)*306;
    using(var trail=new SolidBrush(Color.FromArgb((13-tail)*8,colors[orb])))g.FillEllipse(trail,bx-9,by-9,18,18);
   }
   using(var orbPath=new GraphicsPath()){orbPath.AddEllipse(cx-24,cy-24,48,48);using(var fill=new PathGradientBrush(orbPath)){fill.CenterPoint=new PointF(cx-7,cy-9);fill.CenterColor=Color.FromArgb(250,239,255,249);fill.SurroundColors=new Color[]{Color.FromArgb(190,colors[orb])};g.FillPath(fill,orbPath);}}
   using(var rim=new Pen(Color.FromArgb(210,colors[orb]),2))g.DrawArc(rim,cx-18,cy-18,36,36,(float)(t*180/Math.PI),250);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[PaintedTotem]::Write((Join-Path $PSScriptRoot '../art/talent-effects/enhancement-totemic-painted-v3.png'),$destination)
Write-Output "Animated painted totem: $destination"
