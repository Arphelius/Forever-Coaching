param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Survival-Ambush-v5'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SurvivalArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Bevel;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Trap(Graphics g,float x,float y,bool fire,double t){
  var state=g.Save();g.TranslateTransform(x,y);float scale=fire?1.45f:1.22f;g.ScaleTransform(scale,scale);
  using(var plate=new SolidBrush(Color.FromArgb(255,46,52,57)))g.FillEllipse(plate,-57,-13,114,42);
  using(var rim=new Pen(Color.FromArgb(255,141,145,136),6))g.DrawEllipse(rim,-57,-13,114,42);
  Stroke(g,Color.FromArgb(255,100,105,103),8,new PointF(-63,12),new PointF(63,12));
  if(fire){
   using(var heat=new GraphicsPath()){heat.AddEllipse(-77,-101,154,137);using(var b=new PathGradientBrush(heat)){b.CenterPoint=new PointF(0,-13);b.CenterColor=Color.FromArgb(90,255,116,17);b.SurroundColors=new Color[]{Color.FromArgb(0,255,49,0)};g.FillPath(b,heat);}}
   // Interleaved flame sheets: hot white roots, yellow bodies, thin red tips.
   for(int layer=0;layer<3;layer++)for(int flame=0;flame<7;flame++){
    float fx=-42+flame*14,phase=(float)(t*3+flame*1.7+layer*.6);
    float lean=(float)Math.Sin(phase)*15+(float)Math.Sin(t*2+flame)*7;
    float height=(55+flame%3*18+(float)Math.Sin(phase+1)*14)*(1-layer*.23f);
    float width=18-layer*4;
    using(var path=new GraphicsPath()){
     path.AddBezier(fx-width,3,fx-width-8,-height*.28f,fx+lean-width*.6f,-height*.58f,fx+lean+6,-height);
     path.AddBezier(fx+lean+6,-height,fx+lean+17,-height*.62f,fx+width,-height*.34f,fx+width,2);path.CloseFigure();
     Color root=layer==0?Color.FromArgb(185,255,87,6):layer==1?Color.FromArgb(220,255,200,39):Color.FromArgb(240,255,250,180);
     Color tip=layer==0?Color.FromArgb(25,224,42,4):layer==1?Color.FromArgb(95,255,107,9):Color.FromArgb(100,255,199,48);
     using(var fill=new LinearGradientBrush(new PointF(fx,3),new PointF(fx,-height),root,tip))g.FillPath(fill,path);
    }
   }
   for(int ember=0;ember<13;ember++){
    float p=(float)((t/(Math.PI*2)*2+ember*.137)%1),ex=-45+ember%7*14+(float)Math.Sin(t*2+ember)*p*17,ey=-12-p*(98+ember%3*17);
    Stroke(g,Color.FromArgb((int)(Math.Sin(p*Math.PI)*210),255,174+ember%3*25,42),ember%3==0?3:2,new PointF(ex,ey),new PointF(ex+2,ey-5));
   }
  }else{
   using(var frost=new SolidBrush(Color.FromArgb(100,113,203,244)))g.FillEllipse(frost,-78,-12,156,55);
   // Asymmetric glacier slabs surround the trap with substantial shaded faces.
   for(int crystal=0;crystal<7;crystal++){
    float cx=-65+crystal*21,h=crystal==3?111:37+crystal%3*23;
    float lean=crystal<3?-12:crystal>3?14:5;
    PointF tip=new PointF(cx+lean,-h),ridge=new PointF(cx-3,-h+23);
    Poly(g,Color.FromArgb(245,50,114,164),new PointF(cx-17,12),new PointF(cx-24,-h*.35f),tip,new PointF(cx+17,-h*.62f),new PointF(cx+21,10));
    Poly(g,Color.FromArgb(240,123,211,237),new PointF(cx-17,12),ridge,tip,new PointF(cx-24,-h*.35f));
    Poly(g,Color.FromArgb(245,193,241,250),tip,ridge,new PointF(cx+4,9),new PointF(cx+17,-h*.62f));
    Stroke(g,Color.FromArgb(255,236,255,255),2,new PointF(cx-16,4),ridge,tip);
    Stroke(g,Color.FromArgb(170,80,163,204),2,new PointF(cx+10,-17),new PointF(cx+3,-h*.4f),new PointF(cx+10,-h*.54f));
   }
   for(int mist=0;mist<12;mist++){
    float p=(float)((t/(Math.PI*2)+mist/12.0)%1),mx=(float)Math.Sin(mist*2.7+t)* (30+p*31),my=3+p*77;
    float width=40+p*45,height=18+p*16;
    using(var haze=new GraphicsPath()){haze.AddEllipse(mx-width/2,my-height/2,width,height);using(var b=new PathGradientBrush(haze)){b.CenterColor=Color.FromArgb((int)((1-p)*90),181,228,244);b.SurroundColors=new Color[]{Color.FromArgb(0,178,238,250)};g.FillPath(b,haze);}}
   }
   for(int spark=0;spark<6;spark++){float p=(float)((t/(Math.PI*2)+spark/6.0)%1),sx=(float)Math.Sin(spark*3+t)*45,sy=-p*87;Stroke(g,Color.FromArgb((int)((1-p)*180),167,237,255),2,new PointF(sx-3,sy),new PointF(sx+3,sy));}
  }
  g.Restore(state);
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // Two open steel jaws fully surround the talent; their teeth face inward.
  var jaws=g.Save();g.ExcludeClip(new Rectangle(653,656,97,94));
  for(int half=0;half<2;half++){
   using(var shadow=new Pen(Color.FromArgb(255,29,35,39),25))g.DrawArc(shadow,260,260,504,504,half*180+8,164);
   using(var metal=new Pen(Color.FromArgb(255,128,139,139),13))g.DrawArc(metal,260,260,504,504,half*180+8,164);
   using(var edge=new Pen(Color.FromArgb(255,205,207,183),3))g.DrawArc(edge,253,253,518,518,half*180+8,164);
  }
  for(int tooth=0;tooth<24;tooth++){
   double a=(tooth+.5)*Math.PI/12;float cx=512+(float)Math.Cos(a)*251,cy=512+(float)Math.Sin(a)*251;
   float tx=512+(float)Math.Cos(a)*215,ty=512+(float)Math.Sin(a)*215;
   var p=new PointF[]{new PointF(cx-(float)Math.Sin(a)*12,cy+(float)Math.Cos(a)*12),new PointF(tx,ty),new PointF(cx+(float)Math.Sin(a)*12,cy-(float)Math.Cos(a)*12)};
   Poly(g,Color.FromArgb(255,165,175,168),p);Stroke(g,Color.FromArgb(255,220,223,199),2,new PointF[]{p[0],p[1]});
  }
  g.Restore(jaws);
  for(int side=-1;side<=1;side+=2){using(var hinge=new SolidBrush(Color.FromArgb(255,88,99,101)))g.FillEllipse(hinge,512+side*255-18,494,36,36);using(var pin=new SolidBrush(Color.FromArgb(255,208,205,177)))g.FillEllipse(pin,512+side*255-6,506,12,12);}
  Trap(g,235,738,true,t);Trap(g,795,738,false,t);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[SurvivalArt]::Write($destination)
Write-Output "Created Survival ambush: $destination"
