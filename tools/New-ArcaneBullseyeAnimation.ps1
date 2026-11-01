param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Marksmanship-Sentinel-v6'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class ArcaneBullseye {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Bevel;g.DrawLines(pen,p);}}
 static void Arrow(Graphics g,float x,float y,double approach,float scale,double t){
  var state=g.Save();g.TranslateTransform(x,y);g.RotateTransform((float)(approach*180/Math.PI)+180);g.ScaleTransform(scale,scale);
  Stroke(g,Color.FromArgb(55,161,93,249),24,new PointF(-173,0),new PointF(-9,0));
  Stroke(g,Color.FromArgb(240,156,108,241),10,new PointF(-165,0),new PointF(0,0));
  Stroke(g,Color.FromArgb(255,237,220,255),4,new PointF(-159,-1),new PointF(0,-1));
  var head=new PointF[]{new PointF(0,0),new PointF(-44,-23),new PointF(-31,0),new PointF(-44,23)};
  using(var fill=new SolidBrush(Color.FromArgb(250,206,163,255)))g.FillPolygon(fill,head);
  Stroke(g,Color.FromArgb(255,255,237,255),3,new PointF(-33,-15),new PointF(-7,0),new PointF(-33,15));
  Stroke(g,Color.FromArgb(235,177,128,255),8,new PointF(-163,-21),new PointF(-135,0),new PointF(-163,21));
  for(int ribbon=0;ribbon<2;ribbon++){
   var p=new PointF[20];for(int j=0;j<20;j++)p[j]=new PointF(-168+j*7, (float)Math.Sin(j*.65-t*3+ribbon*Math.PI)*8);
   Stroke(g,Color.FromArgb(130,199,152,255),3,p);
  }
  g.Restore(state);
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=f*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  float lockIn=f<8?1-f/8f:0,radius=247+lockIn*39;
  // Segmented targeting rings lock inward, keeping the talent face open.
  for(int ring=0;ring<2;ring++)for(int arc=0;arc<4;arc++){
   float r=radius+ring*33,angle=arc*90+12+(ring==0?1:-1)*(float)Math.Sin(t)*7;
   using(var glow=new Pen(Color.FromArgb(25,229,35,45),18))g.DrawArc(glow,512-r,512-r,r*2,r*2,angle,57);
   using(var metal=new Pen(ring==0?Color.FromArgb(235,222,43,45):Color.FromArgb(160,159,27,43),ring==0?6:4))g.DrawArc(metal,512-r,512-r,r*2,r*2,angle,57);
  }
  // Four substantial inward-facing sights emphasize the locked target.
  for(int side=0;side<4;side++){
   var state=g.Save();g.TranslateTransform(512,512);g.RotateTransform(side*90);
   float y=-201-lockIn*50;
   Stroke(g,Color.FromArgb(255,231,52,48),8,new PointF(-40,y-26),new PointF(0,y),new PointF(40,y-26));
   Stroke(g,Color.FromArgb(200,188,37,55),5,new PointF(0,y-34),new PointF(0,y-82));
   g.Restore(state);
  }
  // Clear archery bullseye, centered precisely on every arrow's impact point.
  for(int ring=0;ring<4;ring++){
   float r=16+ring*37;
   using(var glow=new Pen(Color.FromArgb(28,235,32,38),16))g.DrawEllipse(glow,512-r,512-r,r*2,r*2);
   using(var target=new Pen(Color.FromArgb(220,238,48,45),ring==0?6:8))g.DrawEllipse(target,512-r,512-r,r*2,r*2);
  }
  // Arcane runes orbit outside the target, not over the rank label.
  for(int rune=0;rune<8;rune++){
   double a=rune*Math.PI/4+t*.12;float x=512+(float)Math.Cos(a)*298,y=512+(float)Math.Sin(a)*298;
   var state=g.Save();g.TranslateTransform(x,y);g.RotateTransform((float)(a*180/Math.PI)+90);
   Stroke(g,Color.FromArgb(45,174,147,255),3,new PointF(-8,9),new PointF(0,-11),new PointF(9,9),new PointF(-8,9));
   Stroke(g,Color.FromArgb(40,221,202,255),2,new PointF(0,-3),new PointF(0,15));g.Restore(state);
  }
  // Arcane arrows fly into the open bullseye; no persistent central red mark.
  int shot=f/12,beat=f%12;
  double approach=shot==0?Math.PI:shot==1?-.65:2.25;
  if(beat<3){
   float p=beat/2f,remaining=(1-p)*371;
   float x=512+(float)Math.Cos(approach)*remaining,y=512+(float)Math.Sin(approach)*remaining;
   if(beat<2)Arrow(g,x,y,approach,1.5f,t);
  }
  // Landed arrows remain planted in the talent until the loop restarts.
  for(int landed=0;landed<3;landed++)if(f>=landed*12+2){double a=landed==0?Math.PI:landed==1?-.65:2.25;Arrow(g,512,512,a,1.1f,t);}
  if(beat>=2&&beat<6){
   float fade=(6-beat)/4f,spread=37+(beat-2)*29;
   using(var burst=new GraphicsPath()){burst.AddEllipse(512-spread,512-spread,spread*2,spread*2);using(var fill=new PathGradientBrush(burst)){fill.CenterColor=Color.FromArgb((int)(fade*150),225,189,255);fill.SurroundColors=new Color[]{Color.FromArgb(0,144,67,233)};g.FillPath(fill,burst);}}
   using(var ring=new Pen(Color.FromArgb((int)(fade*185),198,148,255),6))g.DrawEllipse(ring,512-spread,512-spread,spread*2,spread*2);
   for(int ray=0;ray<12;ray++){
    double a=ray*Math.PI/6+shot*.7;
    Stroke(g,Color.FromArgb((int)(fade*225),224,191,255),5,new PointF(512+(float)Math.Cos(a)*13,512+(float)Math.Sin(a)*13),new PointF(512+(float)Math.Cos(a)*spread,512+(float)Math.Sin(a)*spread));
   }
  }
  // Three loaded arcane charges fill beneath the icon and flash on release.
  for(int charge=0;charge<3;charge++){
   float x=452+charge*60,y=803;bool loaded=f>=charge*7&&f<29;
   var shape=new PointF[]{new PointF(x,y-19),new PointF(x+14,y),new PointF(x,y+19),new PointF(x-14,y),new PointF(x,y-19)};
   using(var fill=new SolidBrush(loaded?Color.FromArgb(45,148,99,235):Color.FromArgb(25,46,49,74)))g.FillPolygon(fill,shape);
   Stroke(g,Color.FromArgb(45,213,196,255),2,shape);
   if(loaded)Stroke(g,Color.FromArgb(40,242,229,255),2,new PointF(x,y-9),new PointF(x,y+9));
  }
  float progress=(f%12)/12f;double sweep=-Math.PI/2+progress*Math.PI*2;
  for(int mote=0;mote<12;mote++){
   double a=sweep-mote*.045;float x=512+(float)Math.Cos(a)*266,y=512+(float)Math.Sin(a)*266;
   using(var spark=new SolidBrush(Color.FromArgb(45-mote*3,188,158,255)))g.FillEllipse(spark,x-2,y-2,4,4);
  }
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[ArcaneBullseye]::Write($destination)
Write-Output "Created arcane bullseye: $destination"
