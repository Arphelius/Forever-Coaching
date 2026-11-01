param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Feral-Wildstalker-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class WildstalkerArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // Deep foliage shadow surrounds the talent and conceals the tiger's face.
  for(int wisp=0;wisp<23;wisp++){
   double a=wisp*Math.PI*2/23;float x=512+(float)Math.Cos(a)*233,y=498+(float)Math.Sin(a)*227;
   using(var shadow=new GraphicsPath()){shadow.AddEllipse(x-85,y-66,170,132);using(var fill=new PathGradientBrush(shadow)){fill.CenterColor=Color.FromArgb(160,12,15,20);fill.SurroundColors=new Color[]{Color.FromArgb(0,23,17,30)};g.FillPath(fill,shadow);}}
  }
  // Only one huge eye is visible above the icon; the animal stays in hiding.
  var eye=g.Save();g.TranslateTransform(512,265);g.RotateTransform(9);g.ScaleTransform(.86f,.86f);
  // Layered fur follows the socket rather than leaving a disembodied eyeball.
  using(var coat=new GraphicsPath()){
   coat.AddEllipse(-184,-91,368,176);
   using(var fill=new LinearGradientBrush(new PointF(-100,-85),new PointF(96,83),Color.FromArgb(255,122,68,45),Color.FromArgb(255,45,35,49)))g.FillPath(fill,coat);
  }
  for(int tuft=0;tuft<48;tuft++){
   double a=tuft*Math.PI*2/48;
   float x=(float)Math.Cos(a)*169,y=(float)Math.Sin(a)*73;
   float dx=(float)Math.Cos(a)*(19+tuft%4*5),dy=(float)Math.Sin(a)*(17+tuft%3*5);
   Color fur=tuft%3==0?Color.FromArgb(255,137,84,56):tuft%3==1?Color.FromArgb(255,88,57,55):Color.FromArgb(255,63,44,57);
   using(var fill=new SolidBrush(fur))g.FillPolygon(fill,new PointF[]{new PointF(x-9,y-8),new PointF(x+dx-7,y+dy),new PointF(x+dx+6,y+dy-9),new PointF(x+9,y+8)});
   Stroke(g,Color.FromArgb(145,178,119,78),2,new PointF(x,y),new PointF(x+dx*.8f,y+dy*.8f));
  }
  for(int stripe=0;stripe<7;stripe++){
   float x=-141+stripe*46;
   using(var ink=new SolidBrush(Color.FromArgb(245,24,26,33)))g.FillPolygon(ink,new PointF[]{new PointF(x-18,-82+Math.Abs(stripe-3)*5),new PointF(x+8,-85+Math.Abs(stripe-3)*5),new PointF(x+25,-48),new PointF(x+10,-27)});
  }
  float blink=f==27?.55f:f==28?.12f:f==29?.55f:1;
  g.ScaleTransform(1,blink);
  using(var socket=new GraphicsPath()){
   socket.AddBezier(-174,-6,-92,-100,74,-101,171,12);
   socket.AddBezier(171,12,76,80,-80,77,-174,-6);
   using(var dark=new SolidBrush(Color.FromArgb(255,12,12,18)))g.FillPath(dark,socket);
  }
  using(var opening=new GraphicsPath()){
   opening.AddBezier(-154,-2,-64,-61,70,-67,151,9);
   opening.AddBezier(151,9,65,60,-63,57,-154,-2);
   using(var fill=new LinearGradientBrush(new PointF(0,-50),new PointF(0,54),Color.FromArgb(255,164,88,22),Color.FromArgb(255,232,181,49)))g.FillPath(fill,opening);
   var iris=g.Save();g.SetClip(opening);
   float focus=(float)Math.Sin(t)*7;
   using(var circle=new GraphicsPath()){
    circle.AddEllipse(focus-64,-68,128,136);
    using(var fill=new PathGradientBrush(circle)){fill.CenterPoint=new PointF(focus-11,-12);fill.CenterColor=Color.FromArgb(255,255,251,130);fill.SurroundColors=new Color[]{Color.FromArgb(255,206,128,17)};g.FillPath(fill,circle);}
   }
   for(int fiber=0;fiber<42;fiber++){
    double a=fiber*Math.PI*2/42;float r=36+fiber%4*5;
    Stroke(g,Color.FromArgb(115,136,76,15),2,new PointF(focus+(float)Math.Cos(a)*r,(float)Math.Sin(a)*r),new PointF(focus+(float)Math.Cos(a)*65,(float)Math.Sin(a)*65));
   }
   using(var pupil=new SolidBrush(Color.FromArgb(255,8,14,12)))g.FillPolygon(pupil,new PointF[]{new PointF(focus,-59),new PointF(focus+11,-7),new PointF(focus+4,26),new PointF(focus-2,56),new PointF(focus-10,4)});
   using(var gleam=new SolidBrush(Color.FromArgb(240,255,255,216)))g.FillEllipse(gleam,focus-34,-34,15,9);
   Stroke(g,Color.FromArgb(185,255,236,133),3,new PointF(focus+26,8),new PointF(focus+32,24));g.Restore(iris);
  }
  Stroke(g,Color.FromArgb(255,49,34,43),17,new PointF(-160,-16),new PointF(-89,-51),new PointF(-9,-59),new PointF(76,-45),new PointF(155,-3));
  Stroke(g,Color.FromArgb(235,119,82,60),4,new PointF(-145,-13),new PointF(-78,-43),new PointF(-5,-48),new PointF(73,-37),new PointF(143,-2));
  // Dark tiger stripes break up the brow instead of revealing a whole face.
  for(int stripe=0;stripe<5;stripe++){
   float x=-121+stripe*58;
   Stroke(g,Color.FromArgb(255,13,17,20),12,new PointF(x-14,-83+Math.Abs(stripe-2)*10),new PointF(x+9,-48+Math.Abs(stripe-2)*7));
  }
  g.Restore(eye);
  // Foliage surrounds the whole tilted eye, separated by a narrow dark opening.
  var bush=g.Save();g.TranslateTransform(512,265);g.RotateTransform(9);
   for(int leaf=0;leaf<27;leaf++){
    double a=leaf*Math.PI*2/27+Math.Sin(leaf*2.3)*.04;
    float x=(float)Math.Cos(a)*(182+leaf%3*5),y=(float)Math.Sin(a)*(94+leaf%3*4);
    var foliage=g.Save();g.TranslateTransform(x,y);g.RotateTransform((float)(a*180/Math.PI)+90+(float)Math.Sin(leaf*3)*18+(float)Math.Sin(t+leaf*1.7)*5);
    float size=.66f+leaf%4*.09f;g.ScaleTransform(size,size);
    using(var shape=new GraphicsPath()){
     if(leaf%3==0){
      // Broad five-lobed silhouette, visibly different from a simple oval.
      shape.AddPolygon(new PointF[]{new PointF(0,18),new PointF(-18,7),new PointF(-43,-3),new PointF(-26,-15),new PointF(-44,-39),new PointF(-17,-33),new PointF(0,-67),new PointF(17,-33),new PointF(44,-39),new PointF(26,-15),new PointF(43,-3),new PointF(18,7)});
     }else if(leaf%3==1){
      // Long sweeping grass blade, narrow with a sharply bent tip.
      shape.AddBezier(0,18,-16,-19,1,-59,37,-94);shape.AddBezier(37,-94,14,-50,17,-12,0,18);
     }else{
      // A fern sprig made of distinct paired leaflets with open gaps.
      shape.FillMode=FillMode.Winding;
      shape.AddPolygon(new PointF[]{new PointF(-2,18),new PointF(-2,-79),new PointF(2,-79),new PointF(2,18)});
      for(int pair=0;pair<6;pair++)for(int side=-1;side<=1;side+=2){
       float leafletY=3-pair*13,width=35-pair*4;
       shape.StartFigure();shape.AddBezier(0,leafletY,side*10,leafletY-14,side*width,leafletY-7,side*(width+5),leafletY-21);shape.AddBezier(side*(width+5),leafletY-21,side*(width+8),leafletY-2,side*9,leafletY+3,0,leafletY);shape.CloseFigure();
      }
     }
     Color light=leaf%5==0?Color.FromArgb(250,90,57,111):Color.FromArgb(250,60+leaf%3*8,89+leaf%4*7,43);
     using(var fill=new LinearGradientBrush(new PointF(-22,-35),new PointF(16,18),light,Color.FromArgb(250,17,34,26)))g.FillPath(fill,shape);
    }
    Stroke(g,Color.FromArgb(165,100,125,57),2,new PointF(-7,13),new PointF(-5,-9),new PointF(4,-37));
    if(leaf%3==0){Stroke(g,Color.FromArgb(150,127,149,72),2,new PointF(-5,-9),new PointF(-29,-28));Stroke(g,Color.FromArgb(150,127,149,72),2,new PointF(-5,-9),new PointF(29,-28));}
    g.Restore(foliage);
   }
  g.Restore(bush);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[WildstalkerArt]::Write($destination)
Write-Output "Created Wildstalker animation: $destination"
