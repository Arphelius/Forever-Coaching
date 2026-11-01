param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/RestorationDruid-KeeperOfTheGrove-v3'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class GroveKeeperArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var fill=new SolidBrush(c))g.FillPolygon(fill,p);}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // A pair of tapered wooden antlers grows up around the talent's sides.
  for(int side=-1;side<=1;side+=2){
   var antler=g.Save();g.TranslateTransform(512+side*39,512);g.ScaleTransform(side*.88f,.88f);g.TranslateTransform(0,-512);
   var main=new PointF[]{new PointF(19,793),new PointF(80,746),new PointF(150,702),new PointF(197,634),new PointF(225,552),new PointF(233,459),new PointF(215,365),new PointF(190,282),new PointF(193,211),new PointF(211,151),new PointF(215,233),new PointF(219,277),new PointF(245,354),new PointF(266,454),new PointF(260,560),new PointF(231,651),new PointF(179,731),new PointF(98,783),new PointF(30,821)};
   using(var bark=new LinearGradientBrush(new PointF(185,228),new PointF(245,780),Color.FromArgb(255,126,87,40),Color.FromArgb(255,70,47,26)))g.FillPolygon(bark,main);
   Stroke(g,Color.FromArgb(255,192,149,73),5,new PointF(38,793),new PointF(152,713),new PointF(211,636),new PointF(244,542),new PointF(249,451),new PointF(228,356),new PointF(205,278),new PointF(204,221));
   // Irregular pointed tines branch alternately inward and outward.
   Poly(g,Color.FromArgb(255,111,75,33),new PointF(211,340),new PointF(156,329),new PointF(137,284),new PointF(141,234),new PointF(155,287),new PointF(183,305),new PointF(225,302));
   Poly(g,Color.FromArgb(255,116,80,36),new PointF(243,433),new PointF(285,378),new PointF(293,331),new PointF(273,289),new PointF(307,319),new PointF(314,375),new PointF(268,469));
   Poly(g,Color.FromArgb(255,103,68,31),new PointF(243,529),new PointF(198,488),new PointF(173,446),new PointF(173,396),new PointF(193,437),new PointF(218,463),new PointF(260,477));
   Poly(g,Color.FromArgb(255,116,78,32),new PointF(221,639),new PointF(287,601),new PointF(317,554),new PointF(317,511),new PointF(335,549),new PointF(316,604),new PointF(253,667));
   Poly(g,Color.FromArgb(255,103,67,29),new PointF(153,718),new PointF(127,650),new PointF(91,623),new PointF(96,576),new PointF(113,613),new PointF(158,642),new PointF(183,691));
   Stroke(g,Color.FromArgb(210,191,143,68),3,new PointF(253,447),new PointF(299,372),new PointF(299,336));
   Stroke(g,Color.FromArgb(210,191,143,68),3,new PointF(242,647),new PointF(302,595),new PointF(323,548));
   for(int leaf=0;leaf<3;leaf++){
    float x=226+leaf%2*25,y=383+leaf*134;
    using(var shape=new GraphicsPath()){shape.AddBezier(x,y,x+18,y-31,x+45,y-12,x+58,y-36);shape.AddBezier(x+58,y-36,x+61,y+15,x+21,y+23,x,y);using(var fill=new SolidBrush(Color.FromArgb(245,65+leaf*9,119+leaf*11,45)))g.FillPath(fill,shape);}
   }
   g.Restore(antler);
  }
  // Green healing spiral, translucent enough to identify the selected talent.
  var spiral=new PointF[100];
  for(int j=0;j<100;j++){float u=j/99f;double a=u*Math.PI*3.5+Math.Sin(t)*.17;float r=13+u*182;spiral[j]=new PointF(512+(float)Math.Cos(a)*r,509+(float)Math.Sin(a)*r);}
  var healing=g.Save();g.ExcludeClip(new Rectangle(651,654,100,96));
  Stroke(g,Color.FromArgb(25,86,216,59),25,spiral);
  for(int j=0;j<99;j++){
   float phase=(float)((j/99.0-f/36.0+1)%1),pulse=(float)Math.Pow(Math.Max(0,Math.Sin(phase*Math.PI)),3);
   var pair=new PointF[]{spiral[j],spiral[j+1]};
   Stroke(g,Color.FromArgb((int)(35+pulse*55),72,222,74),13,pair);
   Stroke(g,Color.FromArgb((int)(55+pulse*120),158,249,92),6,pair);
   Stroke(g,Color.FromArgb((int)(35+pulse*120),225,255,170),2,pair);
  }
  g.Restore(healing);
  // Healing motes drift upward between the antlers.
  for(int mote=0;mote<16;mote++){
   float p=(float)((f/36.0+mote*.137)%1),x=512+(mote%2==0?-1:1)*(184+(float)Math.Sin(t+mote)*19),y=746-p*437;
   int alpha=(int)(Math.Sin(p*Math.PI)*185);
   using(var glow=new GraphicsPath()){glow.AddEllipse(x-9,y-9,18,18);using(var fill=new PathGradientBrush(glow)){fill.CenterColor=Color.FromArgb(alpha,184,255,121);fill.SurroundColors=new Color[]{Color.FromArgb(0,84,217,56)};g.FillPath(fill,glow);}}
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[GroveKeeperArt]::Write($destination)
Write-Output "Created Keeper of the Grove animation: $destination"
