param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Arms-Colossus-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ColossusArt {
 static float Ease(float p){p=Math.Max(0,Math.Min(1,p));return p*p*(3-2*p);}
 static PointF P(float x,float y){return new PointF(x,y);}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var b=new Pen(c,w)){b.LineJoin=LineJoin.Round;g.DrawLines(b,p);}}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new[]{Color.Transparent};g.FillPath(b,p);}}}
 static void Sword(Graphics g,float x,float y,float angle,float alpha){var s=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
  int a=(int)(255*alpha);
  // A broad, weighty slab of forged steel with a bright bevel and dark fuller.
  PointF[] blade={P(-72,-166),P(-79,-119),P(-61,193),P(0,277),P(61,193),P(79,-119),P(72,-166)};
  using(var path=new GraphicsPath()){path.AddPolygon(blade);using(var fill=new LinearGradientBrush(P(-79,0),P(79,0),Color.FromArgb(a,39,51,57),Color.FromArgb(a,192,216,211)))g.FillPath(fill,path);using(var edge=new Pen(Color.FromArgb(a,230,237,217),4))g.DrawPath(edge,path);}
  Poly(g,Color.FromArgb(a,27,39,43),P(-19,-157),P(-14,189),P(0,244),P(14,189),P(19,-157));
  Poly(g,Color.FromArgb(a,112,149,144),P(-7,-155),P(-3,181),P(0,219),P(5,181),P(8,-155));
  Line(g,Color.FromArgb(a,236,247,231),5,P(-62,-125),P(-46,185),P(-5,260));
  Line(g,Color.FromArgb(a,79,98,94),4,P(62,-125),P(46,185));
  for(int i=0;i<13;i++){float yy=-105+i*22;Line(g,Color.FromArgb((int)(alpha*105),222,231,213),1,P(-57,yy),P(-28,yy+12));}
  // Heavy bronze crossguard, green inlay, and a wrapped two-handed grip.
  Poly(g,Color.FromArgb(a,58,39,25),P(-24,-168),P(-108,-187),P(-145,-160),P(-111,-129),P(-84,-147),P(0,-132),P(84,-147),P(111,-129),P(145,-160),P(108,-187),P(24,-168));
  Line(g,Color.FromArgb(a,214,167,83),7,P(-135,-159),P(-105,-174),P(-69,-158),P(0,-148),P(69,-158),P(105,-174),P(135,-159));
  Poly(g,Color.FromArgb(a,161,111,49),P(0,-191),P(32,-162),P(0,-126),P(-32,-162));
  Poly(g,Color.FromArgb(a,35,111,97),P(0,-181),P(20,-162),P(0,-139),P(-20,-162));
  Line(g,Color.FromArgb(a,28,24,22),30,P(0,-276),P(0,-192));
  for(int i=0;i<8;i++)Line(g,Color.FromArgb(a,121,87,54),4,P(-13,-268+i*10),P(13,-260+i*10));
  Poly(g,Color.FromArgb(a,169,128,63),P(0,-312),P(22,-290),P(15,-270),P(-15,-270),P(-22,-290));
  g.Restore(s);
 }
 static PointF Tip(int slash,float u){return P(slash==0?309+406*u:715-406*u,309+406*u);}
 static PointF Grip(int slash,float u){double a=(slash==0?110-u*125:-110+u*125)*Math.PI/180;PointF tip=Tip(slash,u);return P(tip.X+(float)Math.Sin(a)*502*.8f,tip.Y-(float)Math.Cos(a)*502*.8f);}
 static void HeldSword(Graphics g,float hx,float hy,float angle,float scale,float alpha){var s=g.Save();g.TranslateTransform(hx,hy);g.RotateTransform(angle);g.ScaleTransform(scale,scale);g.TranslateTransform(0,225);Sword(g,0,0,0,alpha);g.Restore(s);}
 static void Fracture(Graphics g,int slash,float amount){if(amount<=0)return;var clip=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  int count=Math.Max(2,(int)(amount*40)+2);PointF[] crack=new PointF[count];for(int i=0;i<count;i++){float u=Math.Min(amount,i/40f);crack[i]=Tip(slash,u);}
  Line(g,Color.FromArgb(235,20,15,13),16,crack);Line(g,Color.FromArgb(210,161,106,53),4,crack);
  for(int i=4;i<count-1;i+=5){var p=crack[i];float side=i%2==0?-1:1;Line(g,Color.FromArgb(220,30,23,18),4,p,P(p.X+side*25,p.Y+22),P(p.X+side*38,p.Y+29));}
  g.Restore(clip);
 }
 public static void Write(string output){for(int f=0;f<108;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;float p=f/107f;
  // Animate from the grip: the blade leads each cut around a steady hand position.
  float handX=704,handY=275,angle=0;
  if(p>.14f&&p<.25f){float u=Ease((p-.14f)/.11f);PointF end=Grip(0,0);handX=704+(end.X-704)*u;handY=275+(end.Y-275)*u;angle=110*u;}
  else if(p>=.25f&&p<.34f){float u=Ease((p-.25f)/.09f);PointF hand=Grip(0,u);handX=hand.X;handY=hand.Y;angle=110-u*125;}
  else if(p>=.34f&&p<.48f){float u=Ease((p-.34f)/.14f);PointF start=Grip(0,1),end=Grip(1,0);handX=start.X+(end.X-start.X)*u;handY=start.Y+(end.Y-start.Y)*u;angle=-15-u*95;}
  else if(p>=.48f&&p<.57f){float u=Ease((p-.48f)/.09f);PointF hand=Grip(1,u);handX=hand.X;handY=hand.Y;angle=-110+u*125;}
  else if(p>=.57f){float u=Ease((p-.57f)/.17f);PointF start=Grip(1,1);handX=start.X+(704-start.X)*u;handY=start.Y+(275-start.Y)*u;angle=15-u*15;}
  float size=.8f;
  if(p<.25f)size=1-.2f*Ease((p-.14f)/.11f);
  if(p>=.57f)size=.8f+.2f*Ease((p-.57f)/.17f);
  for(int hit=0;hit<2;hit++){
   float at=hit==0?.29f:.52f,age=p-at;
   float cut=Ease((p-(hit==0?.25f:.48f))/.09f);
   Fracture(g,hit,cut);
   if(age>=0&&age<.20f){float u=age/.20f,alpha=1-u;
    PointF contact=Tip(hit,cut);
    Glow(g,contact.X,contact.Y,46+u*90,Color.FromArgb((int)(alpha*165),255,202,111));
    for(int chip=0;chip<28;chip++){double a=chip*2.399+hit;float radius=30+u*(120+chip%5*24);PointF origin=Tip(hit,Ease((at-(hit==0?.25f:.48f))/.09f));float cx=origin.X+(float)Math.Cos(a)*radius,cy=origin.Y+(float)Math.Sin(a)*radius+u*u*82;
     float r=(5+chip%4*3)*(1-u*.5f);Poly(g,Color.FromArgb((int)(alpha*235),chip%2==0?151:66,chip%2==0?136:60,chip%2==0?111:53),P(cx-r,cy),P(cx,cy-r),P(cx+r,cy+3),P(cx+2,cy+r));
     if(chip%3==0)Line(g,Color.FromArgb((int)(alpha*230),255,209,129),3,P(cx,cy),P(cx-(float)Math.Cos(a)*22,cy-(float)Math.Sin(a)*22));
    }
   }
  }
  if((p>.25f&&p<.34f)||(p>.48f&&p<.57f)){float direction=p<.34f?1:-1;for(int trail=3;trail>0;trail--)HeldSword(g,handX,handY,angle+direction*trail*7,size,.035f);}
  HeldSword(g,handX,handY,angle,size,1);
  // Preserve the talent's point counter.
  for(int yy=642;yy<819;yy++)for(int xx=592;xx<821;xx++){float dx=Math.Max(0,Math.Max(620-xx,xx-793)),dy=Math.Max(0,Math.Max(670-yy,yy-791));float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/28);Color c=im.GetPixel(xx,yy);if(c.A>0)im.SetPixel(xx,yy,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));}
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[ColossusArt]::Write($destination)
