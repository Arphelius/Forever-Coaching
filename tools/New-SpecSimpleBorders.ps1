param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Spec-SimpleBorders-v1'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$styles=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'talent-border-styles.json') -Raw | ConvertFrom-Json
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SpecBorderArt {
 static PointF P(float x,float y){return new PointF(x,y);}
 static Color C(string s){return ColorTranslator.FromHtml(s);}
 static Color A(Color c,int a){return Color.FromArgb(a,c.R,c.G,c.B);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Lightning(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Miter;pen.MiterLimit=3;pen.StartCap=pen.EndCap=LineCap.Flat;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Disc(Graphics g,float x,float y,float r,Color c){using(var b=new SolidBrush(c))g.FillEllipse(b,x-r,y-r,r*2,r*2);}
 static void Mist(Graphics g,float x,float y,float w,float h,Color color){using(var p=new GraphicsPath()){
  p.AddEllipse(x-w/2,y-h/2,w,h);using(var b=new PathGradientBrush(p)){b.CenterColor=color;b.SurroundColors=new Color[]{A(color,0)};g.FillPath(b,p);}
 }}
 static void Ring(Graphics g,float x,float y,float r,Color c,float w){using(var pen=new Pen(c,w))g.DrawEllipse(pen,x-r,y-r,r*2,r*2);}
 static void Curve(Graphics g,Color c,float w,PointF a,PointF b,PointF c1,PointF d){using(var pen=new Pen(c,w)){pen.StartCap=pen.EndCap=LineCap.Round;g.DrawBezier(pen,a,b,c1,d);}}
 static void Wing(Graphics g,int side,Color col){var s=g.Save();g.TranslateTransform(512,298);g.ScaleTransform(side,1);
  for(int i=0;i<5;i++){float x=27+i*15,y=-10-i*7;Poly(g,A(col,235),P(14,-3),P(x+22,y-29-i*4),P(x+19,y-4),P(38+i*11,8));}
  Line(g,A(col,245),5,P(10,0),P(52,-17),P(108,-60));g.Restore(s);
 }
 static void Eye(Graphics g,float x,float y,float scale,Color col,bool slit){var s=g.Save();g.TranslateTransform(x,y);g.ScaleTransform(scale,scale);
  using(var path=new GraphicsPath()){path.AddBezier(-52,0,-23,-26,23,-26,52,0);path.AddBezier(52,0,23,23,-23,23,-52,0);path.CloseFigure();using(var b=new SolidBrush(Color.FromArgb(255,21,20,31)))g.FillPath(b,path);using(var pen=new Pen(col,5))g.DrawPath(pen,path);}
  Disc(g,0,0,15,col);if(slit)Poly(g,Color.FromArgb(255,17,17,22),P(0,-17),P(4,0),P(0,17),P(-4,0));else Disc(g,0,0,7,Color.FromArgb(255,255,244,205));g.Restore(s);
 }
 static void Dagger(Graphics g,float x,float y,int side,Color col){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(side*13);
  Poly(g,Color.FromArgb(255,30,34,39),P(-15,-27),P(0,-90),P(15,-27),P(10,38),P(-10,38));
  Poly(g,Color.FromArgb(255,168,179,180),P(-10,-25),P(0,-80),P(10,-25),P(6,34),P(-6,34));
  Line(g,col,4,P(-6,-24),P(-4,32));Line(g,Color.FromArgb(255,155,134,94),6,P(-26,37),P(26,37));Line(g,Color.FromArgb(255,59,39,36),12,P(0,44),P(0,76));Disc(g,0,82,8,col);g.Restore(s);
 }
 static void Crystal(Graphics g,float x,float y,float scale,Color col){Poly(g,Color.FromArgb(255,38,84,113),P(x-14*scale,y+18*scale),P(x-12*scale,y-10*scale),P(x+2*scale,y-43*scale),P(x+19*scale,y-6*scale),P(x+12*scale,y+18*scale));Poly(g,col,P(x-12*scale,y-10*scale),P(x+2*scale,y-43*scale),P(x+3*scale,y+12*scale));Line(g,A(col,240),3,P(x+2*scale,y-43*scale),P(x+19*scale,y-6*scale));}
 static void Flame(Graphics g,float x,float y,float scale,Color col){using(var p=new GraphicsPath()){p.AddBezier(x-18*scale,y,x-35*scale,y-19*scale,x+5*scale,y-33*scale,x-3*scale,y-64*scale);p.AddBezier(x-3*scale,y-64*scale,x+40*scale,y-25*scale,x+29*scale,y+9*scale,x-18*scale,y);p.CloseFigure();using(var b=new SolidBrush(col))g.FillPath(b,p);}Poly(g,Color.FromArgb(255,255,224,126),P(x-5*scale,y),P(x+5*scale,y-30*scale),P(x+13*scale,y));}
 static void Leaf(Graphics g,float x,float y,float angle,Color col){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);using(var p=new GraphicsPath()){p.AddBezier(0,0,-27,-7,-17,-36,0,-54);p.AddBezier(0,-54,27,-28,22,-5,0,0);using(var b=new SolidBrush(col))g.FillPath(b,p);}Line(g,Color.FromArgb(180,196,221,136),2,P(0,0),P(0,-40));g.Restore(s);}
 static void Antler(Graphics g,int side,Color col){var s=g.Save();g.TranslateTransform(512,302);g.ScaleTransform(side,1);
  Line(g,Color.FromArgb(255,67,44,29),13,P(54,0),P(82,-22),P(94,-59),P(91,-104));
  Line(g,col,6,P(54,0),P(82,-22),P(94,-59),P(91,-104));
  Line(g,col,6,P(85,-31),P(111,-40),P(122,-65));Line(g,col,6,P(94,-58),P(69,-76),P(66,-95));g.Restore(s);
 }
 static void Spiral(Graphics g,float x,float y,float r,Color col){PointF[] p=new PointF[65];for(int i=0;i<65;i++){double a=i/64.0*Math.PI*4;float rr=r*(1-i/70f);p[i]=P(x+(float)Math.Cos(a)*rr,y+(float)Math.Sin(a)*rr);}Line(g,col,5,p);}
 static void Horns(Graphics g,Color col){for(int side=-1;side<=1;side+=2){var s=g.Save();g.TranslateTransform(512,292);g.ScaleTransform(side,1);Poly(g,Color.FromArgb(255,31,24,35),P(19,5),P(36,-28),P(60,-31),P(80,-70),P(82,-29),P(63,-7),P(36,14));Line(g,col,4,P(20,4),P(39,-21),P(62,-25),P(80,-66));g.Restore(s);}Eye(g,493,288,.25f,col,false);Eye(g,532,288,.25f,col,false);}
 static void Shield(Graphics g,float x,float y,Color col){Poly(g,Color.FromArgb(255,52,43,32),P(x-40,y-39),P(x,y-48),P(x+40,y-39),P(x+34,y+13),P(x,y+49),P(x-34,y+13));Line(g,col,6,P(x-40,y-39),P(x,y-48),P(x+40,y-39),P(x+34,y+13),P(x,y+49),P(x-34,y+13),P(x-40,y-39));Line(g,A(col,210),4,P(x,y-29),P(x,y+30));}
 static void Bolt(Graphics g,float x,float y,int side,Color col){Line(g,A(col,75),13,P(x,y),P(x+side*26,y-31),P(x+side*4,y-38),P(x+side*34,y-75));Line(g,col,4,P(x,y),P(x+side*26,y-31),P(x+side*4,y-38),P(x+side*34,y-75));}
 static void Soul(Graphics g,float x,float y,Color col){using(var p=new GraphicsPath()){p.AddBezier(x-17,y+10,x-29,y-41,x+27,y-41,x+17,y+10);p.AddBezier(x+17,y+10,x+4,y+29,x-5,y+25,x-4,y+48);p.AddBezier(x-4,y+48,x-20,y+23,x-17,y+23,x-17,y+10);using(var b=new SolidBrush(A(col,235)))g.FillPath(b,p);}Disc(g,x-7,y-7,4,Color.FromArgb(255,29,15,43));Disc(g,x+7,y-7,4,Color.FromArgb(255,29,15,43));using(var b=new SolidBrush(Color.FromArgb(255,37,17,49)))g.FillEllipse(b,x-6,y+3,12,17);}
 static void Dice(Graphics g,float x,float y,Color col){Poly(g,Color.FromArgb(255,211,205,187),P(x-24,y-23),P(x+21,y-28),P(x+27,y+20),P(x-19,y+26));Line(g,col,3,P(x-24,y-23),P(x+21,y-28),P(x+27,y+20),P(x-19,y+26),P(x-24,y-23));for(int i=0;i<5;i++)Disc(g,x+(i==4?0:(i%2==0?-12:12)),y+(i==4?0:(i<2?-12:12)),4,Color.FromArgb(255,41,40,43));}
 static void MagicEdge(Graphics g,string motif,Color col,Color accent){
  if(motif!="souls"&&motif!="titan"&&motif!="hellfire"&&motif!="storm-lava"&&motif!="totem"&&motif!="water"&&motif!="venom"&&motif!="trickster"&&motif!="deathstalker"&&motif!="archon"&&motif!="mindblast"&&motif!="oracle")return;
  PointF[] edge=new PointF[2049];float[] distance=new float[2049];
  for(int k=0;k<=2048;k++){
   double a=k*Math.PI*2/2048,c=Math.Cos(a),s=Math.Sin(a);
   edge[k]=P(512+203*(float)(Math.Sign(c)*Math.Pow(Math.Abs(c),.6)),512+203*(float)(Math.Sign(s)*Math.Pow(Math.Abs(s),.6)));
   if(k>0){float dx=edge[k].X-edge[k-1].X,dy=edge[k].Y-edge[k-1].Y;distance[k]=distance[k-1]+(float)Math.Sqrt(dx*dx+dy*dy);}
  }
  if(motif=="water"){
   PointF[] wave=new PointF[192],foam=new PointF[192];int at=1;
   for(int k=0;k<192;k++){
    float along=distance[2048]*k/192;while(at<2048&&distance[at]<along)at++;
    float mix=(along-distance[at-1])/(distance[at]-distance[at-1]);
    float px=edge[at-1].X+(edge[at].X-edge[at-1].X)*mix,py=edge[at-1].Y+(edge[at].Y-edge[at-1].Y)*mix;
    double direction=Math.Atan2(py-512,px-512),crest=Math.Sin(k*Math.PI*2*12/192)*11;
    wave[k]=P(px+(float)(Math.Cos(direction)*crest),py+(float)(Math.Sin(direction)*crest));
    foam[k]=P(px+(float)(Math.Cos(direction)*(crest+11)),py+(float)(Math.Sin(direction)*(crest+11)));
   }
   using(var p=new GraphicsPath()){p.AddClosedCurve(wave,.45f);using(var pen=new Pen(A(C("#197BA9"),230),30))g.DrawPath(pen,p);using(var pen=new Pen(A(C("#53D8E8"),245),20))g.DrawPath(pen,p);}
   using(var p=new GraphicsPath()){p.AddClosedCurve(foam,.45f);using(var pen=new Pen(A(C("#B3FFFF"),230),4))g.DrawPath(pen,p);}
  }
  int cursor=1;
  for(int i=0;i<96;i++){
   float along=distance[2048]*i/96;while(cursor<2048&&distance[cursor]<along)cursor++;
   float blend=(along-distance[cursor-1])/(distance[cursor]-distance[cursor-1]);
   float x=edge[cursor-1].X+(edge[cursor].X-edge[cursor-1].X)*blend,y=edge[cursor-1].Y+(edge[cursor].Y-edge[cursor-1].Y)*blend;
   double theta=Math.Atan2(y-512,x-512),cs=Math.Cos(theta),sn=Math.Sin(theta);
   x+=(float)(cs*Math.Sin(i*2.1)*3);y+=(float)(sn*Math.Sin(i*2.1)*3);
   float angle=(float)(Math.Atan2(y-512,x-512)*180/Math.PI+90);
   if(motif=="oracle"){
    Mist(g,x,y,51,36,A(C("#EDCD6D"),190));Mist(g,x-3,y-3,35,25,A(C("#FFF2BC"),205));
    if(i%4==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);Curve(g,A(C("#FFF9DC"),230),3,P(-19,1),P(-7,-7),P(7,7),P(19,-1));g.Restore(s);}
    if(i%12==0){Line(g,C("#FFFFFF"),3,P(x-7,y),P(x+7,y));Line(g,C("#FFFFFF"),3,P(x,y-7),P(x,y+7));}
   }else if(motif=="archon"){
    bool light=x<512;Color energy=light?C("#FFE6A0"):C("#A76CDD"),shade=light?C("#C5933D"):C("#362044");
    Mist(g,x,y,57,43,A(shade,235));Mist(g,x-4,y-4,39,29,A(energy,220));
    if(i%3==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);Curve(g,A(energy,245),5,P(-18,0),P(-7,-14),P(6,13),P(20,-2));if(light)Line(g,C("#FFF5D3"),3,P(0,-10),P(0,9));g.Restore(s);}
   }else if(motif=="mindblast"){
    Mist(g,x,y,70,54,A(C("#23142F"),245));Mist(g,x-8,y-5,49,38,A(C("#764598"),205));Mist(g,x+10,y+5,43,30,A(C("#110D1D"),230));
    if(i%2==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);Curve(g,A(C("#AD6BD8"),230),5,P(-22,2),P(-4,-22),P(3,17),P(23,-5));Curve(g,A(C("#513179"),245),9,P(-19,-3),P(-4,13),P(6,-17),P(19,4));g.Restore(s);}
   }else if(motif=="venom"){
    Disc(g,x,y,23,A(C("#203510"),230));Disc(g,x,y,18,A(C("#65B52B"),245));Mist(g,x-4,y-5,26,22,A(C("#C6F157"),230));
    if(i%5==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);Line(g,C("#8FE235"),8,P(-6,0),P(-4,-18),P(3,-25));Disc(g,3,-26,7,C("#B4EF49"));g.Restore(s);}
   }else if(motif=="trickster"||motif=="deathstalker"){
    Mist(g,x,y,70,55,A(C(motif=="trickster"?"#3E3B3E":"#332C40"),235));
    Mist(g,x-10,y-6,48,40,A(C(motif=="trickster"?"#716366":"#685A7C"),175));
    Mist(g,x+9,y+5,45,37,A(C("#15131B"),240));
    if(motif=="trickster"&&i%2==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);Curve(g,C("#75121D"),10,P(-20,3),P(-6,-13),P(4,14),P(22,-1));Curve(g,C("#C52F3A"),4,P(-20,3),P(-6,-13),P(4,14),P(22,-1));if(i%8==0){Disc(g,2,-21,8,C("#9C1725"));Disc(g,-8,-12,4,C("#D1444C"));}g.Restore(s);}
   }else if(motif=="storm-lava"){
    {var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
     Mist(g,0,0,45,25,A(C("#98A6B2"),210));Mist(g,-9,-3,30,19,A(C("#D0D8DE"),175));Mist(g,9,2,29,18,A(C("#BAC6CE"),180));g.Restore(s);}
    if(i%6==0){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
     PointF[] bolt={P(-30,4),P(-17,-7),P(-21,-7),P(-6,3),P(3,-9),P(-1,-3),P(14,2),P(29,-10)};
     Lightning(g,A(C("#248DE8"),150),13,bolt);Lightning(g,C("#55CEFF"),7,bolt);Lightning(g,C("#FFFFFF"),4,bolt);
     Lightning(g,C("#ECFFFF"),3.5f,P(-6,3),P(-2,11),P(-9,15));Lightning(g,C("#ECFFFF"),3.5f,P(14,2),P(19,-8),P(25,-7));g.Restore(s);}
   }else if(motif=="water"){
    if(i%6==0){float bx=x+(float)cs*16,by=y+(float)sn*16;Disc(g,bx,by,15,A(col,170));Ring(g,bx,by,15,A(accent,240),3);Disc(g,bx-4,by-5,4,C("#E3FFFF"));}
    if(i%3==0)Disc(g,x+(float)cs*4,y+(float)sn*4,3,A(C("#DEFFFF"),220));
   }else if(motif=="totem"){
    int element=(i/24)%4;var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
    if(element==0){Curve(g,C("#C7F4EC"),7,P(-15,3),P(-4,-17),P(10,15),P(20,-7));Curve(g,C("#66B9CF"),4,P(-16,-6),P(-5,-25),P(6,3),P(16,-12));}
    else if(element==1){Flame(g,0,0,.72f,C("#EF7029"));Flame(g,2,-2,.35f,C("#FFE183"));}
    else if(element==2){Poly(g,C("#805E38"),P(-18,7),P(-20,-8),P(-5,-20),P(15,-14),P(21,9));Line(g,C("#CDB580"),5,P(-17,-7),P(-5,-16),P(12,-11));Disc(g,1,0,5,C("#81B36C"));}
    else{Disc(g,0,0,19,A(C("#278DCA"),225));Ring(g,0,0,17,C("#98F1F6"),4);Disc(g,-5,-6,4,C("#D7FFFF"));}
    g.Restore(s);
   }else if(motif=="souls"){
    Disc(g,x,y,23,C("#211128"));Ring(g,x,y,19,A(accent,250),5);Disc(g,x,y,11,A(col,255));Disc(g,x-3,y-3,5,A(accent,245));
    float ox=(float)cs*19,oy=(float)sn*19;
    Disc(g,x+ox,y+oy,5,A(accent,235));
   }else if(motif=="titan"){
    var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
    Curve(g,A(accent,245),10,P(-22,0),P(-5,-25),P(9,24),P(24,-5));
    Curve(g,A(col,255),7,P(-22,-8),P(-5,17),P(9,-25),P(24,5));
    Line(g,A(accent,250),5,P(-5,8),P(0,-11),P(8,3));g.Restore(s);
   }else{
    var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
    Flame(g,0,0,.85f+(i%3)*.10f,A(col,255));Flame(g,2,-2,.46f,A(accent,250));g.Restore(s);
   }
  }
 }
 static void Motif(Graphics g,string motif,Color col,Color accent){
  if(motif=="storm-lava"||motif=="water"){}
  else if(motif=="totem"){
   foreach(float x in new float[]{286,738}){
    Poly(g,C("#38281D"),P(x-24,430),P(x+24,430),P(x+29,549),P(x,567),P(x-29,549));
    Line(g,C("#C59657"),6,P(x-22,436),P(x-25,546),P(x,560),P(x+25,546),P(x+22,436));
    Poly(g,C("#A47B48"),P(x-42,454),P(x-18,442),P(x,459),P(x+18,442),P(x+42,454),P(x+24,472),P(x,465),P(x-24,472));
    Eye(g,x,481,.36f,C("#A8F3EB"),false);
    Line(g,C("#EF923A"),5,P(x-10,505),P(x,494),P(x+10,505));
    Line(g,C("#8BD1EA"),5,P(x-12,523),P(x,516),P(x+12,523));
    Disc(g,x,542,7,C("#A9C47B"));
   }
  }
  else if(motif=="archon"){var s=g.Save();g.TranslateTransform(512,284);g.ScaleTransform(1.65f,1.65f);g.TranslateTransform(-512,-298);Wing(g,-1,C("#FFE6A0"));Wing(g,1,C("#B880E7"));g.Restore(s);}
  else if(motif=="sun-wings"){
   // Radiant: sunlight surrounds the square talent face on every side.
   for(int i=0;i<40;i++){
    double angle=(i+.5)*Math.PI*2/40;float dx=(float)Math.Cos(angle),dy=(float)Math.Sin(angle);
    float radius=211/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*radius,y=512+dy*radius,length=23+(i%4)*10;
    Mist(g,x+dx*12,y+dy*12,61,61,A(col,105));
    Poly(g,A(col,200),P(x-dy*8,y+dx*8),P(x+dx*length,y+dy*length),P(x+dy*8,y-dx*8));
    Line(g,A(accent,225),3,P(x,y),P(x+dx*(length-6),y+dy*(length-6)));
   }
  }
  else if(motif=="phoenix"){
   // Fireball: an asymmetric curl of flame hugs the talent's square face.
   using(var curl=new GraphicsPath()){
    curl.AddBezier(653,298,494,206,260,236,285,427);
    curl.AddBezier(285,427,265,536,291,705,391,725);
    curl.AddBezier(391,725,489,768,643,703,735,767);
    curl.AddBezier(735,767,776,655,741,470,738,369);
    curl.AddBezier(738,369,732,310,693,282,653,298);
    curl.CloseFigure();
    foreach(int width in new int[]{83,59,35})using(var pen=new Pen(A(C("#E65C24"),width==83?22:width==59?60:190),width)){pen.StartCap=pen.EndCap=LineCap.Round;g.DrawPath(pen,curl);}
    using(var pen=new Pen(A(C("#FFC15E"),225),10))g.DrawPath(pen,curl);
   }
   for(int i=0;i<7;i++){
    var flame=g.Save();g.TranslateTransform(291+i*7,353+i*48);g.RotateTransform(-41-i*5);
    Flame(g,0,0,.62f+(i%3)*.14f,C("#EE792A"));g.Restore(flame);
   }
   for(int i=0;i<5;i++){
    var flame=g.Save();g.TranslateTransform(420+i*66,730+(i%2)*8);g.RotateTransform(102);
    Flame(g,0,0,.62f,C("#EF822C"));g.Restore(flame);
   }
   for(int i=0;i<6;i++){
    var flame=g.Save();g.TranslateTransform(743,377+i*53);g.RotateTransform(55);
    Flame(g,0,0,.7f,C("#EF822C"));g.Restore(flame);
   }
   for(int i=0;i<9;i++){float x=271+(i*67)%467,y=i%2==0?266-i%3*13:755+i%3*12;Mist(g,x,y,29,34,A(col,100));Disc(g,x,y,3,accent);}
  }
  else if(motif=="light-armor"){
   // One full-size bulwark surrounds the talent, with a transparent face.
   using(var shield=new GraphicsPath()){
    shield.AddLines(new PointF[]{P(270,291),P(512,252),P(754,291),P(750,619)});
    shield.AddBezier(750,619,744,724,617,819,512,866);
    shield.AddBezier(512,866,407,819,280,724,274,619);
    shield.CloseFigure();
    foreach(int width in new int[]{78,56,34,18})using(var pen=new Pen(A(col,width==78?18:width==56?32:width==34?65:155),width))g.DrawPath(pen,shield);
    using(var pen=new Pen(A(accent,250),7))g.DrawPath(pen,shield);
   }
  }
  else if(motif=="silver-hand"){
   // Crusader Aura: four warm rays joined by a soft band of holy fire.
   using(var link=new GraphicsPath()){
    link.AddArc(263,263,150,150,180,90);link.AddArc(611,263,150,150,270,90);
    link.AddArc(611,611,150,150,0,90);link.AddArc(263,611,150,150,90,90);link.CloseFigure();
    foreach(int width in new int[]{86,62,40,22})using(var pen=new Pen(A(col,width==86?10:width==62?18:width==40?35:75),width))g.DrawPath(pen,link);
    using(var pen=new Pen(A(accent,150),4))g.DrawPath(pen,link);
   }
   for(int side=0;side<4;side++){
    var aura=g.Save();g.TranslateTransform(512,512);g.RotateTransform(side*90);
    Mist(g,0,-249,137,164,A(col,120));
    Poly(g,A(col,110),P(-31,-205),P(-23,-256),P(0,-313),P(23,-256),P(31,-205));
    Poly(g,A(accent,155),P(-12,-207),P(-9,-254),P(0,-299),P(9,-254),P(12,-207));
    Line(g,A(accent,200),4,P(0,-212),P(0,-283));
    g.Restore(aura);
   }
  }
  else if(motif=="cat-vfx-fangs"){
   for(int side=-1;side<=1;side+=2){
    var corner=g.Save();g.TranslateTransform(512,512);g.ScaleTransform(side,1);
    using(var fang=new GraphicsPath()){
     fang.AddBezier(171,-204,225,-218,240,-155,183,-66);
     fang.AddBezier(183,-66,196,-134,178,-170,171,-204);fang.CloseFigure();
     using(var fill=new SolidBrush(C("#E9DFC4")))g.FillPath(fill,fang);
     using(var pen=new Pen(C("#6F6851"),4))g.DrawPath(pen,fang);
    }
    Curve(g,C("#FFF5D9"),4,P(181,-197),P(210,-187),P(215,-153),P(194,-109));
    Curve(g,C("#941A28"),11,P(208,-157),P(215,-129),P(191,-92),P(184,-70));
    Line(g,C("#9F202C"),4,P(187,-81),P(182,-44));Disc(g,182,-40,5,C("#C3333B"));
    g.Restore(corner);
   }
  }
  else if(motif=="watchful-feathers"){
   // Enlarge the original sketch silhouette without adding separate bows.
   for(int end=0;end<2;end++){
    var feather=g.Save();g.TranslateTransform(512,512);g.RotateTransform(end*180);
    g.TranslateTransform(0,-259);g.ScaleTransform(1.65f,1.65f);g.TranslateTransform(0,250);
    using(var plume=new GraphicsPath()){
     plume.AddBezier(-67,-294,-74,-235,10,-251,53,-209);
     plume.AddBezier(53,-209,28,-278,-32,-255,-67,-294);plume.CloseFigure();
     using(var b=new SolidBrush(C("#49BDB0")))g.FillPath(b,plume);
     using(var pen=new Pen(C("#194A50"),5))g.DrawPath(pen,plume);
    }
    Curve(g,C("#C5FFF0"),7,P(-62,-286),P(-44,-250),P(10,-249),P(49,-214));
    Line(g,A(accent,200),2,P(-29,-260),P(-30,-247));
    Line(g,A(accent,200),2,P(-5,-251),P(-4,-238));
    Line(g,C("#344D49"),4,P(43,-220),P(68,-200));
    g.Restore(feather);
   }
   for(int side=-1;side<=1;side+=2){
    float x=512+side*165,y=235;
    bool feline=side>0;Color iris=feline?C("#7BC68B"):C("#E5A548");
    Mist(g,x,y,155,73,A(C("#182B2C"),200));
    for(int eyeSide=-1;eyeSide<=1;eyeSide+=2){
     var gaze=g.Save();g.TranslateTransform(x+eyeSide*36,y);g.RotateTransform(-eyeSide*(feline?12:6));
     using(var lid=new GraphicsPath()){
      lid.AddBezier(-31,0,-15,-22,15,-22,31,0);
      lid.AddBezier(31,0,13,17,-13,17,-31,0);lid.CloseFigure();
      using(var b=new SolidBrush(C("#D3D0AE")))g.FillPath(b,lid);
      var irisClip=g.Save();g.SetClip(lid);
      Disc(g,0,-1,17,iris);Ring(g,0,-1,17,C("#4E593C"),3);
      for(int ray=0;ray<12;ray++){
       double a=ray*Math.PI*2/12;float dx=(float)Math.Cos(a),dy=(float)Math.Sin(a);
       Line(g,A(feline?C("#C1ED8E"):C("#FFE29A"),170),2,P(dx*9,-1+dy*9),P(dx*14,-1+dy*14));
      }
      if(feline)Poly(g,C("#101719"),P(0,-17),P(5,-1),P(0,16),P(-5,-1));
      else Disc(g,0,-1,8,C("#101719"));
      Disc(g,-5,-7,4,C("#FFF8E0"));Disc(g,5,5,2,A(C("#FFFFFF"),190));
      g.Restore(irisClip);
      using(var pen=new Pen(C("#172321"),5))g.DrawPath(pen,lid);
     }
     Curve(g,feline?C("#365C4E"):C("#77654A"),5,P(-31,-5),P(-14,-24),P(12,-23),P(32,-3));
     g.Restore(gaze);
    }
   }
  }
  else if(motif=="pack"){
   // Jungle foliage hugs the square; watchful eyes peek through the canopy.
   for(int i=0;i<52;i++){
    double angle=i*Math.PI*2/52;float dx=(float)Math.Cos(angle),dy=(float)Math.Sin(angle);
    float radius=211/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*radius,y=512+dy*radius;
    Mist(g,x,y,54,49,A(col,140));
    Leaf(g,x,y,(float)(angle*180/Math.PI)+90+(i%2==0?32:-28),i%3==0?accent:col);
   }
   Curve(g,A(accent,210),5,P(304,355),P(258,456),P(340,595),P(296,681));
   Curve(g,A(col,230),7,P(716,332),P(772,449),P(675,624),P(728,692));
   foreach(PointF perch in new PointF[]{P(382,286),P(291,421),P(717,585)}){
    Mist(g,perch.X,perch.Y,81,34,A(C("#102F35"),130));
    Eye(g,perch.X-17,perch.Y,.22f,A(C("#88BDA8"),165),true);
    Eye(g,perch.X+17,perch.Y,.22f,A(C("#88BDA8"),165),true);
   }
   // Blood spatters cover the foliage around the entire jungle rim.
   for(int stain=0;stain<76;stain++){
    double a=stain*Math.PI*2/76;float dx=(float)Math.Cos(a),dy=(float)Math.Sin(a);
    float r=(208+(stain%3-1)*15)/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*r,y=512+dy*r;
    Disc(g,x,y,5+stain%5*2,A(C(stain%3==0?"#B52B35":"#751421"),220));
    Disc(g,x+11,y-8,2+stain%3,C("#A42530"));
    if(stain%6==0){Line(g,C("#8E1B28"),4,P(x,y),P(x+2,y+18));Disc(g,x+2,y+20,4,C("#B52B35"));}
   }
   for(int side=-1;side<=1;side+=2){
    var fangState=g.Save();g.TranslateTransform(512,512);g.ScaleTransform(side,1);
    using(var fang=new GraphicsPath()){
     fang.AddBezier(220,-79,289,-76,281,41,228,124);
     fang.AddBezier(228,124,246,34,221,-9,220,-79);fang.CloseFigure();
     using(var fill=new SolidBrush(C("#E9DFC4")))g.FillPath(fill,fang);
     using(var outline=new Pen(C("#6F6851"),5))g.DrawPath(outline,fang);
    }
    Curve(g,C("#FFF5D9"),5,P(229,-65),P(261,-43),P(259,24),P(238,80));
    Curve(g,C("#851725"),15,P(246,-28),P(269,14),P(244,73),P(231,111));
    Curve(g,C("#B92D36"),6,P(249,-7),P(259,29),P(240,75),P(233,99));
    Disc(g,241,-45,8,C("#A42430"));Disc(g,252,-30,5,C("#8D1B27"));
    Line(g,C("#911A27"),4,P(234,97),P(229,136));Disc(g,229,140,5,C("#B52B35"));
    g.Restore(fangState);
   }
  }
  else if(motif=="bullseye"){
   // Mark: a circular reticle surrounds the square talent face.
   foreach(int width in new int[]{38,24,13})Ring(g,512,512,295,A(col,width==38?22:width==24?50:210),width);
   Ring(g,512,512,295,A(accent,220),3);
   for(int side=0;side<4;side++){
    var mark=g.Save();g.TranslateTransform(512,512);g.RotateTransform(side*90);
    Line(g,A(col,80),20,P(0,-273),P(0,-331));
    Line(g,col,10,P(0,-273),P(0,-331));
    Line(g,A(accent,220),3,P(-2,-279),P(-2,-326));
    g.Restore(mark);
   }
  }
  else if(motif=="traps"){
   // Open steel jaws cradle the talent, with a fire trap burning above it.
   Color steel=C("#969B96"),edge=C("#D8D8C4"),shadow=C("#424B49");
   using(var jaw=new GraphicsPath()){
    jaw.AddBezier(260,578,213,658,225,755,512,791);
    jaw.AddBezier(512,791,799,755,811,658,764,578);
    using(var pen=new Pen(shadow,31))g.DrawPath(pen,jaw);
    using(var pen=new Pen(steel,19))g.DrawPath(pen,jaw);
    using(var pen=new Pen(edge,4))g.DrawPath(pen,jaw);
   }
   for(int side=-1;side<=1;side+=2){
    float x=512+side*244;
    Poly(g,shadow,P(x-side*21,687),P(x+side*29,647),P(x+side*14,533));
    Line(g,edge,5,P(x-side*21,687),P(x+side*14,544),P(x+side*29,647));
    Disc(g,x,696,17,shadow);Disc(g,x,696,9,steel);
   }
   for(int i=0;i<7;i++){
    float x=329+i*61,y=766-(float)Math.Pow((x-512)/183,2)*30;
    Poly(g,steel,P(x-17,y),P(x+17,y),P(x,y-44));
    Line(g,edge,3,P(x-15,y),P(x,y-42));
   }
   Mist(g,512,222,193,215,A(C("#EB822C"),125));
   Flame(g,512,300,2.5f,C("#DD6928"));
  }
  else if(motif=="eclipse"){
   // Keep the eclipse crest visible above the talent in border-only mode.
   Mist(g,512,253,158,158,A(accent,130));
   for(int ray=0;ray<12;ray++){
    double angle=ray*Math.PI*2/12;float dx=(float)Math.Cos(angle),dy=(float)Math.Sin(angle);
    Line(g,A(accent,210),4,P(512+dx*51,253+dy*51),P(512+dx*63,253+dy*63));
   }
   Disc(g,512,253,48,accent);
   Disc(g,503,249,40,C("#26344E"));
   Ring(g,512,253,48,C("#E4E8E9"),3);
   Curve(g,col,4,P(487,221),P(466,249),P(483,277),P(500,282));
   for(int i=0;i<96;i++){
    double a=(i+.5)*Math.PI*2/96;float dx=(float)Math.Cos(a),dy=(float)Math.Sin(a),r=205/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*r,y=512+dy*r;bool moon=x<512;Color light=moon?col:accent;
    Mist(g,x,y,65,65,A(light,140));
    if(i%4==0){
     if(moon){Ring(g,x,y,6,A(C("#EDF7FF"),210),2);Disc(g,x+3,y-2,5,C("#789DC5"));}
     else{Line(g,A(C("#FFF0B9"),230),3,P(x,y),P(x+dx*20,y+dy*20));}
    }
   }
  }
  else if(motif=="wild-eye"){Eye(g,512,284,.9f,accent,true);for(int side=-1;side<=1;side+=2)for(int i=0;i<3;i++)Leaf(g,512+side*(69+i*18),311-i*6,side*(36+i*24),col);}
  else if(motif=="fangs"){
   // A broad enraged glow surrounds a blood-soaked rim.
   using(var rage=new GraphicsPath()){
    rage.AddArc(309,309,100,100,180,90);rage.AddArc(615,309,100,100,270,90);
    rage.AddArc(615,615,100,100,0,90);rage.AddArc(309,615,100,100,90,90);rage.CloseFigure();
    foreach(int width in new int[]{114,84,58,34})using(var pen=new Pen(A(col,width==114?15:width==84?30:width==58?55:100),width))g.DrawPath(pen,rage);
    using(var pen=new Pen(C("#80101D"),28))g.DrawPath(pen,rage);
    using(var pen=new Pen(A(C("#DE3C38"),220),5))g.DrawPath(pen,rage);
   }
   for(int i=0;i<88;i++){
    double a=i*Math.PI*2/88;float dx=(float)Math.Cos(a),dy=(float)Math.Sin(a),r=205/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*r,y=512+dy*r;
    Disc(g,x,y,11+i%4,C(i%3==0?"#B7222C":"#700C19"));
    if(i%5==0){
     Curve(g,A(C("#F04B3D"),190),3,P(x-8,y-4),P(x-3,y-9),P(x+3,y+3),P(x+7,y-3));
     float drip=14+i%4*7;
     Line(g,C("#8F1420"),5,P(x,y+6),P(x+2,y+drip));Disc(g,x+2,y+drip+2,5,C("#B7222C"));
    }
   }
   for(int side=-1;side<=1;side+=2){
    var claws=g.Save();g.TranslateTransform(512,512);g.ScaleTransform(side,1);
    for(int claw=0;claw<3;claw++){
     float x=234+claw*29,y=-94+claw*69;
     using(var talon=new GraphicsPath()){
      talon.AddBezier(x,y,x+44,y+35,x+36,y+103,x-18,y+151);
      talon.AddBezier(x-18,y+151,x+3,y+91,x+9,y+49,x,y);talon.CloseFigure();
      using(var b=new SolidBrush(C("#E4D6B6")))g.FillPath(b,talon);
      using(var pen=new Pen(C("#70503A"),4))g.DrawPath(pen,talon);
     }
     Curve(g,C("#9F2028"),9,P(x+10,y+56),P(x+29,y+78),P(x+6,y+113),P(x-13,y+142));
     Line(g,C("#D34439"),3,P(x+12,y+75),P(x+3,y+114));
     Line(g,C("#A11F26"),4,P(x+3,y+116),P(x+2,y+159));Disc(g,x+2,y+162,5,C("#B62B2F"));
    }g.Restore(claws);
   }
  }
  else if(motif=="grove"){
   for(int i=0;i<64;i++){
    double a=i*Math.PI*2/64;float dx=(float)Math.Cos(a),dy=(float)Math.Sin(a),r=207/Math.Max(Math.Abs(dx),Math.Abs(dy));
    float x=512+dx*r,y=512+dy*r;
    Mist(g,x,y,75,65,A(C("#55DB69"),135));
    Leaf(g,x,y,(float)(a*180/Math.PI)+90+(i%2==0?30:-25),i%3==0?accent:col);
    if(i%4==0){Curve(g,A(C("#BBFFB0"),220),3,P(x-12,y+10),P(x+16,y-22),P(x-15,y-20),P(x+7,y-37));Disc(g,x+7,y-37,3,C("#E0FFD1"));}
   }
  }
  else if(motif=="runes"){
   // Arcane Flux: overlapping loops of violet energy orbit the talent.
   for(int orbit=0;orbit<3;orbit++){
    var flux=g.Save();g.TranslateTransform(512,512);g.RotateTransform(orbit*60+15);
    using(var loop=new GraphicsPath()){
     loop.AddEllipse(-321,-234,642,468);
     foreach(int width in new int[]{42,26,13})using(var pen=new Pen(A(col,width==42?13:width==26?30:85),width))g.DrawPath(pen,loop);
     using(var pen=new Pen(A(accent,185),4))g.DrawPath(pen,loop);
    }
    for(int side=-1;side<=1;side+=2){
     Mist(g,side*313,0,78,67,A(col,165));
     Disc(g,side*313,0,7,A(accent,225));
     Line(g,A(accent,210),3,P(side*313-13,0),P(side*313+13,0));
     Line(g,A(accent,210),3,P(side*313,-13),P(side*313,13));
    }
    g.Restore(flux);
   }
  }
  else if(motif=="icicles"){
   // Frostbite coats the complete rim with frozen facets and branching cracks.
   for(int edgeSide=0;edgeSide<4;edgeSide++){
    var frozenEdge=g.Save();g.TranslateTransform(512,512);g.RotateTransform(edgeSide*90);
    Line(g,A(col,200),30,P(-177,-203),P(177,-203));
    Line(g,A(accent,235),7,P(-177,-209),P(177,-209));
    for(int shard=0;shard<8;shard++){
     float x=-166+shard*47,length=24+(shard+edgeSide)%3*11;
     Mist(g,x,-204,67,58,A(col,115));
     Poly(g,C("#8ED9F0"),P(x-21,-215),P(x+18,-212),P(x+9,-184),P(x-8,-175));
     Poly(g,A(accent,235),P(x-17,-211),P(x+8,-215),P(x+3,-184));
     Poly(g,A(col,220),P(x-10,-215),P(x+10,-215),P(x+2,-215-length));
     Line(g,A(accent,250),3,P(x-12,-209),P(x-3,-196),P(x-12,-181));
     Line(g,A(accent,220),2,P(x-3,-196),P(x+11,-191));
    }
    g.Restore(frozenEdge);
   }
   for(int corner=0;corner<4;corner++){
    var frost=g.Save();g.TranslateTransform(512,512);g.RotateTransform(corner*90);
    Mist(g,-193,-190,135,150,A(col,210));
    Line(g,A(col,245),23,P(-203,-70),P(-207,-182),P(-193,-207),P(-80,-203));
    Line(g,A(accent,255),7,P(-201,-82),P(-204,-180),P(-190,-202),P(-92,-202));
    Crystal(g,-208,-179,.9f,C("#A3E9FF"));
    Poly(g,C("#CFF8FF"),P(-189,-207),P(-163,-205),P(-178,-140));
    Poly(g,C("#84D8F4"),P(-157,-204),P(-130,-204),P(-142,-162));
    Poly(g,A(col,190),P(-216,-184),P(-194,-202),P(-188,-162),P(-200,-111));
    Poly(g,A(accent,220),P(-203,-193),P(-193,-204),P(-196,-158));
    Poly(g,A(col,175),P(-182,-204),P(-156,-202),P(-169,-173));
    Line(g,A(accent,255),5,P(-195,-178),P(-167,-154),P(-180,-125));
    Line(g,A(accent,245),4,P(-185,-200),P(-171,-229),P(-150,-219));
    g.Restore(frost);
   }
  }
  else if(motif=="frostfire"){for(int i=0;i<4;i++){float x=333+i*42;Poly(g,C("#D0F5FF"),P(x-13,305),P(x+15,305),P(x+2,345+i%2*17));}Crystal(g,300,428,.85f,col);for(int i=0;i<3;i++)Flame(g,612+i*37,306,.6f,accent);Flame(g,723,428,.85f,accent);}
  else if(motif=="oracle"){Eye(g,512,280,1,Color.FromArgb(255,255,241,198),false);Ring(g,512,280,22,accent,3);for(int i=-2;i<=2;i++)Line(g,A(i%2==0?col:accent,190),4,P(512+i*12,256),P(512+i*22,228-Math.Abs(i)*5));}
  else if(motif=="mindblast"){Disc(g,512,279,36,C("#281B35"));Spiral(g,512,279,29,accent);for(int i=0;i<5;i++)Line(g,col,5,P(480+i*15,304),P(470+i*20,313));}
  else if(motif=="venom"||motif=="trickster"){
   for(int side=-1;side<=1;side+=2){var s=g.Save();g.TranslateTransform(512+side*226,495);g.ScaleTransform(1.65f,1.65f);
    Dagger(g,0,0,side,motif=="venom"?col:accent);g.RotateTransform(side*13);
    Color coating=C(motif=="venom"?"#84D72F":"#A51D29");
    Curve(g,coating,8,P(0,-64),P(-9,-43),P(10,-15),P(0,21));
    Line(g,C(motif=="venom"?"#D1FF6D":"#F25B61"),3,P(1,-61),P(-3,-35),P(3,-16));
    Line(g,coating,5,P(3,-16),P(7,5),P(6,22));Disc(g,6,24,5,coating);g.Restore(s);
   }
  }
  else if(motif=="deathstalker"){
   var s=g.Save();g.TranslateTransform(512,270);g.ScaleTransform(1.45f,1.45f);g.TranslateTransform(-512,-280);
   Mist(g,512,278,135,70,A(C("#625373"),170));
   Poly(g,C("#17121F"),P(463,302),P(479,264),P(512,241),P(545,264),P(561,302),P(533,293),P(512,281),P(491,293));
   Line(g,C("#746181"),4,P(465,300),P(481,265),P(512,245),P(543,265),P(559,300));
   Mist(g,494,284,28,20,A(C("#F32332"),190));Mist(g,531,284,28,20,A(C("#F32332"),190));
   Eye(g,494,284,.27f,C("#FF3442"),false);Eye(g,531,284,.27f,C("#FF3442"),false);g.Restore(s);
  }
  else if(motif=="souls"){
   foreach(float x in new float[]{302,722}){
    var soulState=g.Save();g.TranslateTransform(x,475);g.ScaleTransform(1.75f,1.75f);
    Soul(g,0,0,accent);g.Restore(soulState);
   }
  }
  else if(motif=="titan"){
   var skullState=g.Save();g.TranslateTransform(512,274);g.ScaleTransform(1.55f,1.55f);g.TranslateTransform(-512,-286);
   Poly(g,C("#171320"),P(485,270),P(512,258),P(539,270),P(543,301),P(529,311),P(526,326),P(498,326),P(495,311),P(481,301));
   Horns(g,col);Eye(g,498,289,.20f,col,false);Eye(g,527,289,.20f,col,false);
   Poly(g,accent,P(512,300),P(506,310),P(518,310));
   for(int i=0;i<4;i++)Line(g,A(col,230),3,P(501+i*7,315),P(501+i*7,325));
   g.Restore(skullState);
  }
 }
 public static void Write(string dir,int frame,string motif,string color,string highlight){Color col=C(color),accent=C(highlight);using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  bool split=motif=="frostfire"||motif=="eclipse"||motif=="archon";
  // Protection uses the full shield silhouette instead of the square rim.
  for(int yy=280;yy<745;yy++)for(int xx=280;xx<745;xx++){
   double qx=Math.Abs(xx-512)-153,qy=Math.Abs(yy-512)-153,ax=Math.Max(qx,0),ay=Math.Max(qy,0);
   double edge=Math.Sqrt(ax*ax+ay*ay)+Math.Min(Math.Max(qx,qy),0)-50,d=Math.Abs(edge);
   // Double the visible width of both elemental halves of Frostfire.
   if(motif=="frostfire")d/=2;
   int a=(int)Math.Min(248,210*Math.Exp(-d*d/35)+26*Math.Exp(-d*d/170));Color tint=split&&xx>512?accent:col;
   if(motif=="traps"){tint=C("#858C82");a=(int)(a*.65);}
   if(motif=="runes"||motif=="phoenix"||motif=="cat-vfx-fangs")a=0;
   if(motif=="watchful-feathers"){tint=C("#577B76");a=(int)(a*.42);}
   if(motif=="icicles"){tint=C("#A0C0CC");a=(int)(a*.36);}
   if(motif=="souls")tint=C("#25132F");else if(motif=="titan")tint=C("#1D2B16");else if(motif=="hellfire")tint=C("#481709");
   if(a>0&&motif!="bullseye"&&motif!="light-armor"&&motif!="souls"&&motif!="titan"&&motif!="hellfire"&&motif!="storm-lava"&&motif!="totem"&&motif!="water"&&motif!="venom"&&motif!="trickster"&&motif!="deathstalker"&&motif!="archon"&&motif!="mindblast"&&motif!="oracle")im.SetPixel(xx,yy,A(tint,a));
  }
  MagicEdge(g,motif,col,accent);
  bool paladin=motif=="sun-wings"||motif=="light-armor"||motif=="silver-hand";
  if(paladin&&motif!="light-armor"){
   Color glow=motif=="sun-wings"?C("#D96813"):motif=="light-armor"?C("#FFE9A1"):C("#EC7838");
   using(var rim=new GraphicsPath()){
    rim.AddArc(309,309,100,100,180,90);rim.AddArc(615,309,100,100,270,90);rim.AddArc(615,615,100,100,0,90);rim.AddArc(309,615,100,100,90,90);rim.CloseFigure();
    foreach(int width in new int[]{60,42,28,16})using(var pen=new Pen(A(glow,width==60?18:width==42?30:width==28?55:105),width))g.DrawPath(pen,rim);
    using(var pen=new Pen(A(accent,235),5))g.DrawPath(pen,rim);
   }
  }
  var motifState=g.Save();
  Motif(g,motif,col,accent);g.Restore(motifState);
  for(int y=652;y<804;y++)for(int x=605;x<809;x++){Color c=im.GetPixel(x,y);float dx=Math.Max(0,Math.Max(620-x,x-793)),dy=Math.Max(0,Math.Max(670-y,y-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/16);if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(dir,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
$manifest=[ordered]@{}
$fangDirectory=Join-Path $destination 'FeralFangs'
[IO.Directory]::CreateDirectory($fangDirectory)|Out-Null
[SpecBorderArt]::Write($fangDirectory,0,'cat-vfx-fangs','#287E7C','#80D4C5')
$frame=0
foreach($style in $styles){
 if($style.motif){
  [SpecBorderArt]::Write($destination,$frame,$style.motif,$style.color,$style.accent)
  $manifest[$style.kind]=[ordered]@{file='SimpleBorders';atlas='simple-borders';frame=$frame}
  $frame++
 }else{$manifest[$style.kind]=[ordered]@{file=$style.file;atlas=$style.atlas;frame=[int]$style.frame}}
}
$lua="-- Generated by tools/New-SpecSimpleBorders.ps1 from tools/talent-border-styles.json.`nForeverCoaching=ForeverCoaching or {}`nForeverCoaching.TalentSimpleBorders={`n"
foreach($entry in $manifest.GetEnumerator()){$lua+='    ["'+$entry.Key+'"]={file="'+$entry.Value.file+'",frame='+$entry.Value.frame+"},`n"}
$lua+="}`n"
[IO.File]::WriteAllText((Join-Path $PSScriptRoot '../addons/ForeverCoaching/Data/TalentBorderStyles.lua'),$lua)
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'talent-preview/border-styles.js'),('// Generated by tools/New-SpecSimpleBorders.ps1.'+"`nwindow.TalentBorderStyles="+($manifest|ConvertTo-Json -Depth 4 -Compress)+";`n"))
Write-Output "Generated $frame static borders and shared runtime manifests."
