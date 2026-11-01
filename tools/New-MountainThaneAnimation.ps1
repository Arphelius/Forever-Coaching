param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/ProtectionWarrior-MountainThane-v11'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class MountainThaneArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static float Smooth(float p){p=Math.Max(0,Math.Min(1,p));return p*p*(3-2*p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Bevel;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var path=new GraphicsPath()){path.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(path)){b.CenterColor=c;b.SurroundColors=new[]{Color.Transparent};g.FillPath(b,path);}}}
 static void Plate(Graphics g,params PointF[] p){using(var b=new LinearGradientBrush(P(310,180),P(650,690),Color.FromArgb(255,115,110,83),Color.FromArgb(255,28,43,52)))g.FillPolygon(b,p);Line(g,Color.FromArgb(255,160,142,99),6,p);Line(g,Color.FromArgb(180,70,93,100),2,p);}
 static void Bolt(Graphics g,int alpha,params PointF[] p){Line(g,Color.FromArgb(alpha/4,0,155,255),18,p);Line(g,Color.FromArgb(alpha,21,211,255),5,p);Line(g,Color.FromArgb(alpha,197,251,255),2,p);}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;float p=f/36f;double t=f/18.0*Math.PI*2;
  float impact=Smooth((p-.25f)/.04f)*(float)(.84+.16*Math.Sin(t*2));
  var groundPosition=g.Save();g.TranslateTransform(-36,0);
  // Tear open irregular earth fissures with raised, separated rock lips.
  float rupture=Smooth((p-.25f)/.16f);
  for(int crack=0;crack<8;crack++){
   double direction=crack*2.399+.28;
   float dx=(float)Math.Cos(direction),dy=(float)Math.Sin(direction)*.48f;
   float length=(160+crack%4*47)*rupture;
   PointF[] split=new PointF[9];
   for(int node=0;node<9;node++){
    float u=node/8f,jag=node==0?0:(float)Math.Sin(node*3.7+crack*1.9)*(9+u*12)*rupture;
    split[node]=P(367+dx*length*u-dy*jag,740+dy*length*u+dx*jag);
   }
   for(int node=0;node<8;node++){
    PointF a=split[node],b=split[node+1];float width=(15-node*1.4f)*rupture;
    float nx=-dy,ny=dx*.65f;
    Poly(g,Color.FromArgb((int)(rupture*245),71,66,57),P(a.X+nx*(width+10),a.Y+ny*(width+10)-5),P(b.X+nx*(width+6),b.Y+ny*(width+6)-3),P(b.X-nx*(width+7),b.Y-ny*(width+7)),P(a.X-nx*(width+9),a.Y-ny*(width+9)));
    Poly(g,Color.FromArgb((int)(rupture*255),12,13,15),P(a.X+nx*width,a.Y+ny*width),P(b.X+nx*width*.8f,b.Y+ny*width*.8f),P(b.X-nx*width*.7f,b.Y-ny*width*.7f),P(a.X-nx*width,a.Y-ny*width));
    Line(g,Color.FromArgb((int)(rupture*235),158,145,115),3,P(a.X+nx*(width+5),a.Y+ny*(width+5)-4),P(b.X+nx*(width+3),b.Y+ny*(width+3)-3));
    if(node%3==1){float side=node%2==0?-1:1;PointF end=P(b.X-dy*side*35,b.Y+dx*side*22);Line(g,Color.FromArgb((int)(rupture*230),63,58,49),12,b,end);Line(g,Color.FromArgb((int)(rupture*255),15,16,17),5,b,end);}
   }
  }
  if(p>=.25f){
   // Sustained thunder erupts only after the shield lands, then loops continuously.
   for(int strike=0;strike<7;strike++){
    float u=(float)(((f-9)/9.0+strike*.137)%1),blast=1-(float)Math.Pow(1-u,3);int a=(int)((1-u)*245);
    double direction=strike*2.399;
    float dx=(float)Math.Cos(direction),dy=(float)Math.Sin(direction)*.52f;
    float reach=65+blast*(145+strike%4*27),jag=(strike%2==0?1:-1)*(12+u*13);
    PointF start=P(367+dx*blast*70,740+dy*blast*70);
    PointF middle=P(367+dx*reach*.48f-dy*jag,740+dy*reach*.48f+dx*jag);
    PointF end=P(367+dx*reach,740+dy*reach);
    Line(g,Color.FromArgb(a/3,0,155,255),10,start,middle,P(middle.X+dx*22+dy*17,middle.Y+dy*22-dx*17),end);
    Line(g,Color.FromArgb(a,146,239,255),3,start,middle,P(middle.X+dx*22+dy*17,middle.Y+dy*22-dx*17),end);
    Line(g,Color.FromArgb(a/2,220,234,237),3,P(end.X-dx*26,end.Y-dy*26),P(end.X+dx*20,end.Y+dy*20));
   }
   for(int chip=0;chip<24;chip++){float u=(float)(((f-9)/18.0+chip*.137)%1);int a=(int)(Math.Sin(u*Math.PI)*235);double angle=chip*2.399;float x=367+(float)Math.Cos(angle)*(25+u*300),y=733+(float)Math.Sin(angle)*u*95-u*(1-u)*260;float r=5+chip%4*3;Poly(g,Color.FromArgb(a,78,89,94),P(x-r,y-4),P(x+3,y-r),P(x+r,y),P(x+4,y+r));Line(g,Color.FromArgb(a,163,175,172),2,P(x-r,y-4),P(x+3,y-r),P(x+r,y));}
  }
  g.Restore(groundPosition);
  // A single horned helmet sits at the center, without separate shoulder plates.
  for(int side=-1;side<=1;side+=2){var s=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   var hornSize=g.Save();g.TranslateTransform(0,344);g.ScaleTransform(1.05f,1.05f);g.TranslateTransform(0,-344);
   using(var horn=new GraphicsPath()){horn.AddBezier(47,242,117,259,152,207,123,146);horn.AddBezier(123,146,129,201,87,218,61,205);horn.CloseFigure();using(var b=new LinearGradientBrush(P(70,230),P(140,153),Color.FromArgb(255,61,76,79),Color.FromArgb(255,146,140,105)))g.FillPath(b,horn);using(var edge=new Pen(Color.FromArgb(255,174,150,100),5))g.DrawPath(edge,horn);}
   g.Restore(hornSize);
   g.Restore(s);
  }
  var helmetSize=g.Save();g.TranslateTransform(512,344);g.ScaleTransform(1.05f,1.05f);g.TranslateTransform(-512,-344);
  Plate(g,P(443,215),P(475,184),P(512,204),P(549,184),P(581,215),P(565,289),P(542,323),P(512,344),P(482,323),P(459,289),P(443,215));
  Poly(g,Color.FromArgb(255,15,30,42),P(458,240),P(489,252),P(512,238),P(535,252),P(566,240),P(547,294),P(523,307),P(512,333),P(501,307),P(477,294));
  Plate(g,P(512,204),P(526,231),P(520,311),P(512,335),P(504,311),P(498,231),P(512,204));
  for(int side=-1;side<=1;side+=2){Glow(g,512+side*32,263,25,Color.FromArgb(160,0,184,255));Line(g,Color.FromArgb(255,154,248,255),5,P(512+side*16,268),P(512+side*40,258));}
  // Lightning branches over the horns and crawls over the armor.
  int flash=(f%6<2?245:125);
  for(int side=-1;side<=1;side+=2){float jitter=(float)Math.Sin(t*5+side)*12;
   Bolt(g,flash,P(512+side*41,218),P(512+side*73,179),P(512+side*66,151),P(512+side*(110+jitter),119),P(512+side*149,153),P(512+side*130,185));
   Bolt(g,flash-30,P(512+side*111,120),P(512+side*156,103),P(512+side*170,126),P(512+side*196,111));
   Bolt(g,flash-35,P(512+side*141,207),P(512+side*166,232),P(512+side*155,258),P(512+side*188,277));
  }
  g.Restore(helmetSize);
  // The bulwark falls once and buries its sharp point below the ground line.
  float drop=Math.Min(1,p/.25f),shieldY=-700+745*drop*drop;
  if(p>=.25f)shieldY=45+(p<.34f?(float)Math.Sin((p-.25f)/.09f*Math.PI)*12:0);
  var shieldPose=g.Save();g.TranslateTransform(-36,shieldY);
  // Bowed siege steel: a broad, weighty face with a deep forged frame.
  using(var shield=new GraphicsPath()){
   shield.AddBezier(237,352,307,371,404,376,476,349);
   shield.AddBezier(476,349,485,450,477,589,444,650);
   shield.AddBezier(444,650,418,681,390,685,367,708);
   shield.AddBezier(367,708,332,684,283,696,246,665);
   shield.AddBezier(246,665,226,565,225,440,237,352);shield.CloseFigure();
   using(var fill=new LinearGradientBrush(P(227,500),P(484,500),Color.Black,Color.White)){
    fill.InterpolationColors=new ColorBlend{Colors=new[]{Color.FromArgb(255,31,30,39),Color.FromArgb(255,103,94,116),Color.FromArgb(255,73,70,88),Color.FromArgb(255,26,29,37)},Positions=new[]{0f,.37f,.65f,1f}};g.FillPath(fill,shield);
   }
   using(var shadow=new Pen(Color.FromArgb(255,14,20,22),23))g.DrawPath(shadow,shield);
   using(var rim=new Pen(Color.FromArgb(255,99,104,80),13))g.DrawPath(rim,shield);
   using(var bevel=new Pen(Color.FromArgb(255,157,151,121),3))g.DrawPath(bevel,shield);
  }
  Line(g,Color.FromArgb(230,175,162,158),3,P(255,378),P(247,447),P(249,558),P(263,644));
  Line(g,Color.FromArgb(220,25,25,33),5,P(455,380),P(462,477),P(454,581),P(430,639));
  // Six broad diamond sockets carry long, faceted armor-piercing spikes.
  for(int row=0;row<3;row++)for(int column=0;column<2;column++){
   float x=292+column*112,y=421+row*91;
   Poly(g,Color.FromArgb(255,22,25,29),P(x,y-28),P(x+28,y),P(x,y+29),P(x-28,y));
   Line(g,Color.FromArgb(255,136,132,126),4,P(x,y-28),P(x-28,y),P(x,y+29));
   float tipX=x+47+column*23,tipY=y-19+column*35;
   Poly(g,Color.FromArgb(255,26,39,40),P(x-16,y-10),P(tipX,tipY),P(x+13,y+17));
   Poly(g,Color.FromArgb(255,112,127,116),P(x-16,y-10),P(tipX,tipY),P(x+10,y-15));
   Poly(g,Color.FromArgb(255,50,66,65),P(x+10,y-15),P(tipX,tipY),P(x+13,y+17));
   Line(g,Color.FromArgb(255,177,184,156),2,P(x-16,y-10),P(tipX,tipY));
  }
  // Domed rivets and worn scratches make the bulwark read as thick physical metal.
  for(int rivet=0;rivet<7;rivet++){
   float x=260+rivet*29,y=389+(float)Math.Sin(rivet*Math.PI/6)*9;
   using(var b=new SolidBrush(Color.FromArgb(255,27,29,33)))g.FillEllipse(b,x-7,y-5,15,15);
   using(var b=new SolidBrush(Color.FromArgb(255,160,155,156)))g.FillEllipse(b,x-5,y-5,10,10);
   Line(g,Color.FromArgb(255,214,207,197),2,P(x-3,y-3),P(x+1,y-3));
   if(rivet<6){float bx=270+rivet*28,by=658+(float)Math.Sin(rivet*Math.PI/5)*8;using(var b=new SolidBrush(Color.FromArgb(255,129,128,125)))g.FillEllipse(b,bx-5,by-5,10,10);}
  }
  for(int scar=0;scar<11;scar++){float x=266+(scar*43)%171,y=444+(scar*59)%177;Line(g,Color.FromArgb(95,189,177,170),1,P(x,y),P(x+12,y-7));}
  g.Restore(shieldPose);
  // Hide the buried tip behind small foreground fragments, leaving it embedded.
  if(p>=.25f){
   var buriedPosition=g.Save();g.TranslateTransform(-36,0);
   Poly(g,Color.FromArgb(245,46,56,61),P(338,743),P(355,733),P(367,746),P(384,735),P(400,746),P(386,762),P(347,760));
   Line(g,Color.FromArgb(225,119,138,143),3,P(338,743),P(355,733),P(367,746),P(384,735),P(400,746));
   g.Restore(buriedPosition);
  }
  // Keep the rank badge clear of the shockwave and splinters.
  for(int yy=642;yy<819;yy++)for(int xx=592;xx<821;xx++){float dx=Math.Max(0,Math.Max(620-xx,xx-793)),dy=Math.Max(0,Math.Max(670-yy,yy-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(xx,yy);if(c.A>0)im.SetPixel(xx,yy,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[MountainThaneArt]::Write($destination)
