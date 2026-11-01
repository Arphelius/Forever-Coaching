param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Arcane-Collapse-v1'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ArcaneCollapse {
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f/36.0*Math.PI*4;g.SmoothingMode=SmoothingMode.AntiAlias;
  using(var aura=new GraphicsPath()){aura.AddEllipse(162,162,700,700);using(var fill=new PathGradientBrush(aura)){fill.CenterColor=Color.FromArgb(200,110,36,196);fill.SurroundColors=new Color[]{Color.FromArgb(0,70,13,140)};g.FillPath(fill,aura);}}
  for(int arm=0;arm<9;arm++){
   var spiral=new PointF[70];for(int j=0;j<70;j++){float p=j/69f;double a=t+arm*Math.PI*2/9+p*3.7;float r=143+p*184;spiral[j]=new PointF(512+(float)Math.Cos(a)*r,512+(float)Math.Sin(a)*r);}
   using(var haze=new Pen(Color.FromArgb(55,153,63,247),22))g.DrawLines(haze,spiral);
   using(var light=new Pen(Color.FromArgb(220,195,129,255),5))g.DrawLines(light,spiral);
  }
  using(var disk=new SolidBrush(Color.FromArgb(255,2,1,7)))g.FillEllipse(disk,350,350,324,324);
  using(var ring=new Pen(Color.FromArgb(255,228,181,255),7))g.DrawEllipse(ring,346,346,332,332);
  using(var ring=new Pen(Color.FromArgb(130,123,66,238),15))g.DrawEllipse(ring,339,339,346,346);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[ArcaneCollapse]::Write($destination)
