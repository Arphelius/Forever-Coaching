param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Fire-Sunfury-v5'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SunfuryArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawCurve(pen,p);}}
 static void Shape(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 public static void Write(string output,string phoenixSource){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  // Preserve the accepted phoenix while replacing its original small orbs.
  var phoenix=g.Save();
  g.TranslateTransform(512,512);g.ScaleTransform(.85f,.85f);g.TranslateTransform(-512,-512);
  // Remove only the isolated phoenix head, crest and neck above the talent.
  g.ExcludeClip(new Rectangle(472,190,91,140));
  for(int old=0;old<3;old++)using(var cut=new GraphicsPath()){
   float ox=512+(old-1)*94,oy=old==1?130:190;
   cut.AddEllipse(ox-59,oy-59,118,118);using(var region=new Region(cut))g.ExcludeClip(region);
  }
  using(var source=Image.FromFile(Path.Combine(phoenixSource,"enhancement_"+f.ToString("D4")+".png")))g.DrawImageUnscaled(source,0,0);
  g.Restore(phoenix);
  // Three independently flickering solar orbs above the phoenix.
  for(int orb=0;orb<3;orb++){
   float x=512+(orb-1)*119,y=orb==1?225:248;
   var orbState=g.Save();g.TranslateTransform(x,y);g.ScaleTransform(.82f,.82f);g.TranslateTransform(-x,-y);
   float pulse=(float)(.5+.5*Math.Sin(t*2+orb*1.9));
   Glow(g,x,y,76+pulse*9,Color.FromArgb(165,255,65,4));
   Glow(g,x,y,53+pulse*4,Color.FromArgb(255,255,126,8));
   Glow(g,x,y,34,Color.FromArgb(255,255,211,53));
   using(var core=new SolidBrush(Color.FromArgb(255,255,248,183)))g.FillEllipse(core,x-19,y-23,38,46);
   for(int lick=0;lick<7;lick++){
    float dx=(lick-3)*12,height=48+(float)Math.Sin(t*3+lick+orb)*14;
    Line(g,Color.FromArgb(155,255,70,3),15,new PointF(x+dx,y+20),new PointF(x+dx-10,y-14),new PointF(x+dx+(float)Math.Sin(t*3+lick+orb)*13,y-height));
    Line(g,Color.FromArgb(235,255,180+lick%3*25,42),5,new PointF(x+dx,y+10),new PointF(x+dx-8,y-17),new PointF(x+dx+(float)Math.Sin(t*3+lick+orb)*13,y-height));
   }
   for(int ember=0;ember<12;ember++){
    float age=(float)((f/36.0*2+ember*.173+orb*.23)%1),ex=x+(float)Math.Sin(ember*4+orb)*57,ey=y-25-age*58;
    using(var spark=new SolidBrush(Color.FromArgb((int)(200*Math.Sin(age*Math.PI)),255,206,73)))g.FillEllipse(spark,ex,ey,3,5);
   }
   g.Restore(orbState);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[SunfuryArt]::Write($destination,[IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../art/krita/Fire-Sunfury-v1')))
Write-Output "Created Sunfury animation: $destination"
