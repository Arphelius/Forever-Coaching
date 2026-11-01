param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Frost-Frozen-v18'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FrozenArt {
 static void Line(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;
  // The atlas now represents only the actual spell face, with no outer margin.
  g.ScaleTransform(1024f/650,1024f/650);g.TranslateTransform(-187,-187);
  g.SetClip(new Rectangle(309,309,406,406));
  // A continuous sheet of fractured ice lies over the artwork itself.
  var surface=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  g.ExcludeClip(new Rectangle(627,651,110,83));
  // Uneven rime freezes the artwork, with clear areas between cloudy patches.
  for(int patch=0;patch<60;patch++){
   float x=310+(patch*97)%405,y=310+(patch*163)%405,r=28+(patch%5)*14;
   using(var p=new GraphicsPath()){
    p.AddEllipse(x-r,y-r,r*2,r*2);
    using(var frost=new PathGradientBrush(p)){
     frost.CenterColor=Color.FromArgb(44+(patch%4)*10,205,235,246);frost.SurroundColors=new Color[]{Color.Transparent};g.FillPath(frost,p);
    }
   }
  }
  // Tiny fixed crystals form a granular frozen texture, not a solid blue panel.
  var grain=new Random(714);
  for(int crystal=0;crystal<1550;crystal++){
   int x=grain.Next(310,715),y=grain.Next(310,715);
   int edge=Math.Min(Math.Min(x-309,715-x),Math.Min(y-309,715-y));
   int a=edge<60?grain.Next(55,135):grain.Next(20,60);
   using(var speck=new SolidBrush(Color.FromArgb(a,225,247,255)))g.FillEllipse(speck,x,y,1+grain.Next(3),1+grain.Next(3));
  }
  PointF[][] cracks=new PointF[][]{
   new PointF[]{new PointF(513,309),new PointF(491,377),new PointF(506,412),new PointF(466,468),new PointF(478,510),new PointF(439,553)},
   new PointF[]{new PointF(466,468),new PointF(403,486),new PointF(377,534),new PointF(309,586)},
   new PointF[]{new PointF(466,468),new PointF(532,491),new PointF(549,539),new PointF(582,567),new PointF(647,542),new PointF(715,502)},
   new PointF[]{new PointF(582,567),new PointF(560,608),new PointF(570,648),new PointF(516,715)},
   new PointF[]{new PointF(491,377),new PointF(451,367),new PointF(426,337)},
   new PointF[]{new PointF(377,534),new PointF(359,516),new PointF(333,521)},
   new PointF[]{new PointF(560,608),new PointF(520,617),new PointF(506,645)},
   new PointF[]{new PointF(506,412),new PointF(550,398),new PointF(573,361),new PointF(609,345)},
   new PointF[]{new PointF(647,542),new PointF(639,505),new PointF(666,478),new PointF(658,450)},
   new PointF[]{new PointF(439,553),new PointF(421,592),new PointF(438,624),new PointF(407,660)},
   new PointF[]{new PointF(403,486),new PointF(379,455),new PointF(387,423)}
  };
  foreach(var crack in cracks){Line(g,Color.FromArgb(145,32,83,129),6,crack);Line(g,Color.FromArgb(230,232,252,255),2.7f,crack);}
  // Fine fernlike frost grows inward from the frozen corners.
  for(int corner=0;corner<4;corner++){
   var fern=g.Save();g.TranslateTransform(corner%2==0?313:711,corner<2?313:711);g.ScaleTransform(corner%2==0?1:-1,corner<2?1:-1);
   for(int stem=0;stem<4;stem++){
    float dx=18+stem*15,dy=87-stem*16;
    Line(g,Color.FromArgb(155,227,249,255),2,new PointF(0,0),new PointF(dx,dy));
    for(int twig=1;twig<5;twig++){
     float p=twig/5f,x=dx*p,y=dy*p;
     Line(g,Color.FromArgb(135,218,245,255),1.5f,new PointF(x,y),new PointF(x-10,y+3),new PointF(x-16,y-3));
     Line(g,Color.FromArgb(135,218,245,255),1.5f,new PointF(x,y),new PointF(x+10,y-4),new PointF(x+13,y-12));
    }
   }
   g.Restore(fern);
  }
  g.Restore(surface);
  // Translucent ice rim hugs the spell instead of obscuring its center.
  var clipped=g.Save();g.ExcludeClip(new Rectangle(627,651,110,83));
  for(int edge=0;edge<4;edge++)for(int crust=0;crust<18;crust++){
   var rim=g.Save();g.TranslateTransform(512,512);g.RotateTransform(edge*90);g.TranslateTransform(-512,-512);
   float x=311+crust*23,y=309+(float)Math.Sin(crust*2.7)*4;
   Poly(g,Color.FromArgb(140,174,225,247),new PointF(x-9,y+8),new PointF(x-12,y-6),new PointF(x+3,y-11),new PointF(x+15,y-3),new PointF(x+11,y+12));
   g.Restore(rim);
  }
  for(int frost=0;frost<22;frost++){
   float y=331+frost*16,x=frost%2==0?315:709,sign=frost%2==0?1:-1,len=12+frost%4*6;
   Line(g,Color.FromArgb(110,190,235,255),2,new PointF(x,y),new PointF(x+sign*len,y-10),new PointF(x+sign*(len+8),y-22));
   Line(g,Color.FromArgb(95,190,235,255),2,new PointF(x+sign*len,y-10),new PointF(x+sign*(len+12),y-8));
  }
  g.Restore(clipped);
  // Faceted icicles hang from the entire top edge, longer at the corners.
  for(int ice=0;ice<13;ice++){
   float x=307+ice*34,w=13+ice%3*3,h=ice==0||ice==12?92:30+(ice*29)%58;
   Poly(g,Color.FromArgb(210,74,160,219),new PointF(x-w,300),new PointF(x+w,303),new PointF(x+3,314+h));
   Poly(g,Color.FromArgb(205,178,232,255),new PointF(x-w,300),new PointF(x,305),new PointF(x+3,314+h));
   Line(g,Color.FromArgb(230,240,253,255),2,new PointF(x-w+3,304),new PointF(x+2,309+h));
  }
  for(int glint=0;glint<6;glint++){
   float x=315+glint*78,y=glint%2==0?309:335;
   int a=(int)(Math.Pow(Math.Max(0,Math.Sin(t+glint)),8)*210);
   Line(g,Color.FromArgb(a,232,254,255),2,new PointF(x-7,y),new PointF(x+7,y));
   Line(g,Color.FromArgb(a,232,254,255),2,new PointF(x,y-9),new PointF(x,y+9));
  }
  // Additional ice teeth cling to the sides and underside of the artwork.
  var outer=g.Save();g.ExcludeClip(new Rectangle(627,651,110,83));
  for(int edge=1;edge<4;edge++){
   var sideState=g.Save();g.TranslateTransform(512,512);g.RotateTransform(edge*90);g.TranslateTransform(-512,-512);
   for(int ice=0;ice<8;ice++){
    float x=330+ice*51,w=9+ice%3*3,h=23+(ice*19+edge*11)%37;
    Poly(g,Color.FromArgb(175,104,191,231),new PointF(x-w,315),new PointF(x+w,312),new PointF(x+4,309-h));
    Poly(g,Color.FromArgb(195,218,247,255),new PointF(x-w,315),new PointF(x,312),new PointF(x+4,309-h));
   }
   g.Restore(sideState);
  }
  g.Restore(outer);
  // Cold vapor rolls down the face of the icon and joins the escaping mist.
  var faceMist=g.Save();g.SetClip(new Rectangle(235,235,554,495));
  g.ExcludeClip(new Rectangle(627,651,110,83));
  for(int lane=0;lane<9;lane++)for(int puff=0;puff<4;puff++){
   float age=(float)((f/36.0+puff*.241+lane*.079)%1);
   float x=326+lane*45+(float)Math.Sin(t+lane+age*5)*10;
   float y=307+age*423;
   float fade=(float)Math.Sin(age*Math.PI);
   using(var cloud=new GraphicsPath()){
    cloud.AddEllipse(x-25,y-38,50,76);
    using(var fog=new PathGradientBrush(cloud)){
     fog.CenterColor=Color.FromArgb((int)(fade*100),173,222,242);
     fog.SurroundColors=new Color[]{Color.Transparent};g.FillPath(fog,cloud);
    }
   }
  }
  g.Restore(faceMist);
  // A soft fringe of moving frost surrounds the top and sides of the spell.
  var fringe=g.Save();g.ResetClip();g.ExcludeClip(new Rectangle(627,651,110,83));
  for(int edge=0;edge<3;edge++)for(int wisp=0;wisp<18;wisp++){
   float age=(float)((f/36.0+wisp*.0837+edge*.173)%1);
   float wave=(float)Math.Sin(t*2+wisp*1.7+edge);
   float x=edge==0?298+age*428:(edge==1?283:741)+wave*17;
   float y=edge==0?283+wave*16:298+age*410;
   float rx=edge==0?45:43,ry=edge==0?43:49;
   float fade=(float)Math.Sin(age*Math.PI);
   using(var cloud=new GraphicsPath()){
    cloud.AddEllipse(x-rx,y-ry,rx*2,ry*2);
    using(var fog=new PathGradientBrush(cloud)){
     fog.CenterColor=Color.FromArgb((int)(fade*160),205,242,255);
     fog.SurroundColors=new Color[]{Color.Transparent};g.FillPath(fog,cloud);
    }
   }
  }
  g.Restore(fringe);
  // Only vapor may escape the spell face; solid ice stays clipped inside it.
  g.ResetClip();
  // Connected curtains of cold vapor descend first, then roll outward slowly.
  for(int lane=0;lane<12;lane++)for(int puff=0;puff<5;puff++){
   float age=(float)((f/36.0+puff*.193+lane*.061)%1);
   float spread=age*age*age;
   float origin=354+lane*27,side=lane<6?-1:1;
   float curl=(float)Math.Sin(t*2+lane*.93+puff*1.7);
   float x=origin+side*spread*134+curl*(3+age*7);
   // A continuous curved descent: no clamped height or horizontal shelf.
   float y=674+112*(float)(1-Math.Exp(-2.2*age))+age*15+(float)Math.Sin(t+lane)*age*5;
   float fade=(float)(Math.Sin(Math.Min(1,age*6)*Math.PI*.5)*Math.Pow(1-age,1.15));
   float rx=12+age*18+curl*2,ry=20+age*4;
   using(var cloud=new GraphicsPath()){
    cloud.AddEllipse(x-rx,y-ry,rx*2,ry*2);
    using(var fog=new PathGradientBrush(cloud)){
     fog.CenterColor=Color.FromArgb((int)(fade*(165+22*Math.Sin(t+lane))),205,239,253);
     fog.SurroundColors=new Color[]{Color.Transparent};g.FillPath(fog,cloud);
    }
   }
  }
  // Small melt droplets catch the light below the longer icicles.
  g.SetClip(new Rectangle(309,309,406,406));
  for(int drop=0;drop<5;drop++){
   float age=(float)((f/36.0+drop*.213)%1),x=315+drop*96,y=381+age*73;
   using(var water=new SolidBrush(Color.FromArgb((int)(Math.Sin(age*Math.PI)*125),205,244,255)))g.FillEllipse(water,x,y,3,6);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination)|Out-Null
[FrozenArt]::Write($destination)
