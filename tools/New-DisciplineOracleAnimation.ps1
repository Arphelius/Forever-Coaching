param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Discipline-Oracle-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class OracleArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Glow(Graphics g,float x,float y,float rx,float ry,Color color){using(var p=new GraphicsPath()){p.AddEllipse(x-rx,y-ry,rx*2,ry*2);using(var b=new PathGradientBrush(p)){b.CenterColor=color;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,p);}}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;float pulse=(float)(.5+.5*Math.Sin(t));
  // Oracle radiance fans upward above the eye, with faint prismatic accents.
  var radiancePosition=g.Save();g.TranslateTransform(0,25);
  for(int ray=0;ray<34;ray++){
   float d=(ray-16.5f)*.5f,x=512+d*19+(float)Math.Sin(t+ray*.31)*6,top=38+Math.Abs(d)*9+(ray*19)%41;
   using(var beam=new GraphicsPath()){
    beam.AddPolygon(new PointF[]{new PointF(512+d*4-5,247),new PointF(x,top),new PointF(x+4,top+45),new PointF(512+d*4+5,247)});
    int softness=(int)(32+23*(.5+.5*Math.Sin(t+ray*.41)));
    Color c=ray%5==0?Color.FromArgb(softness,119,224,255):ray%5==1?Color.FromArgb(softness,225,142,245):ray%5==2?Color.FromArgb(softness,166,247,175):ray%5==3?Color.FromArgb(softness,255,173,172):Color.FromArgb(softness+10,255,227,135);
    using(var b=new LinearGradientBrush(new PointF(512,247),new PointF(512,70),c,Color.Transparent))g.FillPath(b,beam);
    float travel=(float)((f/36.0+ray*.117)%1);
    float sx=512+d*4+(x-512-d*4)*travel,sy=247+(top-247)*travel;
    int intensity=(int)(Math.Sin(travel*Math.PI)*30);
    Glow(g,sx,sy,13,30,Color.FromArgb(intensity,c.R,c.G,c.B));
   }
  }
  // Broad colored veils softly roll upward, joining the finer radiant rays.
  for(int veil=0;veil<7;veil++){
   float x=420+veil*30,wave=(float)Math.Sin(t+veil*.8)*15;
   using(var ribbon=new GraphicsPath()){
    ribbon.AddBezier(494+veil*6,263,x-25+wave,201,x+wave,120,x-10,69);
    ribbon.AddBezier(x-10,69,x+35+wave,139,x+28-wave,207,512+veil*5,263);ribbon.CloseFigure();
    Color color=veil%3==0?Color.FromArgb(34,115,222,255):veil%3==1?Color.FromArgb(34,239,158,232):Color.FromArgb(40,255,228,128);
    using(var fill=new LinearGradientBrush(new PointF(512,263),new PointF(512,69),color,Color.Transparent))g.FillPath(fill,ribbon);
   }
  }
  g.Restore(radiancePosition);
  // Power Word: Shield is a transparent curved shell around the talent.
  var shellState=g.Save();g.ExcludeClip(new Rectangle(616,650,145,117));
  float swell=pulse;
  RectangleF shell=new RectangleF(309-swell,309-swell,406+swell*2,406+swell*2);
  using(var shape=new GraphicsPath()){
   shape.AddEllipse(shell);
   using(var b=new PathGradientBrush(shape)){b.CenterColor=Color.Transparent;b.SurroundColors=new Color[]{Color.FromArgb(19,255,229,143)};g.FillPath(b,shape);}
   // Layered diffuse gold recreates the spell halo without a solid white ring.
   using(var haze=new Pen(Color.FromArgb((int)(15+pulse*15),255,213,66),56))g.DrawPath(haze,shape);
   using(var glow=new Pen(Color.FromArgb((int)(27+pulse*24),255,226,100),36))g.DrawPath(glow,shape);
   using(var core=new Pen(Color.FromArgb((int)(55+pulse*45),255,237,149),19))g.DrawPath(core,shape);
   using(var edge=new Pen(Color.FromArgb((int)(80+pulse*70),255,249,207),6))g.DrawPath(edge,shape);
  }
  // Translucent spell ripples sweep down the shield face and brighten its edges.
  var ripples=g.Save();
  using(var round=new GraphicsPath()){round.AddEllipse(shell);g.SetClip(round);}
  g.ExcludeClip(new Rectangle(616,650,145,117));
  for(int ripple=0;ripple<3;ripple++){
   float age=(float)((f/36.0+ripple*.3333)%1),y=740-age*450;
   using(var wave=new GraphicsPath()){
    wave.AddBezier(304,y-14,415,y+32,610,y+32,720,y-14);
    using(var blur=new Pen(Color.FromArgb((int)(Math.Sin(age*Math.PI)*26),255,238,160),24))g.DrawPath(blur,wave);
    using(var line=new Pen(Color.FromArgb((int)(Math.Sin(age*Math.PI)*85),255,247,202),3))g.DrawPath(line,wave);
   }
  }
  g.Restore(ripples);
  g.Restore(shellState);
  // A luminous almond eye, with a golden iris and dark center.
  var eyeSize=g.Save();g.TranslateTransform(512,272);g.ScaleTransform(.72f,.72f);g.TranslateTransform(-512,-247);
  Glow(g,512,246,162,88,Color.FromArgb(150+(int)(pulse*35),255,247,216));
  using(var eye=new GraphicsPath()){
   eye.AddBezier(377,247,444,167,576,167,647,247);
   eye.AddBezier(647,247,570,302,445,302,377,247);eye.CloseFigure();
   using(var fill=new LinearGradientBrush(new PointF(512,190),new PointF(512,289),Color.FromArgb(28,255,253,221),Color.FromArgb(0,255,213,117)))g.FillPath(fill,eye);
   using(var outer=new Pen(Color.FromArgb(65,255,205,76),16))g.DrawPath(outer,eye);
   using(var edge=new Pen(Color.FromArgb(240,255,254,239),7))g.DrawPath(edge,eye);
  }
  // A broken radiant iris is constructed from light rather than an eyeball.
  Glow(g,512,247,45,45,Color.FromArgb(155,255,224,103));
  for(int segment=0;segment<8;segment++){
   using(var ring=new Pen(segment%3==0?Color.FromArgb(235,184,238,255):Color.FromArgb(245,255,245,175),6))g.DrawArc(ring,482,217,60,60,segment*45,30);
  }
  for(int notch=0;notch<12;notch++){
   double a=notch*Math.PI*2/12+t*.04;
   Stroke(g,Color.FromArgb(220,255,252,212),3,new PointF(512+(float)Math.Cos(a)*27,247+(float)Math.Sin(a)*27),new PointF(512+(float)Math.Cos(a)*34,247+(float)Math.Sin(a)*34));
  }
  Glow(g,512,247,17,17,Color.FromArgb(145,255,247,203));
  // Slowly flowing prismatic veils create the suggestion of an eye around an orb.
  Color[] prism=new Color[]{Color.FromArgb(160,255,219,128),Color.FromArgb(145,165,240,255),Color.FromArgb(135,207,177,255),Color.FromArgb(140,255,178,208),Color.FromArgb(140,205,255,191),Color.FromArgb(170,255,248,196)};
  for(int veil=0;veil<18;veil++){
   float wave=(float)Math.Sin(t+veil*.71),span=105+veil%4*11;
   float arch=29+veil%5*7+wave*5,side=veil%2==0?-1:1;
   using(var ribbon=new GraphicsPath()){
    ribbon.AddBezier(512-span,247+wave*5,456,247+side*arch,566,247+side*arch,512+span,247-wave*4);
    using(var haze=new Pen(Color.FromArgb(24,prism[veil%6]),12))g.DrawPath(haze,ribbon);
    using(var light=new Pen(Color.FromArgb(185,(prism[veil%6].R+255)/2,(prism[veil%6].G+255)/2,(prism[veil%6].B+255)/2),3+veil%3))g.DrawPath(light,ribbon);
   }
  }
  for(int ring=0;ring<6;ring++){
   float r=21+ring*4;
   using(var light=new Pen(prism[ring],2.5f))g.DrawArc(light,512-r,247-r,r*2,r*2,(float)(t*180/Math.PI)+ring*58,112);
  }
  // Fine lashes and a small radiant crown reference the Oracle silhouette.
  for(int side=-1;side<=1;side+=2)for(int lash=0;lash<0;lash++){
   float x=512+side*(73+lash*19),y=226+lash*5;
   Stroke(g,Color.FromArgb(185,255,233,167),3,new PointF(x,y),new PointF(x+side*(18+lash*4),y-20+lash*3));
  }
  Stroke(g,Color.FromArgb(195,255,225,133),4,new PointF(487,190),new PointF(484,151),new PointF(503,170),new PointF(512,127),new PointF(521,170),new PointF(540,151),new PointF(537,190));
  g.Restore(eyeSize);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[OracleArt]::Write($destination)
