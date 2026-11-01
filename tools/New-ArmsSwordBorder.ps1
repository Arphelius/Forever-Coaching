param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Arms-SwordBorder-v3'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ArmsBorderArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Sword(Graphics g,float x,float y,float angle){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle-20);g.ScaleTransform(1.1f,1.1f);
  Poly(g,Color.FromArgb(255,28,34,39),P(-13,-51),P(0,-78),P(13,-51),P(10,20),P(-10,20));
  Poly(g,Color.FromArgb(255,191,201,200),P(-9,-50),P(0,-72),P(9,-50),P(7,18),P(-7,18));
  Poly(g,Color.FromArgb(255,81,98,105),P(0,-69),P(7,-49),P(5,16),P(0,16));
  using(var pen=new Pen(Color.FromArgb(255,240,242,223),2))g.DrawLine(pen,-6,-47,-5,15);
  Poly(g,Color.FromArgb(255,50,41,32),P(-24,17),P(24,17),P(21,27),P(-21,27));
  using(var pen=new Pen(Color.FromArgb(255,181,149,90),4))g.DrawLine(pen,-22,20,22,20);
  using(var pen=new Pen(Color.FromArgb(255,74,48,33),10))g.DrawLine(pen,0,28,0,53);
  for(int i=0;i<3;i++)using(var pen=new Pen(Color.FromArgb(255,165,137,91),2))g.DrawLine(pen,-4,31+i*7,4,34+i*7);
  Poly(g,Color.FromArgb(255,155,144,113),P(0,65),P(-9,56),P(0,48),P(9,56));g.Restore(s);
 }
 public static void Write(string dir){using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  for(int i=0;i<3;i++){float p=365+i*139;Sword(g,p,300,90);Sword(g,724,p,180);Sword(g,300,p,0);Sword(g,p,724,270);}
  for(int y=652;y<804;y++)for(int x=605;x<809;x++){Color c=im.GetPixel(x,y);float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/16);if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(dir,"enhancement_0000.png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[ArmsBorderArt]::Write($destination)
