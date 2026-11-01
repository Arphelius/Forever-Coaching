param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Combat-Trickster-v10'),[switch]$SmokeOnly,[switch]$ArmamentsOnly,[switch]$BloodOnly)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class TricksterArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 static void Dagger(Graphics g,float x,float y,float angle,bool shine){
  var state=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);
  using(var blade=new GraphicsPath()){
   blade.AddPolygon(new PointF[]{new PointF(-12,14),new PointF(-22,-69),new PointF(0,-180),new PointF(22,-69),new PointF(12,14)});
   using(var metal=new LinearGradientBrush(new PointF(-22,0),new PointF(22,0),Color.FromArgb(255,42,61,67),Color.FromArgb(255,225,237,226)))g.FillPath(metal,blade);
   using(var edge=new Pen(Color.FromArgb(255,243,228,166),2))g.DrawPath(edge,blade);
  }
  Line(g,Color.FromArgb(255,244,250,231),2,new PointF(0,-173),new PointF(0,8));
  Line(g,Color.FromArgb(230,156,116,56),3,new PointF(-8,-16),new PointF(-13,-52),new PointF(-5,-73),new PointF(-8,-93));
  Poly(g,Color.FromArgb(255,183,132,57),new PointF(-34,16),new PointF(-22,7),new PointF(0,16),new PointF(22,7),new PointF(34,16),new PointF(14,27),new PointF(-14,27));
  Line(g,Color.FromArgb(255,47,30,27),14,new PointF(0,30),new PointF(0,82));
  for(int wrap=0;wrap<5;wrap++)Line(g,Color.FromArgb(255,173,130,66),3,new PointF(-6,34+wrap*10),new PointF(6,39+wrap*10));
  if(shine){
   Glow(g,0,-180,38,Color.FromArgb(180,240,247,255));
   Glow(g,0,-180,21,Color.FromArgb(240,255,255,255));
   Glow(g,0,-180,11,Color.FromArgb(255,255,255,250));
   using(var source=new SolidBrush(Color.FromArgb(255,255,255,248)))g.FillEllipse(source,-4,-184,8,8);
   Line(g,Color.FromArgb(150,245,250,255),9,new PointF(-22,-180),new PointF(22,-180));
   Line(g,Color.FromArgb(245,255,255,239),3,new PointF(-19,-180),new PointF(19,-180));
   Line(g,Color.FromArgb(255,255,255,249),3,new PointF(0,-205),new PointF(0,-157));
  }
  g.Restore(state);
 }
 public static void Write(string output,bool smokeOnly,bool armamentsOnly,bool bloodOnly){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  if(!armamentsOnly&&!bloodOnly){
  // The same flowing curtains and descending curls used by Frost, in smoke.
  var face=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  for(int lane=0;lane<9;lane++)for(int puff=0;puff<4;puff++){
   float age=(float)((f/36.0+puff*.241+lane*.079)%1);
   float x=326+lane*45+(float)Math.Sin(t+lane+age*5)*10,y=325+age*405;
   Glow(g,x,y,44,Color.FromArgb((int)(Math.Sin(age*Math.PI)*110),106,102,88));
  }
  g.Restore(face);
  for(int edge=0;edge<3;edge++)for(int wisp=0;wisp<18;wisp++){
   float age=(float)((f/36.0+wisp*.0837+edge*.173)%1),wave=(float)Math.Sin(t*2+wisp*1.7+edge);
   float x=edge==0?298+age*428:(edge==1?288:736)+wave*12;
   float y=edge==0?288+wave*12:298+age*410;
   Glow(g,x,y,45,Color.FromArgb((int)(Math.Sin(age*Math.PI)*135),108,104,91));
  }
  for(int lane=0;lane<12;lane++)for(int puff=0;puff<5;puff++){
   float age=(float)((f/36.0+puff*.193+lane*.061)%1),spread=age*age*age;
   float origin=354+lane*27,side=lane<6?-1:1,curl=(float)Math.Sin(t*2+lane*.93+puff*1.7);
   float x=origin+side*spread*134+curl*(3+age*7);
   float y=674+112*(float)(1-Math.Exp(-2.2*age))+age*15;
   float fade=(float)(Math.Sin(Math.Min(1,age*6)*Math.PI*.5)*Math.Pow(1-age,1.15));
   Glow(g,x,y,22+age*22,Color.FromArgb((int)(fade*170),120,113,95));
  }
  }
  if(!smokeOnly&&!bloodOnly){
  // One razor-sharp blade becomes two only after both dice have disappeared.
  float split=Math.Max(0,Math.Min(1,(f-28)/7f));split=split*split*(3-2*split);
  if(f<29)Dagger(g,512,222,0,true);
  else for(int side=-1;side<=1;side+=2)Dagger(g,512+side*split*58,222,-side*split*30,false);
  for(int die=0;die<2;die++){
   int localFrame=f-(die==0?2:6);if(localFrame<0||f>27)continue;
   float age=Math.Min(1,localFrame/10f),side=die==0?-1:1;
   float x=512+side*age*246,y=42+age*210+age*age*360;
   var roll=g.Save();g.TranslateTransform(x,y);g.RotateTransform(age<1?side*age*360:0);g.ScaleTransform(1.4f,1.4f);
   // Three solid cube faces stay visible even while the die tumbles.
   Poly(g,Color.FromArgb(255,251,239,204),new PointF(-25,-25),new PointF(-10,-40),new PointF(40,-40),new PointF(25,-25));
   Poly(g,Color.FromArgb(255,139,121,85),new PointF(25,-25),new PointF(40,-40),new PointF(40,10),new PointF(25,25));
   using(var bone=new LinearGradientBrush(new PointF(-25,-25),new PointF(25,25),Color.FromArgb(255,246,233,187),Color.FromArgb(255,182,165,122)))g.FillRectangle(bone,-25,-25,50,50);
   Line(g,Color.FromArgb(255,94,78,53),1.5f,new PointF(-25,-25),new PointF(25,-25),new PointF(25,25),new PointF(-25,25),new PointF(-25,-25));
   int number=age>=1?(die==0?5:3):new Random(417+die*83+localFrame/2*197).Next(1,7);
   using(var pip=new SolidBrush(Color.FromArgb(255,45,39,34))){
    if(number%2==1)g.FillEllipse(pip,-4,-4,8,8);
    if(number>=2){g.FillEllipse(pip,-17,-17,8,8);g.FillEllipse(pip,9,9,8,8);}
    if(number>=4){g.FillEllipse(pip,9,-17,8,8);g.FillEllipse(pip,-17,9,8,8);}
    if(number==6){g.FillEllipse(pip,-17,-4,8,8);g.FillEllipse(pip,9,-4,8,8);}
    g.FillEllipse(pip,0,-34,7,4);g.FillEllipse(pip,18,-34,7,4);
    g.FillEllipse(pip,30,-18,4,7);g.FillEllipse(pip,30,-5,4,7);
   }
   g.Restore(roll);
  }
  }
  if(bloodOnly)for(int side=-1;side<=1;side+=2){
   float tipX=512-side*32,tipY=222-180*(float)Math.Cos(Math.PI/6);
   for(int drop=0;drop<3;drop++){
    float life=(float)((f/36.0+drop/3.0+(side==1?.2:0))%1);
    float y=tipY+life*life*145,x=tipX+(float)Math.Sin(life*3+side)*2;
    int alpha=(int)(Math.Min(1,life*9)*(1-Math.Max(0,(life-.85f)/.15f))*255);
    using(var blood=new SolidBrush(Color.FromArgb(alpha,218,13,32)))g.FillEllipse(blood,x-5,y-8,10,16);
    Line(g,Color.FromArgb(alpha/2,150,5,19),3,new PointF(x,y-13),new PointF(x,y-4));
    using(var sheen=new SolidBrush(Color.FromArgb(alpha,255,102,112)))g.FillEllipse(sheen,x-2,y-6,3,5);
   }
   using(var bead=new SolidBrush(Color.FromArgb(255,203,11,30)))g.FillEllipse(bead,tipX-5,tipY-3,10,10);
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
[TricksterArt]::Write($destination,$SmokeOnly.IsPresent,$ArmamentsOnly.IsPresent,$BloodOnly.IsPresent)
