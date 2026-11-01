param(
 [ValidateSet('Enhancement','Elemental','Restoration')][string]$Effect='Enhancement',
 [string]$OutputDirectory,
 [switch]$LoopOnly,
 [switch]$ElementalIntro,
 [switch]$Stormbringer
)
if(-not $OutputDirectory){$OutputDirectory=Join-Path $PSScriptRoot $(if($Effect -eq 'Restoration'){'../art/krita/Restoration-animation-v1'}elseif($Effect -eq 'Elemental'){'../art/krita/Elemental-animation-v6'}else{'../art/krita/Enhancement-animation-v12'})}
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.IO;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
public static class EnhancementStorm {
 const double Tau=Math.PI*2;
 static PointF Mix(PointF a,PointF b,float t){return new PointF(a.X+(b.X-a.X)*t,a.Y+(b.Y-a.Y)*t);}
 static void Stroke(Graphics g,PointF[] p,Color color,float width){
  using(var pen=new Pen(color,width)){pen.LineJoin=LineJoin.Bevel;g.DrawLines(pen,p);}
 }
 static PointF[] Reveal(PointF[] p,float progress){
  float count=progress*(p.Length-1);int whole=Math.Min(p.Length-2,(int)count);
  var result=new PointF[whole+2];Array.Copy(p,result,whole+1);
  result[whole+1]=Mix(p[whole],p[whole+1],count-whole);return result;
 }
 static PointF[] Bolt(double t,int arc){
  // Endpoints and interior forks wander independently, never translate as a rigid shape.
  double heading=arc*2.1+.45*Math.Sin(t+arc);
  var start=new PointF(512+(float)Math.Cos(heading)*260,512+(float)Math.Sin(heading)*250);
  var end=new PointF(512-(float)Math.Cos(heading+.6)*250,512-(float)Math.Sin(heading+.6)*230);
  var p=new PointF[11];
  for(int j=0;j<p.Length;j++){
   float u=j/10f;var v=Mix(start,end,u);
   double bend=Math.Sin(u*Math.PI);
   p[j]=new PointF(v.X+(float)(bend*(55*Math.Sin(t*3+j*2.7+arc)+24*Math.Sin(t*7-j))),
    v.Y+(float)(bend*(58*Math.Cos(t*4+j*3.3+arc)+22*Math.Sin(t*5+j))));
  }return p;
 }
 static void Lightning(Graphics g,PointF[] p,float alpha,float width){
  Stroke(g,p,Color.FromArgb((int)(alpha*22),25,85,255),width+28);
  Stroke(g,p,Color.FromArgb((int)(alpha*55),28,122,255),width+13);
  Stroke(g,p,Color.FromArgb((int)(alpha*210),38,152,255),width+5);
  Stroke(g,p,Color.FromArgb((int)(alpha*255),163,228,255),width);
  Stroke(g,p,Color.FromArgb((int)(alpha*245),243,253,255),width*.32f);
 }
 static void Earth(Graphics g,double phase){
  // Three separate diagonal sunders. No ground bed underneath the icon.
  for(int split=0;split<3;split++){
  float opening=(float)Math.Pow(.5-.5*Math.Cos(phase*3+split*.9),.65);
  float width=8+opening*15;
  float[] tearX={328,365,406,432,480,507,551};
  float[] tearY={660,618,589,544,515,471,424};
  var a=new PointF[7];var b=new PointF[7];
  for(int j=0;j<7;j++){
   float taper=j==6?0:1-j*.10f;
   float x=tearX[j]+split*65,y=tearY[j]+split*12;
   a[j]=new PointF(x-width*taper,y);
   b[j]=new PointF(x+width*taper,y);
  }
  var openingShape=new PointF[14];Array.Copy(a,openingShape,7);
  for(int j=0;j<7;j++)openingShape[7+j]=b[6-j];
  using(var abyss=new SolidBrush(Color.FromArgb(250,23,17,13)))g.FillPolygon(abyss,openingShape);
  Stroke(g,a,Color.FromArgb(245,122,80,43),10);
  Stroke(g,b,Color.FromArgb(245,94,61,35),12);
  Stroke(g,a,Color.FromArgb(245,219,169,102),5);
  Stroke(g,b,Color.FromArgb(235,179,128,68),5);
  }
 }
 static void Totem(Graphics g,float x,float y,bool fire,double phase){
  var saved=g.Save();g.TranslateTransform(x,y);
  Color accent=fire?Color.FromArgb(255,239,111,28):Color.FromArgb(255,89,218,94);
  // Local elemental energy surrounds each totem instead of a generic halo.
  for(int wisp=0;wisp<5;wisp++){
   double progress=(phase/Tau*2+wisp/5.0)%1;
   float side=wisp%2==0?-1:1;
   float wx=side*(36+(float)Math.Sin(progress*4+wisp)*10);
   float wy=56-(float)progress*155;
   int alpha=(int)(Math.Sin(progress*Math.PI)*210);
   if(fire){
    using(var flame=new SolidBrush(Color.FromArgb(alpha,255,105+wisp*15,24)))g.FillPolygon(flame,new PointF[]{
     new PointF(wx-8,wy+9),new PointF(wx-10,wy-3),new PointF(wx+3,wy-27),new PointF(wx+9,wy),new PointF(wx+4,wy+11)});
   }else{
    using(var energy=new SolidBrush(Color.FromArgb(alpha,91,225,106)))g.FillPolygon(energy,new PointF[]{
     new PointF(wx,wy-12),new PointF(wx+7,wy-2),new PointF(wx+3,wy+10),new PointF(wx-6,wy+4)});
    Stroke(g,new PointF[]{new PointF(wx,wy+16),new PointF(wx-4,wy+25),new PointF(wx+2,wy+33)},Color.FromArgb(alpha/2,162,255,142),3);
   }
  }
  using(var wood=new SolidBrush(Color.FromArgb(255,92,58,34)))
   g.FillPolygon(wood,new PointF[]{new PointF(-25,60),new PointF(-31,-17),new PointF(-20,-47),new PointF(20,-47),new PointF(31,-17),new PointF(25,60)});
  using(var shade=new SolidBrush(Color.FromArgb(255,52,36,25)))g.FillRectangle(shade,-12,-35,24,92);
  Stroke(g,new PointF[]{new PointF(-35,55),new PointF(35,55)},Color.FromArgb(255,163,122,69),10);
  Stroke(g,new PointF[]{new PointF(-32,-24),new PointF(0,-40),new PointF(32,-24)},Color.FromArgb(255,183,143,85),9);
  Stroke(g,new PointF[]{new PointF(-44,-9),new PointF(-21,3),new PointF(0,-7),new PointF(21,3),new PointF(44,-9)},accent,8);
  Stroke(g,new PointF[]{new PointF(-12,12),new PointF(0,27),new PointF(12,12),new PointF(0,-2),new PointF(-12,12)},accent,5);
  if(fire){
   float sway=(float)Math.Sin(phase*3)*10;
   using(var flame=new SolidBrush(Color.FromArgb(235,242,99,24)))g.FillPolygon(flame,new PointF[]{
    new PointF(-23,-42),new PointF(-28,-67),new PointF(-7+sway,-93),new PointF(5+sway,-120),
    new PointF(15,-87),new PointF(28,-66),new PointF(19,-42)});
   using(var core=new SolidBrush(Color.FromArgb(250,255,214,102)))g.FillPolygon(core,new PointF[]{
    new PointF(-10,-43),new PointF(-12,-65),new PointF(sway,-88),new PointF(12,-62),new PointF(9,-43)});
  }else{
   float pulse=(float)(.65+.35*Math.Sin(phase*2));
   using(var glow=new SolidBrush(Color.FromArgb((int)(pulse*65),82,226,94)))g.FillEllipse(glow,-38,-91,76,62);
   using(var gem=new SolidBrush(accent))g.FillPolygon(gem,new PointF[]{new PointF(0,-94),new PointF(17,-71),new PointF(0,-47),new PointF(-17,-71)});
   Stroke(g,new PointF[]{new PointF(-3,-85),new PointF(-9,-71),new PointF(-2,-60)},Color.FromArgb(240,206,255,166),4);
  }
  g.Restore(saved);
 }
 static void Lava(Graphics g,double phase){
  VolcanicVents(g,phase);
 }
 static void VolcanicVents(Graphics g,double phase){
  // Low, heavy molten pools on either side; no flame-shaped ribbons.
  for(int side=-1;side<=1;side+=2){
   float x=512+side*242;
   using(var heat=new SolidBrush(Color.FromArgb(42,255,78,12)))g.FillEllipse(heat,x-93,656,186,102);
   using(var basalt=new SolidBrush(Color.FromArgb(245,49,32,28)))g.FillPolygon(basalt,new PointF[]{
    new PointF(x-79,711),new PointF(x-62,668),new PointF(x-28,679),new PointF(x-9,648),
    new PointF(x+31,665),new PointF(x+58,661),new PointF(x+84,711),new PointF(x+41,743),new PointF(x-44,740)});
   using(var molten=new LinearGradientBrush(new PointF(x,681),new PointF(x,729),Color.FromArgb(255,255,194,54),Color.FromArgb(255,184,41,8)))
    g.FillEllipse(molten,x-65,682,130,44);
   for(int crust=0;crust<4;crust++){
    float cx=x-47+crust*29+(float)Math.Sin(phase+crust)*5;
    using(var dark=new SolidBrush(Color.FromArgb(240,67,33,22)))g.FillPolygon(dark,new PointF[]{new PointF(cx-12,694),new PointF(cx+7,688),new PointF(cx+17,700),new PointF(cx,709),new PointF(cx-15,704)});
   }
   for(int drop=0;drop<8;drop++){
    double progress=(phase/Tau+drop*.125+(side>0?.18:0))%1;
    float jump=(float)Math.Sin(progress*Math.PI);
    float dx=x+side*((float)progress*83-25)+(float)Math.Sin(drop*3)*21;
    float dy=692-jump*(88+drop%3*41);
    float size=9+(drop%3)*3;
    using(var glow=new SolidBrush(Color.FromArgb((int)(jump*45),255,84,8)))g.FillEllipse(glow,dx-size,dy-size,size*2,size*2);
    using(var lava=new SolidBrush(Color.FromArgb((int)(jump*250),255,114+drop*9,20)))g.FillEllipse(lava,dx,dy,size,size*(.8f+jump*.5f));
    using(var core=new SolidBrush(Color.FromArgb((int)(jump*235),255,225,116)))g.FillEllipse(core,dx+2,dy+2,size*.4f,size*.3f);
   }
   // Inner spill overlaps the lower icon corner, grounding it in the scene.
   var spill=new PointF[]{new PointF(x,717),new PointF(x-side*48,727),new PointF(x-side*88,713),new PointF(x-side*119,728)};
   Stroke(g,spill,Color.FromArgb(225,193,45,9),18);
   Stroke(g,spill,Color.FromArgb(240,255,164,35),7);
  }
 }
 static void ElementalStorm(Graphics g,double phase){
  // Eight staggered strikes per second, with slightly shorter, slimmer channels.
  float[] strikePositions={260,744,432,795,555,320,660,385};
  for(int strike=0;strike<8;strike++){
   double cycle=(phase/Tau*3+strike/8.0)%1;
   if(cycle>.24)continue;
   float energy=cycle<.085?1f:cycle<.17?.6f:.22f;
   ElementalBolt(g,strikePositions[strike],strike,energy,(float)cycle);
  }
 }
 static void ElementalBolt(Graphics g,float x,int strike,float energy,float cycle){
   var p=new PointF[9];
   for(int j=0;j<9;j++)p[j]=new PointF(x+(j==0||j==8?0:(float)Math.Sin(j*4.7+strike*2)*30),286+j*50);
   Stroke(g,p,Color.FromArgb((int)(energy*40),99,113,255),42);
   Stroke(g,p,Color.FromArgb((int)(energy*130),100,161,255),20);
   Stroke(g,p,Color.FromArgb((int)(energy*250),166,205,255),9);
   Stroke(g,p,Color.FromArgb((int)(energy*255),255,255,242),3.3f);
   var fork=new PointF[]{p[3],new PointF(x+(strike%2==0?83:-83),446),new PointF(x+(strike%2==0?101:-101),508)};
   Stroke(g,fork,Color.FromArgb((int)(energy*210),186,220,255),4);
   float burst=12+45*(float)cycle;
   Stroke(g,new PointF[]{new PointF(x-burst,700),new PointF(x,686),new PointF(x+burst,700)},Color.FromArgb((int)(energy*220),248,232,175),5);
 }
 static void ElementalOpening(Graphics g,int frame){
  // All twelve channels land together, then decay before the existing loop.
  float[] positions={260,744,432,795,555,320,660,385,490,605,215,835};
  float energy=frame==0?1f:frame==1?.85f:frame==2?.6f:frame==3?.35f:frame==4?.16f:.06f;
  for(int strike=0;strike<positions.Length;strike++)ElementalBolt(g,positions[strike],strike,energy,frame/24f);
 }
 static void StormbringerGround(Graphics g,int frame){
  double phase=frame*Tau/36;
  // A compact rotating storm above, with cold illuminated inner curls.
  using(var cloud=new GraphicsPath()){
   cloud.FillMode=FillMode.Winding;
   cloud.AddEllipse(318,173,180,102);cloud.AddEllipse(407,124,173,132);cloud.AddEllipse(528,155,185,117);cloud.AddEllipse(365,210,285,77);
   using(var fill=new LinearGradientBrush(new PointF(512,130),new PointF(512,287),Color.FromArgb(245,32,89,109),Color.FromArgb(245,19,33,51)))g.FillPath(fill,cloud);
  }
  for(int curl=0;curl<3;curl++)using(var edge=new Pen(Color.FromArgb(125,77,218,241),5-curl))g.DrawArc(edge,377+curl*23,153+curl*15,238-curl*48,99-curl*18,(float)(phase*180/Math.PI)+curl*80,235);
 }
 static void StormbringerStrike(Graphics g,int frame){
  int beat=frame%12;if(beat>3)return;
  float energy=beat==0?1:beat==1?.8f:beat==2?.46f:.2f;
  float x=frame<12?430:frame<24?590:512;
  var random=new Random(864+frame/12*41);var bolt=new PointF[12];
  for(int j=0;j<12;j++){float u=j/11f;bolt[j]=new PointF(x+(512-x)*u+(j==0||j==11?0:random.Next(-42,43)),259+u*511);}
  Lightning(g,bolt,energy,9);
  for(int fork=0;fork<3;fork++){
   PointF start=bolt[3+fork*2];float side=fork%2==0?-1:1;
   Lightning(g,new PointF[]{start,new PointF(start.X+side*58,start.Y+39),new PointF(start.X+side*41,start.Y+75),new PointF(start.X+side*110,start.Y+121)},energy*.75f,4);
  }
 }
 static void LegacyLava(Graphics g,double phase){
  // A heavy molten bed, with rolling crests and dark cooling crust.
  var top=new PointF[17];var pool=new PointF[34];
  for(int j=0;j<17;j++){
   float x=244+j*33.5f;
   float y=704+(float)Math.Sin(phase*2+j*.8)*16+(float)Math.Cos(phase*3-j*.7)*8;
   top[j]=new PointF(x,y);pool[j]=top[j];
   pool[33-j]=new PointF(x,756+(float)Math.Sin(j*.6+phase)*12);
  }
  using(var bed=new SolidBrush(Color.FromArgb(240,96,29,17)))g.FillPolygon(bed,pool);
  Stroke(g,top,Color.FromArgb(60,255,70,8),65);
  Stroke(g,top,Color.FromArgb(245,234,62,12),34);
  Stroke(g,top,Color.FromArgb(250,255,144,22),17);
  Stroke(g,top,Color.FromArgb(255,255,226,108),5);
  for(int side=-1;side<=1;side+=2){
   // Solid tongues of lava rise beside the icon and curl over its lower corners.
   float surge=(float)(.5+.5*Math.Sin(phase*2+side));
   float x=512+side*201;
   var tongue=new PointF[]{new PointF(x-side*34,717),new PointF(x+side*34,708),
    new PointF(x+side*49,625),new PointF(x+side*(23+surge*17),542-surge*74),
    new PointF(x-side*12,493-surge*62),new PointF(x+side*6,590),new PointF(x-side*23,647)};
   using(var outer=new SolidBrush(Color.FromArgb(225,223,60,12)))g.FillPolygon(outer,tongue);
   var stream=new PointF[]{new PointF(x,709),new PointF(x+side*20,645),new PointF(x+side*15,591),new PointF(x-side*4,538-surge*55)};
   Stroke(g,stream,Color.FromArgb(240,255,161,33),14);
   Stroke(g,stream,Color.FromArgb(245,255,232,136),4);
   for(int ember=0;ember<7;ember++){
    double progress=(phase/Tau+ember*.143+(side>0?.07:0))%1;
    float drift=(float)Math.Sin(progress*4+ember)*35;
    float ex=x+drift-side*(float)progress*40;
    float ey=684-(float)progress*(180+ember*12);
    int alpha=(int)(Math.Sin(progress*Math.PI)*235);
    using(var brush=new SolidBrush(Color.FromArgb(alpha,255,172,43)))g.FillEllipse(brush,ex,ey,7+ember%3,12);
   }
  }
  // Short molten seams cross the lower icon without obscuring its whole face.
  for(int seam=0;seam<3;seam++){
   float shift=(float)Math.Sin(phase*2+seam)*13;
   var p=new PointF[]{new PointF(366+seam*82,704),new PointF(397+seam*73+shift,658),new PointF(382+seam*74,615)};
   Stroke(g,p,Color.FromArgb(195,177,45,9),15);
   Stroke(g,p,Color.FromArgb(235,255,172,46),6);
  }
 }
 static void Water(Graphics g,double phase){
  float tide=440+(float)Math.Sin(phase)*24;
  using(var flood=new GraphicsPath()){
   flood.AddBezier(330,tide,432,tide-20,584,tide+26,694,tide-4);
   flood.AddLine(694,tide-4,694,692);flood.AddLine(694,692,330,692);flood.CloseFigure();
   using(var water=new LinearGradientBrush(new PointF(512,tide-24),new PointF(512,694),Color.FromArgb(85,116,235,246),Color.FromArgb(165,12,104,173)))g.FillPath(water,flood);
  }
  WaterTotem(g,302,582,phase);WaterTotem(g,722,582,phase+Math.PI);
  // Broad, clearly outlined storm-cloud silhouette with a dark rain-bearing base.
  using(var cloud=new GraphicsPath()){
   cloud.FillMode=FillMode.Winding;
   cloud.AddEllipse(325,243,155,85);cloud.AddEllipse(399,207,145,115);
   cloud.AddEllipse(476,190,158,132);cloud.AddEllipse(570,227,140,97);
   cloud.AddEllipse(377,261,278,73);
   using(var fill=new LinearGradientBrush(new PointF(512,190),new PointF(512,334),Color.FromArgb(250,183,214,230),Color.FromArgb(250,58,91,125)))g.FillPath(fill,cloud);
  }
  using(var underside=new SolidBrush(Color.FromArgb(115,40,72,107)))g.FillEllipse(underside,382,292,270,32);
  for(int rain=0;rain<68;rain++){
   double p=(phase/Tau*4+rain*.137)%1;
   float x=355+(rain%17)*19+(float)Math.Sin(rain*3)*5;
   float y=327+(float)p*369;
   int alpha=(int)(Math.Sin(p*Math.PI)*225);
   Stroke(g,new PointF[]{new PointF(x,y),new PointF(x-9,y+24+rain%3*4)},Color.FromArgb(alpha,177,231,255),rain%3==0?3.5f:2.5f);
  }
  for(int bubble=0;bubble<10;bubble++){
   double p=(phase/Tau+bubble*.1)%1;
   float x=370+bubble*29+(float)Math.Sin(phase+bubble)*8,y=684-(float)p*197;
   using(var rim=new Pen(Color.FromArgb((int)(Math.Sin(p*Math.PI)*160),184,255,248),2))g.DrawEllipse(rim,x,y,7+bubble%3*2,7+bubble%3*2);
  }
 }
 static void WaterTotem(Graphics g,float x,float y,double phase){
  var saved=g.Save();g.TranslateTransform(x,y);
  g.ScaleTransform(1.15f,1.15f);
  // Same compact carved silhouette as the approved Enhancement totems.
  using(var wood=new SolidBrush(Color.FromArgb(255,81,65,48)))g.FillPolygon(wood,new PointF[]{new PointF(-25,60),new PointF(-31,-17),new PointF(-20,-47),new PointF(20,-47),new PointF(31,-17),new PointF(25,60)});
  Stroke(g,new PointF[]{new PointF(-35,55),new PointF(35,55)},Color.FromArgb(255,161,147,110),10);
  Stroke(g,new PointF[]{new PointF(-32,-24),new PointF(0,-40),new PointF(32,-24)},Color.FromArgb(255,154,216,219),9);
  Stroke(g,new PointF[]{new PointF(-43,-9),new PointF(-20,3),new PointF(0,-7),new PointF(20,3),new PointF(43,-9)},Color.FromArgb(255,98,222,242),8);
  using(var rune=new SolidBrush(Color.FromArgb(255,137,246,248)))g.FillPolygon(rune,new PointF[]{new PointF(0,-5),new PointF(11,13),new PointF(0,23),new PointF(-11,13)});
  float orbY=-125+(float)Math.Sin(phase)*5;
  var orb=g.Save();g.TranslateTransform(0,orbY);g.ScaleTransform(1.75f,1.75f);g.TranslateTransform(0,-orbY);
  using(var sphere=new GraphicsPath()){
   sphere.AddEllipse(-31,orbY-31,62,62);
   using(var fill=new PathGradientBrush(sphere)){
    fill.CenterPoint=new PointF(-9,orbY-10);fill.CenterColor=Color.FromArgb(250,220,255,255);
    fill.SurroundColors=new Color[]{Color.FromArgb(245,24,131,207)};g.FillPath(fill,sphere);
   }
   using(var rim=new Pen(Color.FromArgb(240,150,246,255),3))g.DrawPath(rim,sphere);
  }
  // Rotate the water surface inside each orb; the carved totem stays still.
  var surface=g.Save();g.TranslateTransform(0,orbY);g.RotateTransform((float)Math.Sin(phase)*18);
  for(int band=0;band<3;band++){
   float offset=(float)Math.Sin(phase+band*2.1)*6;
   using(var ripple=new Pen(Color.FromArgb(160,186,255,255),4))g.DrawArc(ripple,-23+band*3,-19+band*10+offset,42-band*5,18,15+band*35,140);
  }
  using(var shine=new SolidBrush(Color.FromArgb(185,231,255,255)))g.FillEllipse(shine,-17,-20,11,7);
  g.Restore(surface);
  g.Restore(orb);
  // Separate water drops leak underneath and fall past either side of the wood.
  for(int bead=0;bead<8;bead++){
   double p=(phase/Tau*2+bead/8.0)%1;
   float side=bead%2==0?-1:1;
   float dx=side*(22+(float)p*26)+(float)Math.Sin(bead*2.3)*5;
   float dy=orbY+49+(float)(p*p)*165,size=9+bead%3*2;
   int alpha=(int)(255-p*130);
   using(var drop=new SolidBrush(Color.FromArgb(alpha,92,216,245)))g.FillEllipse(drop,dx-size/2,dy,size,size*(1.3f+(float)p));
   using(var gleam=new SolidBrush(Color.FromArgb(alpha,215,255,255)))g.FillEllipse(gleam,dx-size/4,dy+1,size*.35f,size*.6f);
  }
  g.Restore(saved);
 }

