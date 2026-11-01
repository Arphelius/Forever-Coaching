param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/ProtectionWarrior-ShoutBorder-v1'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
# Reuse the accepted VFX bulwark geometry so the smaller shields match it exactly.
$mountainSource=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'New-MountainThaneAnimation.ps1'))
$shieldStart=$mountainSource.IndexOf('  // Bowed siege steel:')
$shieldEnd=$mountainSource.IndexOf('  g.Restore(shieldPose);',$shieldStart)
if($shieldStart -lt 0 -or $shieldEnd -le $shieldStart){throw 'Cannot locate the accepted bulwark geometry.'}
$shieldBody=$mountainSource.Substring($shieldStart,$shieldEnd-$shieldStart)
$source=@'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ProtectionBorderArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Shield(Graphics g,float centerX,int side){var pose=g.Save();g.TranslateTransform(centerX,512);g.ScaleTransform(side*.64f,.64f);g.TranslateTransform(-355,-530);
__SHIELD_BODY__
  g.Restore(pose);
 }
 public static void Write(string dir){using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  // Cool gray pressure hugs the icon, with a restrained blue inner edge.
  for(int yy=279;yy<746;yy++)for(int xx=279;xx<746;xx++){
   double qx=Math.Abs(xx-512)-153,qy=Math.Abs(yy-512)-153,ax=Math.Max(qx,0),ay=Math.Max(qy,0);
   double edge=Math.Sqrt(ax*ax+ay*ay)+Math.Min(Math.Max(qx,qy),0)-50,distance=Math.Abs(edge);
   int a=(int)Math.Min(240,165*Math.Exp(-distance*distance/70)+55*Math.Exp(-distance*distance/300));
   if(a>0)im.SetPixel(xx,yy,Color.FromArgb(a,131,163,182));
  }
  // Broken, bowed shout waves sweep around the edges instead of framing a second square.
  for(int side=0;side<4;side++){var wave=g.Save();g.TranslateTransform(512,512);g.RotateTransform(side*90);
   for(int layer=0;layer<3;layer++)using(var path=new GraphicsPath()){
    float yy=-215-layer*13,x=-134+layer*19;
    path.AddBezier(x,yy+7,x+54,yy-16,59-layer*7,yy+12,139-layer*17,yy-6);
    using(var haze=new Pen(Color.FromArgb(25,160,167,174),18-layer*3))g.DrawPath(haze,path);
    using(var gray=new Pen(Color.FromArgb(165-layer*34,180,183,185),6-layer))g.DrawPath(gray,path);
    if(layer==0)using(var blue=new Pen(Color.FromArgb(160,103,175,218),2))g.DrawPath(blue,path);
   }
   g.Restore(wave);
  }
  Shield(g,297,-1);Shield(g,727,1);
  for(int y=652;y<804;y++)for(int x=605;x<809;x++){Color c=im.GetPixel(x,y);float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/16);if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(dir,"enhancement_0000.png"),ImageFormat.Png);
 }}
}
'@
$source=$source.Replace('__SHIELD_BODY__',$shieldBody)
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition $source
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[ProtectionBorderArt]::Write($destination)
