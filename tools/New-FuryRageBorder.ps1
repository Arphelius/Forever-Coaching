param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Fury-RageBorder-v2'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FuryBorderArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Sword(Graphics g,float x,float angle){var s=g.Save();g.TranslateTransform(x,503);g.RotateTransform(angle);
  Poly(g,Color.FromArgb(255,26,24,29),P(-21,-143),P(0,-192),P(21,-143),P(17,79),P(-17,79));
  using(var path=new GraphicsPath()){path.AddPolygon(new[]{P(-16,-140),P(0,-180),P(16,-140),P(12,75),P(-12,75)});using(var fill=new LinearGradientBrush(P(-16,0),P(16,0),Color.FromArgb(255,205,184,181),Color.FromArgb(255,63,65,75)))g.FillPath(fill,path);}
  Line(g,Color.FromArgb(255,255,211,199),3,P(-10,-137),P(-9,69));
  Line(g,Color.FromArgb(230,119,17,26),4,P(0,-137),P(0,73));
  Poly(g,Color.FromArgb(255,48,32,34),P(-38,75),P(-10,68),P(0,77),P(10,68),P(38,75),P(33,91),P(-33,91));
  Line(g,Color.FromArgb(255,167,123,92),4,P(-34,78),P(0,84),P(34,78));
  Line(g,Color.FromArgb(255,58,24,26),18,P(0,94),P(0,153));
  for(int i=0;i<6;i++)Line(g,Color.FromArgb(255,137,76,66),3,P(-7,97+i*9),P(7,103+i*9));
  Poly(g,Color.FromArgb(255,152,121,96),P(0,175),P(-13,158),P(0,148),P(13,158));g.Restore(s);
 }
 public static void Write(string dir){using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  // Soft red follows the icon's rounded edge instead of drawing nested square frames.
  for(int yy=279;yy<746;yy++)for(int xx=279;xx<746;xx++){
   double qx=Math.Abs(xx-512)-153,qy=Math.Abs(yy-512)-153;
   double ax=Math.Max(qx,0),ay=Math.Max(qy,0);
   double edge=Math.Sqrt(ax*ax+ay*ay)+Math.Min(Math.Max(qx,qy),0)-50;
   double distance=Math.Abs(edge);
   int alpha=(int)Math.Min(255,235*Math.Exp(-distance*distance/65)+30*Math.Exp(-distance*distance/280));
   if(alpha>0)im.SetPixel(xx,yy,Color.FromArgb(alpha,255,12,28));
  }
  // Small blood streaks cling to the lower edge; this is a static low-VFX border.
  for(int drip=0;drip<4;drip++){float x=339+drip*67,h=17+drip%3*10;
   Line(g,Color.FromArgb(255,88,3,11),7,P(x,715),P(x+2,715+h));
   using(var b=new SolidBrush(Color.FromArgb(255,152,9,19)))g.FillEllipse(b,x-3,711+h,9,13);
   Line(g,Color.FromArgb(210,219,37,40),2,P(x-1,718),P(x,711+h));
  }
  Sword(g,298,-14);Sword(g,726,14);
  for(int y=652;y<804;y++)for(int x=605;x<809;x++){Color c=im.GetPixel(x,y);float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/16);if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(dir,"enhancement_0000.png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[FuryBorderArt]::Write($destination)