 static void HammerStorm(Graphics g,int frame,bool intro){
  double cycle=intro?frame/36.0:.56;
  // Discrete, seeded channels jump each frame instead of flowing between paths.
  var random=new Random(617+frame*197);
  bool impact=intro&&frame>=6&&frame<=8;
  int channels=intro&&frame<6?0:impact?24:6;
  for(int bolt=0;bolt<channels;bolt++){
   bool descending=impact;
   var p=new PointF[8];
   float sx=descending?330+random.Next(360):355+random.Next(300);
   float sy=descending?190+random.Next(75):365+random.Next(280);
   float ex=descending?385+random.Next(245):355+random.Next(300);
   float ey=descending?580+random.Next(90):365+random.Next(280);
   if(impact){
    // Explode from the hammer contact across the whole icon and both totems.
    double angle=bolt*Tau/24;
    sx=512;sy=338;
    ex=512+(float)Math.Cos(angle)*(330+random.Next(70));
    ey=512+(float)Math.Sin(angle)*(325+random.Next(65));
   }
   for(int j=0;j<8;j++){
    float u=j/7f;
    p[j]=new PointF(sx+(ex-sx)*u+(j==0||j==7?0:random.Next(-36,37)),
     sy+(ey-sy)*u+(descending?0:random.Next(-32,33)));
   }
   Lightning(g,p,impact?(bolt%3==0?1f:.65f):(bolt%2==frame%2?1f:.48f),impact?(bolt%3==0?15:9):bolt==0?8:4);
   if(impact){
    var fork=new PointF[]{p[4],new PointF(p[5].X+random.Next(-95,96),p[5].Y-45),new PointF(ex+random.Next(-60,61),ey-65)};
    Lightning(g,fork,.65f,6);
   }
  }
  if(intro&&frame<=10){
   // Fixed grip above the icon: rotate the head through an anvil strike.
   float swing=(float)Math.Max(0,Math.Min(1,(frame-2)/4.0));
   float ease=swing*swing;
   float rebound=frame>6?(frame-6)/4f:0;
   float opacity=frame<=6?1:(10-frame)/4f;
   var saved=g.Save();g.TranslateTransform(512,185);g.RotateTransform(-72+ease*72-rebound*22);g.TranslateTransform(0,115);
   using(var handle=new Pen(Color.FromArgb((int)(opacity*255),103,65,39),17))g.DrawLine(handle,0,-111,0,-18);
   for(int wrap=0;wrap<5;wrap++)Stroke(g,new PointF[]{new PointF(-8,-107+wrap*17),new PointF(8,-100+wrap*17)},Color.FromArgb((int)(opacity*245),191,147,83),4);
   using(var steel=new SolidBrush(Color.FromArgb((int)(opacity*255),113,145,168)))g.FillPolygon(steel,new PointF[]{
    new PointF(-65,-25),new PointF(-51,-40),new PointF(52,-40),new PointF(67,-23),
    new PointF(67,23),new PointF(51,38),new PointF(-52,38),new PointF(-65,22)});
   using(var face=new SolidBrush(Color.FromArgb((int)(opacity*255),192,219,233)))g.FillRectangle(face,-50,-26,99,49);
   Stroke(g,new PointF[]{new PointF(-58,-27),new PointF(-48,-34),new PointF(49,-34),new PointF(59,-23)},Color.FromArgb((int)(opacity*255),232,252,255),5);
   Stroke(g,new PointF[]{new PointF(8,-19),new PointF(-9,2),new PointF(7,0),new PointF(-8,22)},Color.FromArgb((int)(opacity*255),33,121,220),5);
   g.Restore(saved);
  }
  if(intro&&frame>=7&&frame<=11){
   float spread=22+(frame-7)*26;
   float alpha=1-(frame-7)/5f;
   for(int side=-1;side<=1;side+=2)Lightning(g,new PointF[]{new PointF(512,340),new PointF(512+side*spread,355),new PointF(512+side*(spread+20),380)},alpha,5);
  }
 }
 public static void Write(string output,bool elemental,bool restoration,bool intro,bool elementalIntro,bool stormbringer){
  for(int frame=0;frame<36;frame++)using(var image=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)){
   double t=frame*Tau/36;
   using(var g=Graphics.FromImage(image)){
    g.SmoothingMode=SmoothingMode.AntiAlias;g.PixelOffsetMode=PixelOffsetMode.HighQuality;
    if(elementalIntro)ElementalOpening(g,Math.Min(frame,5));
    else {
    if(elemental&&stormbringer)StormbringerGround(g,frame);
    if(restoration)Water(g,t);else if(elemental)Lava(g,t);
    if(elemental){ElementalStorm(g,t);if(stormbringer)StormbringerStrike(g,frame);}
    else if(!restoration)HammerStorm(g,frame,intro);
    if(!elemental&&!restoration){Totem(g,301,580,true,t);Totem(g,723,580,false,t);}
    }
   }
   image.Save(Path.Combine(output,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
  }
 }
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[EnhancementStorm]::Write($destination,($Effect -eq 'Elemental'),($Effect -eq 'Restoration'),(-not $LoopOnly),$ElementalIntro.IsPresent,$Stormbringer.IsPresent)
[IO.File]::WriteAllText((Join-Path $destination 'animation.json'),'{"fps":12,"firstFrame":0,"lastFrame":35,"frames":36,"durationSeconds":3,"width":1024,"height":1024,"alpha":true}')
Write-Output "Created branching storm over a ground rupture: $destination"
