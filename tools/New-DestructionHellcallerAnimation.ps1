param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Destruction-Hellcaller-v5'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class HellcallerArt {
 static float Smooth(float p){p=Math.Max(0,Math.Min(1,p));return p*p*(3-2*p);}
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Glow(Graphics g,float x,float y,float r,Color c){using(var path=new GraphicsPath()){path.AddEllipse(x-r,y-r,r*2,r*2);using(var b=new PathGradientBrush(path)){b.CenterColor=c;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,path);}}}
 static void Flame(Graphics g,float x,float y,float h,float sway,int alpha){if(h<.1f||alpha<=0)return;using(var flame=new GraphicsPath()){
  flame.AddBezier(x-10,y,x-25,y-h*.4f,x+sway-8,y-h*.65f,x+sway,y-h);
  flame.AddBezier(x+sway,y-h,x+24,y-h*.3f,x+13,y-5,x-10,y);flame.CloseFigure();
  using(var fill=new LinearGradientBrush(new PointF(x,y),new PointF(x,y-h),Color.FromArgb(alpha,255,76,1),Color.FromArgb(0,255,192,38)))g.FillPath(fill,flame);
 }}
 public static void Write(string output){for(int f=0;f<108;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;float progress=f/107f;double t=f/36.0*Math.PI*2;
  float ritual=Smooth(progress/.18f),burn=Smooth((progress-.42f)/.12f);
  // A dark horned ritualist watches over the spell, lit only by ember-red eyes.
  Glow(g,512,248,105,Color.FromArgb(115,36,10,38));
  for(int side=-1;side<=1;side+=2){
   var visage=g.Save();g.TranslateTransform(512,0);g.ScaleTransform(side,1);
   using(var horn=new GraphicsPath()){
    horn.AddBezier(39,218,113,219,135,132,88,91);
    horn.AddBezier(88,91,108,149,72,164,53,171);horn.CloseFigure();
    using(var fill=new LinearGradientBrush(new PointF(40,215),new PointF(122,110),Color.FromArgb(255,57,40,41),Color.FromArgb(255,15,13,24)))g.FillPath(fill,horn);
    using(var rim=new Pen(Color.FromArgb(160,112,64,57),3))g.DrawPath(rim,horn);
   }
   Poly(g,Color.FromArgb(255,27,18,31),new PointF(0,166),new PointF(25,187),new PointF(51,180),new PointF(77,225),new PointF(57,266),new PointF(24,287),new PointF(0,307));
   Line(g,Color.FromArgb(165,87,47,69),3,new PointF(9,189),new PointF(31,209),new PointF(59,219),new PointF(41,245));
   Glow(g,31,230,21,Color.FromArgb((int)(110+ritual*75),194,16,20));
   Line(g,Color.FromArgb(250,255,53,45),4,new PointF(12,234),new PointF(30,225),new PointF(48,229));
   Line(g,Color.FromArgb(255,12,7,16),4,new PointF(0,264),new PointF(28,258));
   // Upturned shadow hands channel the ritual from beside the top border.
   var handPose=g.Save();g.TranslateTransform(-59,-111);
   float handY=365-ritual*12;
   Line(g,Color.FromArgb(225,31,20,38),16,new PointF(170,handY+52),new PointF(191,handY+19),new PointF(186,handY));
   for(int finger=0;finger<4;finger++)Line(g,Color.FromArgb(240,49,30,47),5,new PointF(182+finger*6,handY+7),new PointF(177+finger*9,handY-15),new PointF(181+finger*9,handY-25));
   Glow(g,186,handY-18,46,Color.FromArgb((int)(ritual*155),109,24,218));
   using(var sigil=new Pen(Color.FromArgb((int)(ritual*210),169,76,255),3))g.DrawEllipse(sigil,147,handY-33,83,24);
   for(int mark=0;mark<7;mark++){
    double a=mark*Math.PI*2/7+t;
    float x=188+(float)Math.Cos(a)*44,y=handY-22+(float)Math.Sin(a)*13;
    Line(g,Color.FromArgb((int)(ritual*185),206,127,255),2,new PointF(x-3,y-6),new PointF(x+2,y),new PointF(x-3,y+5));
   }
   g.Restore(handPose);g.Restore(visage);
  }
  // The soul of the artwork ignites from its center after the first impacts.
  var face=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  using(var heat=new SolidBrush(Color.FromArgb((int)(burn*32),187,28,1)))g.FillRectangle(heat,309,309,406,406);
  Glow(g,512,526,175,Color.FromArgb((int)(burn*59),240,44,2));
  for(int fire=0;fire<29;fire++){
   float x=324+(fire*83)%377,y=386+(fire*137)%324;
   float pulse=(float)(.5+.5*Math.Sin(t*7+fire*1.8));
   Flame(g,x,y,(65+pulse*118)*burn,(float)Math.Sin(t*5+fire)*24,(int)(burn*145));
   Glow(g,x,y,13,Color.FromArgb((int)(burn*(40+pulse*30)),255,142,18));
  }
  g.Restore(face);
  // Uneven flames lick off the borders while embers rise from the burning spell.
  for(int side=-1;side<=1;side+=2)for(int fire=0;fire<14;fire++){
   float age=(float)((f/36.0+fire*.0714)%1),x=512+side*(202+fire%3*9),y=735-age*402;
   Flame(g,x,y,(65+fire%4*23)*burn,side*15+(float)Math.Sin(t*4+fire)*20,(int)(burn*195));
  }
  for(int fire=0;fire<19;fire++){
   float x=306+fire*23,y=725+(float)Math.Sin(t*3+fire)*10;
   Flame(g,x,y,(52+22*(float)Math.Sin(t*5+fire))*burn,(float)Math.Sin(t*4+fire)*20,(int)(burn*165));
  }
  // Six meteorites descend from across the sky after the ritual.
  for(int meteor=0;meteor<6;meteor++){
   float age=(progress-.22f-meteor*.022f)/.2f;if(age<0||age>1.2f)continue;
   float targetX=342+(meteor*107)%340,targetY=371+(meteor*83)%270;
   float startX=180+meteor*133,startY=30+(meteor%3)*24;
   Glow(g,startX,startY,31,Color.FromArgb(110,119,25,209));
   if(age<=1){
    float fall=age*age,x=startX+(targetX-startX)*fall,y=startY+(targetY-startY)*fall;
    float dx=targetX-startX,dy=targetY-startY,len=(float)Math.Sqrt(dx*dx+dy*dy);dx/=len;dy/=len;
    Line(g,Color.FromArgb(75,255,53,0),58,new PointF(x-dx*110,y-dy*110),new PointF(x,y));
    Line(g,Color.FromArgb(185,255,133,15),27,new PointF(x-dx*78,y-dy*78),new PointF(x,y));
    Glow(g,x,y,51,Color.FromArgb(210,255,109,1));
    var meteorShape=g.Save();g.TranslateTransform(x,y);g.ScaleTransform(2.1f,2.1f);g.TranslateTransform(-x,-y);
    Poly(g,Color.FromArgb(255,104,37,18),new PointF(x-11,y-8),new PointF(x+8,y-13),new PointF(x+16,y+3),new PointF(x+4,y+14),new PointF(x-13,y+6));
    Line(g,Color.FromArgb(255,255,213,72),3,new PointF(x-7,y-6),new PointF(x+2,y),new PointF(x-1,y+8));
    g.Restore(meteorShape);
   }else{
    float shock=(age-1)/.2f;
    Glow(g,targetX,targetY,22+shock*49,Color.FromArgb((int)((1-shock)*180),255,134,10));
    using(var blast=new Pen(Color.FromArgb((int)((1-shock)*145),255,198,61),3))g.DrawEllipse(blast,targetX-shock*38,targetY-shock*29,shock*76+1,shock*58+1);
   }
  }
  for(int ember=0;ember<36;ember++){
   float age=(float)((f/36.0+ember*.137)%1),x=321+(ember*101)%383+(float)Math.Sin(t+ember)*9,y=715-age*397;
   Glow(g,x,y,4,Color.FromArgb((int)(Math.Sin(age*Math.PI)*burn*170),255,179,49));
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
[HellcallerArt]::Write($destination)
