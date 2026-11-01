param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Demonology-Sargeras-v8'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SargerasArt {
 static float Smooth(float p){p=Math.Max(0,Math.Min(1,p));return p*p*(3-2*p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color color){using(var path=new GraphicsPath()){path.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(path)){b.CenterColor=color;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,path);}}}
 static void Flame(Graphics g,float x,float y,float h,float sway,int alpha){using(var flame=new GraphicsPath()){
  flame.AddBezier(x-14,y,x-30,y-h*.4f,x+sway-10,y-h*.6f,x+sway,y-h);
  flame.AddBezier(x+sway,y-h,x+27,y-h*.3f,x+15,y-5,x-14,y);flame.CloseFigure();
  using(var fill=new LinearGradientBrush(new PointF(x,y),new PointF(x,y-h),Color.FromArgb(alpha,255,109,3),Color.FromArgb(0,255,224,56)))g.FillPath(fill,flame);
 }}
 static void Fist(Graphics g,float grip){
  // Rounded anatomy, knuckles and molten fissures instead of armored segments.
  using(var flesh=new GraphicsPath()){
   flesh.AddBezier(84,-53,23,-66,-25,-54,-39,-15);
   flesh.AddBezier(-39,-15,-51,26,-4,65,42,53);
   flesh.AddBezier(42,53,64,47,86,47,106,51);flesh.CloseFigure();
   using(var skin=new LinearGradientBrush(new PointF(-35,-50),new PointF(85,54),Color.FromArgb(255,79,51,37),Color.FromArgb(255,28,25,24)))g.FillPath(skin,flesh);
  }
  for(int finger=0;finger<4;finger++){
   float y=-39+finger*25,reach=23+grip*22;
   using(var digit=new GraphicsPath()){
    digit.AddBezier(13,y,-13,y-7,-reach,y+3,-reach+4,y+19);
    digit.AddBezier(-reach+4,y+19,-reach+10,y+31,-reach+24,y+28,-reach+28,y+20);
    using(var skin=new Pen(Color.FromArgb(255,71-finger*5,47-finger*3,33),18)){skin.StartCap=skin.EndCap=LineCap.Round;g.DrawPath(skin,digit);}
   }
   Line(g,Color.FromArgb(215,246,104,10),2,new PointF(7,y-3),new PointF(-9,y+2),new PointF(-13,y+10));
   Poly(g,Color.FromArgb(255,40,34,26),new PointF(-reach+6,y+18),new PointF(-reach+18,y+18),new PointF(-reach+19,y+34));
  }
  using(var thumb=new GraphicsPath()){
   thumb.AddBezier(43,32,9,66,-15,64,-29,44);
   using(var skin=new Pen(Color.FromArgb(255,76,48,32),23)){skin.StartCap=skin.EndCap=LineCap.Round;g.DrawPath(skin,thumb);}
  }
  Line(g,Color.FromArgb(235,255,116,10),3,new PointF(89,-28),new PointF(54,-22),new PointF(42,-7),new PointF(19,-3));
  Glow(g,33,-16,31,Color.FromArgb(55,255,85,0));
 }
 public static void Write(string output){for(int f=0;f<108;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;float p=f/107f;double t=p*Math.PI*2;
  float grip=Smooth(p/.25f),windup=Smooth((p-.22f)/.17f),stab=Smooth((p-.42f)/.15f),ruin=Smooth((p-.53f)/.19f);
  // Layered fire frames a sculpted volcanic face instead of a flat mask.
  Glow(g,512,223,119,Color.FromArgb(75,233,84,0));
  for(int hair=0;hair<18;hair++){
   float x=437+hair*9,y=187+(float)Math.Sin(hair*.7)*13;
   Flame(g,x,y,58+(hair*29)%68+(float)Math.Sin(t*2+hair)*10,(float)Math.Sin(t*2+hair)*14,165);
  }
  for(int side=-1;side<=1;side+=2){
   var head=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   using(var horn=new GraphicsPath()){
    horn.AddBezier(43,201,141,239,183,133,119,47);
    horn.AddBezier(119,47,151,139,107,180,61,163);horn.CloseFigure();
    using(var bone=new LinearGradientBrush(new PointF(68,195),new PointF(157,76),Color.FromArgb(255,92,65,29),Color.FromArgb(255,22,28,21)))g.FillPath(bone,horn);
    using(var edge=new Pen(Color.FromArgb(220,170,111,37),2.5f))g.DrawPath(edge,horn);
   }
   for(int ridge=0;ridge<10;ridge++){
    float u=ridge/10f,x=96+(float)Math.Sin(u*Math.PI)*42,y=194-u*127,w=18-u*12;
    Line(g,Color.FromArgb(175,14,20,17),3,new PointF(x-w,y+3),new PointF(x,y+8),new PointF(x+w,y+4));
    Line(g,Color.FromArgb(115,160,111,48),1.4f,new PointF(x-w,y),new PointF(x,y+4),new PointF(x+w,y));
   }
   using(var skin=new GraphicsPath()){
    skin.AddBezier(0,150,19,155,37,178,57,171);
    skin.AddBezier(57,171,75,188,79,220,66,241);
    skin.AddBezier(66,241,55,256,41,258,34,281);
    skin.AddBezier(34,281,18,300,7,294,0,286);skin.CloseFigure();
    using(var flesh=new LinearGradientBrush(new PointF(0,170),new PointF(77,253),Color.FromArgb(255,106,64,36),Color.FromArgb(255,30,27,25)))g.FillPath(flesh,skin);
   }
   // Brow, temples and cheeks form distinct planes of cracked obsidian.
   Poly(g,Color.FromArgb(255,26,23,22),new PointF(8,180),new PointF(27,185),new PointF(56,179),new PointF(72,199),new PointF(48,203),new PointF(13,224));
   Line(g,Color.FromArgb(210,111,58,25),3,new PointF(15,212),new PointF(37,201),new PointF(62,196));
   Poly(g,Color.FromArgb(255,87,54,33),new PointF(42,230),new PointF(66,218),new PointF(61,243),new PointF(42,252),new PointF(30,263),new PointF(29,246));
   Poly(g,Color.FromArgb(255,21,20,20),new PointF(10,219),new PointF(30,207),new PointF(55,210),new PointF(40,227),new PointF(18,232));
   Glow(g,32,217,19,Color.FromArgb(175,255,116,2));
   Line(g,Color.FromArgb(255,255,192,36),5,new PointF(14,224),new PointF(31,216),new PointF(48,210));
   Line(g,Color.FromArgb(255,255,244,147),2,new PointF(20,221),new PointF(42,213));
   Line(g,Color.FromArgb(220,244,97,7),2,new PointF(11,169),new PointF(24,184),new PointF(19,196),new PointF(36,204));
   Line(g,Color.FromArgb(190,221,82,5),1.5f,new PointF(65,192),new PointF(55,203),new PointF(61,215),new PointF(51,232));
   Line(g,Color.FromArgb(180,200,69,3),2,new PointF(49,248),new PointF(37,261),new PointF(29,282));
   
   g.Restore(head);
  }
  // Strong nose bridge, snarling lower lip and flickering pointed fire beard.
  Poly(g,Color.FromArgb(255,106,67,37),new PointF(508,193),new PointF(516,193),new PointF(524,235),new PointF(512,243),new PointF(500,235));
  Line(g,Color.FromArgb(205,250,134,26),2,new PointF(510,202),new PointF(507,232),new PointF(512,236));
  // Closed, stern mouth above the distinct volcanic jaw and fire beard.
  Poly(g,Color.FromArgb(255,65,40,28),new PointF(477,247),new PointF(495,243),new PointF(512,249),new PointF(530,243),new PointF(547,247),new PointF(537,269),new PointF(512,278),new PointF(487,269));
  Line(g,Color.FromArgb(255,17,12,12),3.5f,new PointF(483,257),new PointF(497,256),new PointF(512,260),new PointF(527,256),new PointF(541,257));
  Poly(g,Color.FromArgb(255,53,35,26),new PointF(485,269),new PointF(512,279),new PointF(539,269),new PointF(530,287),new PointF(512,293),new PointF(494,287));
  Line(g,Color.FromArgb(220,139,72,25),2,new PointF(490,276),new PointF(512,285),new PointF(534,276));
  for(int lockOfFire=0;lockOfFire<11;lockOfFire++){
   float x=466+lockOfFire*9,root=292+Math.Abs(lockOfFire-5)*1.2f;
   float tipY=325+(5-Math.Abs(lockOfFire-5))*6+(float)Math.Sin(t*2+lockOfFire)*5;
   float sway=(float)Math.Sin(t*2+lockOfFire*.7)*7;
   using(var beard=new GraphicsPath()){
    beard.AddBezier(x-9,root,x-19,root+15,x+sway-7,tipY-10,x+sway,tipY);
    beard.AddBezier(x+sway,tipY,x+13,root+25,x+12,root+2,x+9,root);beard.CloseFigure();
    using(var fire=new LinearGradientBrush(new PointF(x,root),new PointF(x,tipY),Color.FromArgb(200,255,151,9),Color.FromArgb(0,255,72,0)))g.FillPath(fire,beard);
   }
  }
  float swordX=835-windup*9-stab*57,swordY=205-windup*131+stab*93;
  // Both wrists emerge from independent fel portals.
  for(int portal=0;portal<2;portal++){
   var gateState=g.Save();
   if(portal==0)g.TranslateTransform(191,498);else{g.TranslateTransform(896,200);g.RotateTransform(34);}
   using(var gate=new GraphicsPath()){
    gate.AddEllipse(-36,-98,72,196);
    using(var hollow=new SolidBrush(Color.FromArgb(220,8,24,9)))g.FillPath(hollow,gate);
    using(var haze=new Pen(Color.FromArgb(65,94,192,9),23))g.DrawPath(haze,gate);
    using(var rim=new Pen(Color.FromArgb(210,171,241,38),4))g.DrawPath(rim,gate);
   }
   for(int arc=0;arc<5;arc++)using(var current=new Pen(Color.FromArgb(140,141,226,30),2))g.DrawArc(current,-29,-87,58,174,(float)(t*180/Math.PI)+arc*72,36);
   g.Restore(gateState);
  }
  // The left hand enters, curls around the icon, and holds it for the strike.
  var left=g.Save();g.TranslateTransform(199+grip*83,498);g.ScaleTransform(-1.2f*Math.Max(.05f,grip),1.2f*Math.Max(.05f,grip));Fist(g,grip);g.Restore(left);
  // The blade materializes from the right fist before it is raised and driven down.
  var sword=g.Save();g.TranslateTransform(swordX,swordY);g.RotateTransform(34);
  float weaponForm=Smooth((p-.13f)/.17f);
  var materialize=g.Save();g.SetClip(new RectangleF(-110,-90,220,550*weaponForm));
  // A broad serrated blade of molten fire, matching the reference silhouette.
  PointF[] swordOutline=new PointF[]{new PointF(-31,52),new PointF(-43,96),new PointF(-34,116),new PointF(-53,145),new PointF(-42,166),new PointF(-61,199),new PointF(-48,221),new PointF(-56,252),new PointF(-39,275),new PointF(-43,307),new PointF(-27,338),new PointF(-28,370),new PointF(0,460),new PointF(27,372),new PointF(26,342),new PointF(44,306),new PointF(38,282),new PointF(57,251),new PointF(48,228),new PointF(62,198),new PointF(45,169),new PointF(53,143),new PointF(37,116),new PointF(44,94),new PointF(31,52)};
  using(var blade=new GraphicsPath()){
   blade.AddPolygon(swordOutline);
   using(var glow=new Pen(Color.FromArgb(65,255,87,0),23))g.DrawPath(glow,blade);
   using(var fire=new LinearGradientBrush(new PointF(0,55),new PointF(0,460),Color.FromArgb(255,193,50,10),Color.FromArgb(255,255,222,89)))g.FillPath(fire,blade);
   using(var rim=new Pen(Color.FromArgb(245,255,136,18),4))g.DrawPath(rim,blade);
  }
  // Dark volcanic islands break up the glowing surface.
  for(int plate=0;plate<10;plate++){
   float y=81+plate*29,w=plate<6?29:27-(plate-6)*4;
   Poly(g,Color.FromArgb(205,105,35,17),new PointF(-w,y),new PointF(4,y-11),new PointF(w,y+6),new PointF(w-6,y+23),new PointF(-7,y+31),new PointF(-w+6,y+18));
   Line(g,Color.FromArgb(245,255,196,47),3,new PointF(-w,y+4),new PointF(-6,y+15),new PointF(w,y+7));
  }
  Line(g,Color.FromArgb(100,255,244,144),14,new PointF(0,69),new PointF(-11,147),new PointF(9,208),new PointF(-10,289),new PointF(0,435));
  Line(g,Color.FromArgb(255,255,231,104),4,new PointF(0,69),new PointF(-11,147),new PointF(9,208),new PointF(-10,289),new PointF(0,435));
  for(int side=-1;side<=1;side+=2)for(int fire=0;fire<10;fire++){
   float y=92+fire*32,w=fire<6?45:42-(fire-6)*6;
   Flame(g,side*w,y,29+(float)Math.Sin(t*3+fire)*12,side*(13+(float)Math.Sin(t*2+fire)*8),155);
  }
  // Hooked black-and-bronze guard with a burning central inset.
  Poly(g,Color.FromArgb(255,59,35,24),new PointF(-83,32),new PointF(-75,-1),new PointF(-48,16),new PointF(-28,11),new PointF(-12,29),new PointF(12,29),new PointF(28,11),new PointF(48,16),new PointF(75,-1),new PointF(83,32),new PointF(45,53),new PointF(21,46),new PointF(0,63),new PointF(-21,46),new PointF(-45,53));
  Line(g,Color.FromArgb(240,185,98,32),3,new PointF(-78,24),new PointF(-49,33),new PointF(-21,29),new PointF(0,49),new PointF(21,29),new PointF(49,33),new PointF(78,24));
  Glow(g,0,35,18,Color.FromArgb(175,255,118,0));
  Line(g,Color.FromArgb(255,44,32,25),19,new PointF(0,-74),new PointF(0,22));
  for(int wrap=0;wrap<6;wrap++)Line(g,Color.FromArgb(255,134,96,40),3,new PointF(-8,-67+wrap*14),new PointF(8,-60+wrap*14));
  g.Restore(materialize);
  if(weaponForm>0&&weaponForm<1)Glow(g,0,-90+550*weaponForm,30,Color.FromArgb(210,255,183,49));
  var right=g.Save();g.TranslateTransform(22,-28);g.ScaleTransform(.9f*Math.Max(.05f,grip),.9f*Math.Max(.05f,grip));Fist(g,1);g.Restore(right);
  g.Restore(sword);
  // The impact darkens and fractures the icon, throwing molten fragments outward.
  if(ruin>0){
   var face=g.Save();g.SetClip(new Rectangle(309,309,406,406));
   using(var destroyed=new SolidBrush(Color.FromArgb((int)(ruin*96),8,8,7)))g.FillRectangle(destroyed,309,309,406,406);
   for(int crack=0;crack<11;crack++){
    double a=crack*Math.PI*2/11;float radius=ruin*237;
    PointF[] fissure=new PointF[]{new PointF(512,548),new PointF(512+(float)Math.Cos(a)*radius*.4f,548+(float)Math.Sin(a)*radius*.4f),new PointF(512+(float)Math.Cos(a+.17)*radius*.7f,548+(float)Math.Sin(a+.17)*radius*.7f),new PointF(512+(float)Math.Cos(a)*radius,548+(float)Math.Sin(a)*radius)};
    Line(g,Color.FromArgb(60,255,84,0),14,fissure);Line(g,Color.FromArgb((int)(215*(1-ruin*.45f)),255,184,41),3.5f,fissure);
   }
   g.Restore(face);
   float burst=(float)Math.Sin(ruin*Math.PI);
   Glow(g,512,548,65+ruin*108,Color.FromArgb((int)(burst*165),255,132,7));
   for(int shock=0;shock<2;shock++){
    float age=Math.Max(0,Math.Min(1,(ruin-shock*.17f)/.83f)),r=20+age*244;
    using(var halo=new Pen(Color.FromArgb((int)((1-age)*85),255,116,0),18))g.DrawEllipse(halo,512-r,548-r*.7f,r*2,r*1.4f);
    using(var core=new Pen(Color.FromArgb((int)((1-age)*210),255,218,93),3))g.DrawEllipse(core,512-r,548-r*.7f,r*2,r*1.4f);
   }
   for(int fire=0;fire<16;fire++){
    double a=fire*Math.PI*2/16;float radius=ruin*143;
    float x=512+(float)Math.Cos(a)*radius,y=548+(float)Math.Sin(a)*radius;
    Flame(g,x,y,25+burst*57,(float)Math.Sin(t*3+fire)*20,(int)(burst*145));
   }
   for(int shard=0;shard<38;shard++){
    double a=shard*2.4;float distance=ruin*(145+shard%5*22);
    float x=512+(float)Math.Cos(a)*distance,y=548+(float)Math.Sin(a)*distance+ruin*ruin*35;
    Poly(g,Color.FromArgb((int)((1-ruin)*240),162,87,21),new PointF(x-7,y-9),new PointF(x+10,y-3),new PointF(x+3,y+11));
    Line(g,Color.FromArgb((int)((1-ruin)*195),255,177,39),2,new PointF(x-6,y-7),new PointF(x+8,y-3));
   }
  }
  for(int y=642;y<819;y++)for(int x=592;x<821;x++){
   float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));
   float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(x,y);
   if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[SargerasArt]::Write($destination)
