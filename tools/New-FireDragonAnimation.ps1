param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Fire-DragonsBreath-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FireDragonArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // New frontal dragon head above the talent, with swept horns and armored cheeks.
  var face=g.Save();g.TranslateTransform(512,225);
  for(int side=-1;side<=1;side+=2){
   var half=g.Save();g.ScaleTransform(side,1);
   // Swept, hooked horns and a fiery dragon crest rather than straight spikes.
   using(var horn=new GraphicsPath()){
    horn.AddBezier(52,-29,96,-52,145,-66,136,-133);
    horn.AddBezier(136,-133,183,-78,134,-24,81,-3);horn.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(65,-20),new PointF(140,-120),Color.FromArgb(255,208,75,8),Color.FromArgb(255,255,237,131)))g.FillPath(fill,horn);
   }
   Poly(g,Color.FromArgb(255,109,33,18),new PointF(12,-44),new PointF(58,-63),new PointF(96,-36),new PointF(112,7),new PointF(75,50),new PointF(47,78),new PointF(0,63));
   for(int spine=0;spine<4;spine++){
    float y=-48+spine*27;
    Poly(g,Color.FromArgb(245,255,145,15),new PointF(74,y),new PointF(139+spine*4,y-25),new PointF(110,y+16),new PointF(66,y+26));
   }
   Poly(g,Color.FromArgb(255,186,53,13),new PointF(43,-34),new PointF(98,-18),new PointF(126,4),new PointF(95,5),new PointF(113,32),new PointF(81,23),new PointF(88,56),new PointF(53,43));
   Poly(g,Color.FromArgb(255,235,96,16),new PointF(23,-27),new PointF(67,-40),new PointF(86,-13),new PointF(62,8),new PointF(36,4));
   Poly(g,Color.FromArgb(255,42,15,10),new PointF(21,-10),new PointF(73,-19),new PointF(58,6),new PointF(31,9));
   Stroke(g,Color.FromArgb(255,255,230,75),7,new PointF(30,-5),new PointF(61,-11));
   Stroke(g,Color.FromArgb(255,255,255,212),2,new PointF(35,-5),new PointF(57,-9));
   Poly(g,Color.FromArgb(255,246,120,22),new PointF(57,14),new PointF(83,9),new PointF(64,40),new PointF(42,52),new PointF(27,35));
   g.Restore(half);
  }
  Poly(g,Color.FromArgb(255,220,75,14),new PointF(0,-76),new PointF(28,-40),new PointF(19,0),new PointF(37,33),new PointF(26,61),new PointF(-26,61),new PointF(-37,33),new PointF(-19,0),new PointF(-28,-40));
  Poly(g,Color.FromArgb(255,255,174,36),new PointF(0,-105),new PointF(17,-55),new PointF(9,-20),new PointF(0,-3),new PointF(-12,-26),new PointF(-18,-57));
  Stroke(g,Color.FromArgb(255,255,191,59),5,new PointF(0,-60),new PointF(0,-16),new PointF(12,27));
  Poly(g,Color.FromArgb(255,35,10,7),new PointF(-39,48),new PointF(39,48),new PointF(44,77),new PointF(24,99),new PointF(-24,99),new PointF(-44,77));
  for(int side=-1;side<=1;side+=2){
   Poly(g,Color.FromArgb(255,255,235,171),new PointF(side*31,49),new PointF(side*18,51),new PointF(side*23,75));
   using(var nostril=new SolidBrush(Color.FromArgb(255,73,20,8)))g.FillEllipse(nostril,side*19-5,32,10,7);
  }
  Stroke(g,Color.FromArgb(255,240,97,18),12,new PointF(-37,83),new PointF(-21,103),new PointF(21,103),new PointF(37,83));
  g.Restore(face);
  var dragon=g.Save();g.TranslateTransform(541,247);g.RotateTransform(90);
  // Fire breath billows from the open mouth across the icon, in timed exhales.
  float breath=.8f+.2f*(float)(.5+.5*Math.Sin(t));
  for(int layer=0;layer<4;layer++){
   using(var plume=new GraphicsPath()){
    float tip=450-layer*32,w=215-layer*38,sway=(float)Math.Sin(t*3+layer)*29;
    plume.AddBezier(69,29,120,14,184,-w+sway,tip,-w*.6f+sway);
    plume.AddBezier(tip,-w*.6f+sway,tip-31,9+sway,tip+22,w+37,tip-10,w+31);
    plume.AddBezier(tip-10,w+31,220,w*.6f,108,49,69,38);plume.CloseFigure();
    Color root=layer==0?Color.FromArgb((int)(breath*110),255,56,3):layer==1?Color.FromArgb((int)(breath*140),255,151,12):Color.FromArgb((int)(breath*160),255,247,161);
    using(var fill=new LinearGradientBrush(new PointF(69,29),new PointF(tip,29),root,Color.FromArgb(15,255,83,3)))g.FillPath(fill,plume);
   }
  }
  for(int ember=0;ember<80;ember++){
   float p=(float)((f/36.0*3+ember*.137)%1),x=85+p*360,y=31+(float)Math.Sin(t*2+ember)*p*180;
   using(var glow=new SolidBrush(Color.FromArgb((int)(Math.Sin(p*Math.PI)*breath*210),255,195+ember%3*18,70)))g.FillEllipse(glow,x,y,4+ember%3,4+ember%3);
  }
  g.Restore(dragon);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[FireDragonArt]::Write($destination)
Write-Output "Created fire dragon animation: $destination"
