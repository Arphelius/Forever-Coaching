param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Assassination-Fatebound-v9'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FateboundArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color color){using(var p=new GraphicsPath()){p.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(p)){b.CenterColor=color;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 static PointF Spill(float age,int side){
  float x=512+side*(62+185*(float)Math.Sin(age*Math.PI*.66));
  float y=245+age*490;return new PointF(x,y);
 }
 static void Coin(Graphics g,float x,float y,float flip,float angle){
  var state=g.Save();g.TranslateTransform(x,y);g.RotateTransform(angle);g.ScaleTransform(.07f+.93f*Math.Abs(flip),1);
  using(var metal=new LinearGradientBrush(new PointF(-27,-29),new PointF(28,29),Color.FromArgb(255,255,228,133),Color.FromArgb(255,131,77,21)))g.FillEllipse(metal,-29,-29,58,58);
  using(var rim=new Pen(Color.FromArgb(255,255,223,120),3))g.DrawEllipse(rim,-28,-28,56,56);
  using(var inset=new Pen(Color.FromArgb(255,123,80,29),2))g.DrawEllipse(inset,-23,-23,46,46);
  // Raised skull with recessed sockets, nose and three engraved teeth.
  using(var skull=new SolidBrush(Color.FromArgb(255,255,230,149))){g.FillEllipse(skull,-15,-17,30,27);g.FillRectangle(skull,-9,3,18,13);}
  using(var dark=new SolidBrush(Color.FromArgb(255,76,50,22))){g.FillEllipse(dark,-11,-8,8,9);g.FillEllipse(dark,3,-8,8,9);g.FillPolygon(dark,new PointF[]{new PointF(0,0),new PointF(-3,6),new PointF(3,6)});}
  Line(g,Color.FromArgb(255,128,83,29),2,new PointF(-3,9),new PointF(-3,16));Line(g,Color.FromArgb(255,128,83,29),2,new PointF(3,9),new PointF(3,16));
  g.Restore(state);
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  // Two opposing daggers rest together above the talent, coated in deadly poison.
  for(int side=-1;side<=1;side+=2){
   var dagger=g.Save();g.TranslateTransform(512+side*24,234);g.RotateTransform(180+side*38);
   Poly(g,Color.FromArgb(255,49,68,73),new PointF(-15,53),new PointF(-24,-28),new PointF(0,-106),new PointF(24,-28),new PointF(15,53));
   Poly(g,Color.FromArgb(255,159,184,170),new PointF(0,48),new PointF(0,-100),new PointF(20,-28),new PointF(12,48));
   Line(g,Color.FromArgb(255,211,227,180),2,new PointF(0,-91),new PointF(0,44));
   // Uneven clinging venom follows the cutting edge.
   Line(g,Color.FromArgb(145,91,186,11),10,new PointF(-14,40),new PointF(-19,-25),new PointF(0,-98));
   Line(g,Color.FromArgb(240,169,244,38),3,new PointF(-14,40),new PointF(-19,-25),new PointF(0,-98));
   Line(g,Color.FromArgb(255,179,134,52),9,new PointF(-34,54),new PointF(0,48),new PointF(34,54));
   Line(g,Color.FromArgb(255,54,39,30),15,new PointF(0,59),new PointF(0,102));
   for(int wrap=0;wrap<4;wrap++)Line(g,Color.FromArgb(255,169,127,58),3,new PointF(-7,63+wrap*10),new PointF(7,68+wrap*10));
   Glow(g,-15,3,24,Color.FromArgb(85,105,194,13));
   g.Restore(dagger);
   // Drops start at the rotated blade tip and fall vertically in world space.
   double bladeAngle=(180+side*38)*Math.PI/180;
   float tipX=512+side*24+(float)Math.Sin(bladeAngle)*106;
   float tipY=234-(float)Math.Cos(bladeAngle)*106;
   for(int drop=0;drop<4;drop++){
    float life=(float)((f/36.0+drop*.25+side*.08+1)%1);
    float dy=life*life*99,dx=(float)Math.Sin(life*4+drop)*2;
    int alpha=(int)(Math.Sin(life*Math.PI)*220);
    Glow(g,tipX+dx,tipY+dy,8,Color.FromArgb(alpha/2,117,209,18));
    using(var venom=new SolidBrush(Color.FromArgb(alpha,165,236,35)))g.FillEllipse(venom,tipX+dx-2.5f,tipY+dy-4,5,9);
   }
  }
  // A shadowed hand flicks coins downward from above, alternating sides.
  for(int toss=0;toss<2;toss++){
   int localFrame=f-toss*18;
   if(localFrame<0||localFrame>15)continue;
   float age=localFrame/15f,side=toss==0?-1:1;
   float x=512+side*(194+age*95);
   float y=285+age*145+age*age*230;
   // Venom remains along the entire thrown path until its coin disappears.
   float tailStart=0;
   for(int segment=0;segment<34;segment++){
    float p=tailStart+(age-tailStart)*segment/34f;
    float q=tailStart+(age-tailStart)*(segment+1)/34f;
    float px=512+side*(194+p*95),py=285+p*145+p*p*230;
    float qx=512+side*(194+q*95),qy=285+q*145+q*q*230;
    float strength=(float)Math.Sin((segment+1)/35f*Math.PI*.65);
    Line(g,Color.FromArgb((int)(70*strength),48,112,7),25,new PointF(px,py),new PointF(qx,qy));
    Line(g,Color.FromArgb((int)(175*strength),100,185,13),10,new PointF(px,py),new PointF(qx,qy));
    Line(g,Color.FromArgb((int)(210*strength),191,245,47),3,new PointF(px,py),new PointF(qx,qy));
    if(segment%4==0)Glow(g,px+(float)Math.Sin(t*3+segment)*10,py+5,7,Color.FromArgb(125,133,223,23));
   }
   // Poison sprays around the releasing fingers and dissipates after the throw.
   for(int spray=0;spray<15;spray++){
    float life=Math.Min(1,age*2.4f),angle=spray*2.4f;
    float sx=512+side*194+(float)Math.Cos(angle)*life*54;
    float sy=285+(float)Math.Sin(angle)*life*34+life*life*28;
    Glow(g,sx,sy,7+life*5,Color.FromArgb((int)((1-life)*175),140,229,22));
   }
   float handAlpha=Math.Max(0,1-age*1.15f);
   if(handAlpha>0){
    float hx=512+side*186,hy=253-age*12;
    Glow(g,hx,hy,66,Color.FromArgb((int)(handAlpha*150),25,13,40));
    var hand=g.Save();g.TranslateTransform(hx,hy);g.ScaleTransform(side,1);g.RotateTransform(age*65);
    g.ScaleTransform(1.2f,1.2f);
    // Tapered forearm, palm, four articulated fingers and an opposing thumb.
    using(var silhouette=new GraphicsPath()){
     silhouette.AddBezier(-93,-26,-55,-23,-39,-26,-22,-22);
     silhouette.AddBezier(-22,-22,-4,-26,8,-13,9,6);
     silhouette.AddBezier(9,6,5,24,-14,29,-33,20);
     silhouette.AddBezier(-33,20,-53,7,-72,9,-93,13);silhouette.CloseFigure();
     using(var skin=new LinearGradientBrush(new PointF(-20,-25),new PointF(-20,28),Color.FromArgb((int)(handAlpha*255),88,80,100),Color.FromArgb((int)(handAlpha*255),22,20,31)))g.FillPath(skin,silhouette);
    }
    for(int finger=0;finger<4;finger++){
     float yy=-19+finger*10,length=35-Math.Abs(finger-1)*5;
     using(var digit=new GraphicsPath()){
      digit.AddBezier(-8,yy,8,yy-4,length-7,yy-9,length,yy+4);
      digit.AddBezier(length,yy+4,length+5,yy+13,length-6,yy+17,length-11,yy+13);
      using(var shadow=new Pen(Color.FromArgb((int)(handAlpha*250),30,27,41),10)){shadow.StartCap=shadow.EndCap=LineCap.Round;g.DrawPath(shadow,digit);}
      using(var skin=new Pen(Color.FromArgb((int)(handAlpha*230),102-finger*8,91-finger*6,116-finger*8),6)){skin.StartCap=skin.EndCap=LineCap.Round;g.DrawPath(skin,digit);}
     }
     Line(g,Color.FromArgb((int)(handAlpha*150),159,141,170),1.5f,new PointF(11,yy-2),new PointF(17,yy));
    }
    using(var thumb=new GraphicsPath()){
     thumb.AddBezier(-22,10,-8,26,7,37,22,28);
     using(var flesh=new Pen(Color.FromArgb((int)(handAlpha*245),77,68,92),11)){flesh.StartCap=flesh.EndCap=LineCap.Round;g.DrawPath(flesh,thumb);}
    }
    Line(g,Color.FromArgb((int)(handAlpha*160),148,128,160),2,new PointF(-71,-18),new PointF(-34,-19),new PointF(-14,-15));
    for(int smoke=0;smoke<6;smoke++)Glow(g,-43-smoke*11,smoke%2*8,18,Color.FromArgb((int)(handAlpha*(60-smoke*7)),33,19,48));
    g.Restore(hand);
   }
   var coinSize=g.Save();g.TranslateTransform(x,y);g.ScaleTransform(1.65f,1.65f);
   Coin(g,0,0,(float)Math.Cos(age*Math.PI*4),side*(float)Math.Sin(age*Math.PI)*13);
   g.Restore(coinSize);
  }
  // Leave the points badge unobstructed.
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
[FateboundArt]::Write($destination)
