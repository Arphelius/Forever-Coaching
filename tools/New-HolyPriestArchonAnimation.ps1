param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/HolyPriest-Archon-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ArchonArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var path=new GraphicsPath()){path.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(path)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,path);}}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  for(int side=-1;side<=1;side+=2){
   bool holy=side<0;Color core=holy?Color.FromArgb(255,255,229,143):Color.FromArgb(255,163,77,239);
   Color edge=holy?Color.FromArgb(240,255,248,207):Color.FromArgb(240,203,127,255);
   var angel=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   float surge=(float)(.5+.5*Math.Sin(t+(holy?0:Math.PI)));
   // Distinct living auras breathe around the two figures.
   for(int aura=0;aura<9;aura++){
    float y=293+aura*39,x=244+(float)Math.Sin(aura*.7+t)*11;
    Glow(g,x,y,51+surge*39,holy?Color.FromArgb((int)(24+surge*90),255,237,157):Color.FromArgb((int)(35+surge*100),104,22,161));
   }
   // Sweeping feathered wings enclose each side of the talent.
   for(int feather=0;feather<10;feather++){
    float lift=(float)Math.Sin(t+feather*.37+side)*9;
    float tipX=239+feather*8,tipY=159+feather*30+lift;
    using(var wing=new GraphicsPath()){
     wing.AddBezier(220,535,361,460,367,267,tipX,tipY);
     wing.AddBezier(tipX,tipY,tipX+44,tipY+135,289,451,220,535);wing.CloseFigure();
     using(var fill=new LinearGradientBrush(new PointF(230,535),new PointF(tipX,tipY),holy?Color.FromArgb(190,240,139,20):Color.FromArgb(210,49,17,83),holy?Color.FromArgb(220,255,237,154):Color.FromArgb(200,170,50,239)))g.FillPath(fill,wing);
     using(var rim=new Pen(Color.FromArgb(155,edge),2))g.DrawPath(rim,wing);
    }
   }
   // Hooded angel, narrow body and long flowing robes sit outside the artwork.
   float sway=(float)Math.Sin(t+side)*5;
   Glow(g,242,405,54,Color.FromArgb(85,core));
   using(var robe=new GraphicsPath()){
    robe.AddBezier(224,432,194,491,240,560,198+sway,666);
    robe.AddBezier(198+sway,666,264,620,290,568,268,474);
    robe.AddBezier(268,474,257,450,261,436,224,432);robe.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(210,448),new PointF(280,620),holy?Color.FromArgb(245,255,213,105):Color.FromArgb(245,38,22,60),holy?Color.FromArgb(90,255,159,20):Color.FromArgb(100,139,40,221)))g.FillPath(fill,robe);
    using(var rim=new Pen(Color.FromArgb(190,edge),3))g.DrawPath(rim,robe);
   }
   using(var hood=new GraphicsPath()){
    hood.AddBezier(222,432,209,409,224,378,244,368);
    hood.AddBezier(244,368,269,382,276,410,263,434);hood.CloseFigure();
    using(var fill=new SolidBrush(holy?Color.FromArgb(255,255,224,147):Color.FromArgb(255,59,29,87)))g.FillPath(fill,hood);
    using(var rim=new Pen(edge,3))g.DrawPath(rim,hood);
   }
   using(var face=new SolidBrush(holy?Color.FromArgb(235,132,92,44):Color.FromArgb(255,18,13,30)))g.FillEllipse(face,233,395,22,30);
   Line(g,edge,3,new PointF(239,405),new PointF(250,405));
   // Raised arms channel holy or shadow light toward the talent.
   Line(g,Color.FromArgb(220,core),13,new PointF(234,451),new PointF(205,482),new PointF(176,459));
   Glow(g,176,455,25,Color.FromArgb(170,core));
   using(var halo=new Pen(Color.FromArgb(150,edge),3))g.DrawEllipse(halo,215,354,57,15);
   for(int fold=0;fold<3;fold++)Line(g,Color.FromArgb(155,edge),2,new PointF(236+fold*8,472),new PointF(243+fold*8,543),new PointF(214+fold*11,623));
   // Flowing curved wakes unite the figures around the lower border.
   // Living currents rise alongside each angel in broad, tapered curls.
   for(int stream=0;stream<6;stream++){
    float shift=stream*9,wave=(float)Math.Sin(t+stream*.7)*12;
    float top=245+stream*21+wave;
    using(var flow=new GraphicsPath()){
     flow.AddBezier(192+shift,673,353+shift,611,380+shift,405,269+shift,top);
     flow.AddBezier(269+shift,top,342+shift,408,319+shift,584,192+shift,673);flow.CloseFigure();
     Color start=holy?Color.FromArgb(80,255,182,36):Color.FromArgb(100,86,19,150);
     Color end=holy?Color.FromArgb(5,255,244,161):Color.FromArgb(8,179,57,241);
     using(var fill=new LinearGradientBrush(new PointF(230,673),new PointF(300,top),start,end))g.FillPath(fill,flow);
    }
   }
   for(int wisp=0;wisp<19;wisp++){
    float age=(float)((f/36.0+wisp*.053)%1),angle=age*2.35f;
    float x=214+115*(float)Math.Sin(angle),y=664-age*400;
    float currentSway=(float)Math.Sin(t*2+wisp)*9;
    using(var wake=new GraphicsPath()){
     wake.AddBezier(x-11,y+27,x+18+currentSway,y+8,x+currentSway,y-5,x-10,y-28);
     int alpha=(int)(Math.Sin(age*Math.PI)*180);
     using(var haze=new Pen(holy?Color.FromArgb(alpha/3,255,193,65):Color.FromArgb(alpha/3,128,39,206),13))g.DrawPath(haze,wake);
     using(var light=new Pen(holy?Color.FromArgb(alpha,255,238,151):Color.FromArgb(alpha,179,77,248),3))g.DrawPath(light,wake);
    }
   }
   for(int curl=0;curl<4;curl++)using(var wake=new GraphicsPath()){
    float shift=(float)Math.Sin(t+curl)*7;
    wake.AddBezier(265,492,348+curl*7,681+shift,111,752,-12,697+curl*6);
    using(var haze=new Pen(Color.FromArgb(24,core),18))g.DrawPath(haze,wake);
    using(var light=new Pen(Color.FromArgb(120,core),3))g.DrawPath(light,wake);
   }
   // Surface radiance swells over the robes and follows the wing contours.
   Glow(g,243,441,72+surge*16,holy?Color.FromArgb((int)(30+surge*150),255,247,195):Color.FromArgb((int)(35+surge*150),156,45,235));
   for(int flare=0;flare<7;flare++){
    float y=315+flare*43,spread=24+surge*42;
    float alpha=(holy?225:235)*surge;
    Line(g,holy?Color.FromArgb((int)(alpha*.35f),255,215,95):Color.FromArgb((int)(alpha*.35f),139,43,216),15,new PointF(233-spread*.3f,y+12),new PointF(246,y),new PointF(252+spread,y-19));
    Line(g,holy?Color.FromArgb((int)alpha,255,250,209):Color.FromArgb((int)alpha,205,119,255),5,new PointF(233-spread*.3f,y+12),new PointF(246,y),new PointF(252+spread,y-19));
   }
   g.Restore(angel);
   for(int mote=0;mote<23;mote++){
    float age=(float)((f/36.0+mote*.137)%1),x=512+side*(220+(float)Math.Sin(age*5+mote)*48),y=702-age*470;
    Glow(g,x,y,5,Color.FromArgb((int)(Math.Sin(age*Math.PI)*190),core));
   }
  }
  // The icon itself carries a split holy/shadow perimeter.
  for(int side=-1;side<=1;side+=2){
   bool holy=side<0;float pulse=(float)(.5+.5*Math.Sin(t+(holy?0:Math.PI)));
   // Soft moving radiance and billowing darkness replace geometric strokes.
   for(int glow=0;glow<64;glow++){
    float age=(float)((f/36.0+glow*.015625)%1),d=age*812;
    float x,y;
    if(d<203){x=512+side*d;y=309;}
    else if(d<609){x=512+side*203;y=309+d-203;}
    else{x=512+side*(812-d);y=715;}
    float drift=(float)Math.Sin(t*2+glow*1.71)*5;
    float billow=(float)(.5+.5*Math.Sin(t*2+glow*.93));
    Glow(g,x+side*drift,y,21+billow*9,holy?Color.FromArgb((int)(45+pulse*25),255,226,117):Color.FromArgb(95,23,8,37));
    Glow(g,x,y+drift*.5f,9+billow*6,holy?Color.FromArgb((int)(100+pulse*60),255,248,191):Color.FromArgb((int)(65+pulse*50),126,39,192));
    if(glow%4==0){
     Glow(g,x+side*(7+billow*9),y-9,holy?8:14,holy?Color.FromArgb(125,255,251,218):Color.FromArgb(120,79,20,125));
    }
   }
   for(int mote=0;mote<23;mote++){
    float age=(float)((f/36.0+mote*.067)%1),y=711-age*400;
    float x=512+side*(203+(float)Math.Sin(t+age*7+mote)*7);
    Glow(g,x,y,holy?13:18,holy?Color.FromArgb((int)(Math.Sin(age*Math.PI)*215),255,245,182):Color.FromArgb((int)(Math.Sin(age*Math.PI)*205),153,49,226));
   }
  }
  // Keep the point badge clear without cutting the figures themselves.
  for(int y=646;y<814;y++)for(int x=610;x<807;x++){
   float dx=Math.Max(0,Math.Max(636-x,x-780)),dy=Math.Max(0,Math.Max(672-y,y-788));
   float fade=Math.Min(1,(float)Math.Sqrt(dx*dx+dy*dy)/26);Color c=im.GetPixel(x,y);
   if(c.A>0)im.SetPixel(x,y,Color.FromArgb((int)(c.A*fade),c.R,c.G,c.B));
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[ArchonArt]::Write($destination)
