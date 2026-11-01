param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Enhancement-Totemic-v8-body'),[switch]$ElementsOnly,[switch]$RearElements)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class TotemicArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Lightning(Graphics g,PointF[] p,float alpha,float width){
  Stroke(g,Color.FromArgb((int)(alpha*22),25,85,255),width+28,p);
  Stroke(g,Color.FromArgb((int)(alpha*55),28,122,255),width+13,p);
  Stroke(g,Color.FromArgb((int)(alpha*210),38,152,255),width+5,p);
  Stroke(g,Color.FromArgb((int)(alpha*255),163,228,255),width,p);
  Stroke(g,Color.FromArgb((int)(alpha*245),243,253,255),width*.32f,p);
 }
 static PointF Orbit(float progress,int element){
  double a=(element%2==0?progress:-progress)*Math.PI*(element<2?6:4)+element*.8;
  // A circle viewed at a tilt: its near arc sweeps across the talent face.
  float x=(float)Math.Cos(a)*(240+element*14);
  return new PointF(512+x,512+(float)Math.Sin(a)*(76+element*18)+x*(element%2==0?-.24f:.24f));
 }
 public static void Write(string dir,bool elementsOnly,bool rear){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)){
 double t=f*Math.PI*2/36;
 using(var g=Graphics.FromImage(im)){g.SmoothingMode=SmoothingMode.AntiAlias;
 if(!elementsOnly){
 // Complete hand-authored trunk, continuous beneath the head and talent.
 var trunk=new PointF[]{new PointF(414,265),new PointF(610,265),new PointF(594,447),new PointF(579,643),new PointF(568,966),new PointF(456,966),new PointF(445,643),new PointF(430,447),new PointF(414,265)};
 using(var wood=new LinearGradientBrush(new PointF(420,500),new PointF(610,500),Color.FromArgb(255,61,39,25),Color.FromArgb(255,157,106,53)))g.FillPolygon(wood,trunk);
 Stroke(g,Color.FromArgb(255,183,130,65),7,trunk);
 for(int band=0;band<5;band++){
  float y=355+band*100,w=75-band*5;
  Poly(g,Color.FromArgb(255,86+band*6,57,31),new PointF(512-w,y-38),new PointF(512,y-9),new PointF(512+w,y-38),new PointF(512+w-5,y+16),new PointF(512,y+56),new PointF(512-w+5,y+16));
  Stroke(g,Color.FromArgb(255,202,151,78),6,new PointF(512-w+8,y-25),new PointF(512,y+7),new PointF(512+w-8,y-25));
  Stroke(g,Color.FromArgb(255,135,95,47),5,new PointF(512-w+8,y+6),new PointF(512,y+40),new PointF(512+w-8,y+6));
 }
 for(int grain=0;grain<8;grain++){
  float x=445+grain*18;
  Stroke(g,Color.FromArgb(80,39,25,18),3,new PointF(x,325),new PointF(x+8,470),new PointF(x-4,621),new PointF(x+5,866));
 }
 // Spread carved wooden wings behind the head and the upper icon corners.
 for(int side=-1;side<=1;side+=2){
  var wing=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
  var silhouette=new PointF[]{new PointF(136,217),new PointF(252,181),new PointF(424,134),new PointF(387,233),new PointF(329,263),new PointF(367,278),new PointF(296,311),new PointF(320,332),new PointF(232,349),new PointF(158,294),new PointF(136,217)};
  using(var woodWing=new LinearGradientBrush(new PointF(140,180),new PointF(400,340),Color.FromArgb(255,156,95,40),Color.FromArgb(255,67,42,25)))g.FillPolygon(woodWing,silhouette);
  Stroke(g,Color.FromArgb(255,204,150,73),8,silhouette);
  for(int feather=0;feather<4;feather++)Stroke(g,Color.FromArgb(255,191,132,60),6,new PointF(180+feather*24,233+feather*20),new PointF(352-feather*16,185+feather*35));
  g.Restore(wing);
 }
 // Massive carved head: crown, heavy brows, cheeks and a pointed stone jaw.
 var head=new PointF[]{new PointF(350,282),new PointF(328,208),new PointF(377,135),new PointF(433,103),new PointF(476,118),new PointF(512,72),new PointF(548,118),new PointF(591,103),new PointF(647,135),new PointF(696,208),new PointF(674,282),new PointF(604,327),new PointF(512,350),new PointF(420,327),new PointF(350,282)};
 using(var wood=new LinearGradientBrush(new PointF(340,80),new PointF(650,300),Color.FromArgb(255,128,76,35),Color.FromArgb(255,45,33,24)))g.FillPolygon(wood,head);
 Stroke(g,Color.FromArgb(255,188,129,59),9,head);
 Poly(g,Color.FromArgb(255,77,52,30),new PointF(345,275),new PointF(380,330),new PointF(465,347),new PointF(512,320),new PointF(559,347),new PointF(644,330),new PointF(679,275));
 Stroke(g,Color.FromArgb(255,184,126,59),7,new PointF(353,286),new PointF(390,317),new PointF(460,329),new PointF(512,307),new PointF(564,329),new PointF(634,317),new PointF(671,286));
 Stroke(g,Color.FromArgb(255,104,221,82),6,new PointF(509,771),new PointF(491,794),new PointF(520,810),new PointF(503,834));
 // Layered carved feather plates replace the candle-shaped flames.
 for(int side=-1;side<=1;side+=2){
  Poly(g,Color.FromArgb(255,157,111,58),new PointF(512+side*18,139),new PointF(512+side*80,125),new PointF(512+side*139,172),new PointF(512+side*111,216),new PointF(512+side*51,188));
  Stroke(g,Color.FromArgb(255,216,169,98),6,new PointF(512+side*35,149),new PointF(512+side*78,141),new PointF(512+side*120,177));
 }
 // Heavy carved brows slant inward into a threatening stare.
 Poly(g,Color.FromArgb(255,34,26,22),new PointF(354,215),new PointF(486,240),new PointF(482,283),new PointF(376,264));
 Poly(g,Color.FromArgb(255,34,26,22),new PointF(670,215),new PointF(538,240),new PointF(542,283),new PointF(648,264));
 float glare=(float)(.85+.15*Math.Sin(t));
 Stroke(g,Color.FromArgb((int)(glare*75),255,122,14),24,new PointF(383,247),new PointF(469,264));
 Stroke(g,Color.FromArgb(255,255,181,38),10,new PointF(383,247),new PointF(469,264));
 Stroke(g,Color.FromArgb(255,255,248,158),4,new PointF(390,247),new PointF(462,262));
 Stroke(g,Color.FromArgb((int)(glare*75),255,122,14),24,new PointF(641,247),new PointF(555,264));
 Stroke(g,Color.FromArgb(255,255,181,38),10,new PointF(641,247),new PointF(555,264));
 Stroke(g,Color.FromArgb(255,255,248,158),4,new PointF(634,247),new PointF(562,262));
 for(int side=-1;side<=1;side+=2){
  Stroke(g,Color.FromArgb(255,163,105,48),7,new PointF(512+side*38,167),new PointF(512+side*76,207),new PointF(512+side*119,175));
  Stroke(g,Color.FromArgb(255,195,146,76),6,new PointF(512+side*149,204),new PointF(512+side*176,231));
 }
 // Long hooked raptor beak, split into shaded carved facets.
 Poly(g,Color.FromArgb(255,55,40,28),new PointF(481,215),new PointF(543,215),new PointF(559,281),new PointF(512,371),new PointF(465,281));
 Poly(g,Color.FromArgb(255,208,172,112),new PointF(512,205),new PointF(481,250),new PointF(489,292),new PointF(512,358));
 Poly(g,Color.FromArgb(255,128,97,58),new PointF(512,205),new PointF(543,250),new PointF(535,292),new PointF(512,358));
 Stroke(g,Color.FromArgb(255,241,209,146),5,new PointF(512,219),new PointF(512,298),new PointF(506,334));
 }
 if(elementsOnly){
 using(var half=new GraphicsPath()){
  half.AddPolygon(rear?new PointF[]{new PointF(0,0),new PointF(1024,0),new PointF(1024,389),new PointF(0,635)}:new PointF[]{new PointF(0,635),new PointF(1024,389),new PointF(1024,1024),new PointF(0,1024)});
  g.SetClip(half);
 }
 // Elemental streams pass through the icon's middle from left to right.
 for(int element=0;element<4;element++){
 float[] starts={0f,.19f,.51f,.78f};
 float[] durations={.62f,.48f,.56f,.43f};
 float cycle=(float)((f/36.0+starts[element])%1);
 if(cycle>=durations[element])continue;
 float age=cycle;
 // Keep the former flowing-current movement; stagger its entrance and exit.
 float envelope=Math.Min(1,Math.Min(cycle/.07f,(durations[element]-cycle)/.07f));
 float fade=(.72f+.22f*(float)Math.Sin((cycle+element*.17)*Math.PI*2))*envelope;
 for(int trail=0;trail<3;trail++){
  var points=new PointF[32];
  for(int j=0;j<32;j++){
   float u=j/31f,progress=age-u*.24f;
   float x,y;
   // Comet-like curled wakes orbit diagonally, reversing direction by element.
   PointF orbitPoint=Orbit(progress,element);
   x=orbitPoint.X;y=orbitPoint.Y+(trail-1)*9;
   x+=(float)Math.Sin(u*8+t*2+element)*u*27;y+=(float)Math.Cos(u*8+t*2+element)*u*27;
   points[j]=new PointF(x,y);
  }
  Color tint=element==0?Color.FromArgb(255,255,104,12):element==1?Color.FromArgb(255,205,250,249):element==2?Color.FromArgb(255,42,176,237):Color.FromArgb(255,88,214,53);
  // Do not paint the rank region at the lower-right corner of the icon.
  var pass=g.Save();g.ExcludeClip(new Rectangle(650,654,112,105));
  // Long overlapping wakes maintain an unbroken elemental current.
  for(int segment=0;segment<31;segment++){
   float taper=1-segment/32f,opacity=fade*(.42f+.58f*taper);
   float billow=.5f+.8f*(float)Math.Sin(segment/31f*Math.PI);
   var pair=new PointF[]{points[segment],points[segment+1]};
   Stroke(g,Color.FromArgb((int)(opacity*24),tint.R,tint.G,tint.B),52*billow,pair);
   Stroke(g,Color.FromArgb((int)(opacity*(element==3?95:145)),tint.R,tint.G,tint.B),(element==1?23:36)*billow,pair);
   Stroke(g,Color.FromArgb((int)(opacity*205),element==0?255:element==3?167:220,element==0?210:250,element==0?72:element==3?90:255),(element==1?5:7)*taper+1,pair);
  }
  for(int j=0;j<32;j+=3){PointF p=points[j];int alpha=(int)(fade*(210-j*3));
   if(element==0){
    float curl=(float)Math.Sin(t*2+j)*18;
    using(var flame=new GraphicsPath()){
     flame.AddBezier(p.X-10,p.Y+9,p.X-24,p.Y-12,p.X+curl,p.Y-17,p.X+curl+8,p.Y-40);
     flame.AddBezier(p.X+curl+8,p.Y-40,p.X+28,p.Y-11,p.X+18,p.Y+6,p.X-10,p.Y+9);
     using(var fire=new LinearGradientBrush(new PointF(p.X,p.Y+9),new PointF(p.X,p.Y-40),Color.FromArgb(alpha,255,78,8),Color.FromArgb(alpha,255,230,103)))g.FillPath(fire,flame);
    }
   }
   else if(element==2){using(var drop=new SolidBrush(Color.FromArgb(alpha,161,242,255)))g.FillEllipse(drop,p.X-4,p.Y-5,8,13);}
   else if(element==1){using(var curl=new Pen(Color.FromArgb(alpha,222,255,255),3))g.DrawArc(curl,p.X-15,p.Y-12,30,24,(float)(t*180/Math.PI+j*9),260);}
   else if(element==3){var rock=g.Save();g.TranslateTransform(p.X,p.Y);g.RotateTransform(f*19+j*31);Poly(g,Color.FromArgb(alpha,87,76,43),new PointF(-12,-7),new PointF(-2,-14),new PointF(12,-3),new PointF(7,11),new PointF(-9,9));Stroke(g,Color.FromArgb(alpha,119,243,64),4,new PointF(-7,-5),new PointF(0,0),new PointF(6,-5));g.Restore(rock);}
  }
  g.Restore(pass);
 }
 // Each wake terminates in a substantial luminous orb, with a rotating spiral.
 double orbit=(element%2==0?1:-1)*age*Math.PI*2+element*1.5;
 PointF orbPosition=Orbit(age,element);
 float ox=orbPosition.X,oy=orbPosition.Y;
 Color orbColor=element==0?Color.FromArgb(255,113,17):element==1?Color.FromArgb(188,241,246):element==2?Color.FromArgb(37,170,245):Color.FromArgb(107,222,55);
 var orbState=g.Save();g.TranslateTransform(ox,oy);
 using(var haze=new GraphicsPath()){haze.AddEllipse(-38,-30,76,60);using(var b=new PathGradientBrush(haze)){b.CenterColor=Color.FromArgb((int)(fade*35),orbColor);b.SurroundColors=new Color[]{Color.FromArgb(0,orbColor)};g.FillPath(b,haze);}}
 // Open, broken vortices replace the solid round head and single thin tail.
 g.RotateTransform((float)(t*180/Math.PI)*(element%2==0?1:-1));
 for(int curl=0;curl<3;curl++){
  float radius=12+curl*7;
  using(var outer=new Pen(Color.FromArgb((int)(fade*150),orbColor),10-curl*2))g.DrawArc(outer,-radius,-radius*.7f,radius*2,radius*1.4f,curl*105,155);
  using(var inner=new Pen(Color.FromArgb((int)(fade*215),242,255,214),3))g.DrawArc(inner,-radius,-radius*.7f,radius*2,radius*1.4f,curl*105+15,95);
 }
 if(element==3){Poly(g,Color.FromArgb((int)(fade*240),92,75,41),new PointF(-16,-18),new PointF(10,-22),new PointF(24,-3),new PointF(8,22),new PointF(-21,12));Stroke(g,Color.FromArgb((int)(fade*250),175,255,105),4,new PointF(-9,-9),new PointF(3,0),new PointF(-4,12));}
 g.Restore(orbState);
 // Smaller satellites detach and spiral around the main elemental sphere.
 for(int satellite=0;satellite<3;satellite++){
  double a=orbit+satellite*1.8+t*(element%2==0?2:-2);
  float radius=29+satellite*7,sx=ox+(float)Math.Cos(a)*radius,sy=oy+(float)Math.Sin(a)*radius*.45f;
  using(var fleck=new Pen(Color.FromArgb((int)(fade*190),orbColor),4))g.DrawArc(fleck,sx-10,sy-7,20,14,(float)(a*180/Math.PI),160);
 }
 }
 }
 }im.Save(Path.Combine(dir,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[TotemicArt]::Write($destination,$ElementsOnly.IsPresent,$RearElements.IsPresent)
Write-Output "Created Totemic animation: $destination"
