param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Affliction-SoulHarvester-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SoulHarvesterArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 static PointF Roam(float u,int soul){
  double direction=soul%2==0?1:-1;
  double a=Math.PI/2+soul*.31+direction*(u*(1.35+soul*.17)+Math.Sin(u*Math.PI*4+soul)*.035)*Math.PI*2;
  float radius=232+soul%3*17+(float)Math.Sin(u*19+soul)*13;
  float x=(float)Math.Cos(a)*radius;
  float y=(float)Math.Sin(a)*(66+soul%3*22)+(float)Math.Sin(a*2+soul)*13;
  float tilt=(soul-2.5f)*.07f;
  return new PointF(512+x,506+y+x*tilt);
 }
 static PointF Harvest(float age,int soul){
  if(age<.78f)return Roam(age/.78f,soul);
  PointF caught=Roam(1,soul);
  float pull=(age-.78f)/.22f;pull=pull*pull;
  float struggle=(float)Math.Sin(pull*Math.PI*3+soul)*(float)Math.Sin(pull*Math.PI)*18;
  return new PointF(caught.X+(512-caught.X)*pull+struggle,caught.Y+(275-caught.Y)*pull);
 }
 public static void Write(string output){for(int f=0;f<108;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/108;float pulse=(float)(.5+.5*Math.Sin(t));
  // Dark demonic visage above the spell; hooked horns and violet soul-fire eyes.
  Glow(g,512,239,109,Color.FromArgb(95,62,13,87));
  for(int side=-1;side<=1;side+=2){
   var demon=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   using(var horn=new GraphicsPath()){
    horn.AddBezier(32,206,86,132,145,145,159,237);
    horn.AddBezier(159,237,129,190,95,189,65,236);horn.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(50,170),new PointF(150,240),Color.FromArgb(255,49,30,66),Color.FromArgb(255,10,10,20)))g.FillPath(fill,horn);
    using(var rim=new Pen(Color.FromArgb(175,106,53,140),3))g.DrawPath(rim,horn);
   }
   Poly(g,Color.FromArgb(255,24,18,36),new PointF(0,179),new PointF(41,192),new PointF(70,229),new PointF(53,268),new PointF(21,285),new PointF(0,306));
   Line(g,Color.FromArgb(195,73,43,99),3,new PointF(8,195),new PointF(32,213),new PointF(49,240),new PointF(28,270));
   Glow(g,33,233,24,Color.FromArgb((int)(130+pulse*65),147,28,231));
   Line(g,Color.FromArgb(245,211,91,255),5,new PointF(13,235),new PointF(29,226),new PointF(46,236));
   Poly(g,Color.FromArgb(255,63,35,77),new PointF(15,259),new PointF(36,254),new PointF(27,287),new PointF(10,297));
   g.Restore(demon);
  }
  Line(g,Color.FromArgb(200,102,42,138),3,new PointF(512,192),new PointF(503,239),new PointF(512,256),new PointF(521,239),new PointF(512,192));
  // A visible maw draws in the spiraling souls and flares as they disappear.
  Glow(g,512,278,34,Color.FromArgb((int)(95+pulse*70),181,40,237));
  using(var maw=new SolidBrush(Color.FromArgb(255,17,5,28)))g.FillEllipse(maw,493,263,38,30);
  for(int fang=0;fang<4;fang++)Poly(g,Color.FromArgb(225,183,121,213),new PointF(496+fang*8,265),new PointF(502+fang*8,265),new PointF(499+fang*8,273));
  // Psychic suction visibly narrows into the demon's mouth.
  for(int particle=0;f<107&&particle<19;particle++){
   float age=(float)((f/108.0*2+particle*.05263)%1),pull=age*age;
   float x=512+(float)Math.Sin(particle*3.7+age*5)*(1-pull)*57,y=441-pull*164;
   float tail=12+pull*15;int a=(int)(Math.Sin(age*Math.PI)*140);
   Line(g,Color.FromArgb(a/3,147,37,219),9,new PointF(x,y+tail),new PointF(x,y));
   Line(g,Color.FromArgb(a,216,120,255),2,new PointF(x,y+tail),new PointF(x,y));
  }
  // Souls are born below, struggle around the whole icon, then collapse into the maw.
  for(int soul=0;soul<6;soul++){
   float clock=f/107f,birth=soul*.023f,capture=.28f+soul*.12f;
   if(clock<birth)continue;
   // Only one soul enters its final pull at a time; the others keep struggling.
   float age=clock<capture?(clock-birth)/(capture-birth)*.78f:.78f+(clock-capture)/.11f*.22f;
   if(age<=0||age>=1)continue;
   float fade=Math.Min(1,age/.08f)*Math.Min(1,(1-age)/.09f);
   for(int strand=0;strand<4;strand++){
    PointF[] trail=new PointF[36];
    for(int j=0;j<36;j++){
     float p=Math.Max(0,age-j/35f*.16f);PointF pos=Harvest(p,soul);
     float flutter=(float)Math.Sin(t*3+j*.7+soul)*j/35f*9;
     trail[j]=new PointF(pos.X+(strand-1.5f)*5+flutter,pos.Y+strand*3);
    }
    Line(g,Color.FromArgb((int)(fade*22),125,24,191),22,trail);
    Line(g,Color.FromArgb((int)(fade*105),178+strand*15,72+strand*18,247),3.5f,trail);
   }
   PointF lead=Harvest(age,soul);
   float consumed=Math.Max(0,(age-.78f)/.22f),scale=(1-consumed*.9f);
   var spirit=g.Save();g.TranslateTransform(lead.X,lead.Y);g.RotateTransform((float)Math.Sin(t*5+soul)*12*(1-consumed));
   g.ScaleTransform(1.28f*scale*(1-consumed*.5f),1.28f*scale*(1+consumed*3));
   Glow(g,0,0,44,Color.FromArgb((int)(fade*100),151,40,218));
   // Hollow anguished faces with deep eye sockets and long screaming mouths.
   using(var skull=new GraphicsPath()){
    skull.AddBezier(-28,4,-39,-33,-16,-47,5,-43);
    skull.AddBezier(5,-43,34,-42,38,-15,24,9);
    skull.AddBezier(24,9,20,35,13,53,0,57);
    skull.AddBezier(0,57,-16,43,-22,24,-28,4);skull.CloseFigure();
    using(var bone=new LinearGradientBrush(new PointF(0,-43),new PointF(0,44),Color.FromArgb((int)(fade*230),214,155,249),Color.FromArgb((int)(fade*50),110,37,175)))g.FillPath(bone,skull);
   }
   using(var hollow=new SolidBrush(Color.FromArgb((int)(fade*245),39,8,65))){
    g.FillEllipse(hollow,-23,-23,17,22);
    g.FillEllipse(hollow,6,-23,17,22);
    float scream=2+(float)Math.Sin(t*4+soul)*2;
    g.FillEllipse(hollow,-13-scream*.3f,6,26+scream*.6f,41+scream);
   }
   using(var frightened=new SolidBrush(Color.FromArgb((int)(fade*210),235,198,255))){g.FillEllipse(frightened,-14,-17,4,5);g.FillEllipse(frightened,10,-17,4,5);}
   Line(g,Color.FromArgb((int)(fade*210),241,194,255),2,new PointF(-25,-25),new PointF(-16,-33),new PointF(-7,-37));
   Line(g,Color.FromArgb((int)(fade*210),241,194,255),2,new PointF(25,-25),new PointF(16,-33),new PointF(7,-37));
   Line(g,Color.FromArgb((int)(fade*140),92,38,143),2,new PointF(-25,0),new PointF(-19,14),new PointF(-20,32));
   Line(g,Color.FromArgb((int)(fade*140),92,38,143),2,new PointF(25,0),new PointF(19,14),new PointF(20,32));
   g.Restore(spirit);
   if(consumed>0)Glow(g,512,278,22,Color.FromArgb((int)(Math.Sin(consumed*Math.PI)*150),228,116,255));
  }
  for(int mote=0;f<107&&mote<34;mote++){
   float age=(float)((f/108.0+mote*.137)%1);double a=mote*2.4+t*.3;
   float x=512+(float)Math.Cos(a)*(220+age*43),y=510+(float)Math.Sin(a)*218-age*33;
   Glow(g,x,y,5,Color.FromArgb((int)(Math.Sin(age*Math.PI)*160),188,69,241));
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
[SoulHarvesterArt]::Write($destination)
