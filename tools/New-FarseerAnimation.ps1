param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Restoration-Farseer-v11'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class FarseerArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Round;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static PointF Flow(double a,int stream){
  // Helical water spirits rise from the pool, curling around the talent.
  double p=Math.Max(0,Math.Min(1,a/(Math.PI*2)));
  // Mirrored swirls stay on opposite sides and converge at the same top point.
  float side=stream==0?-1:1;
  // Three alternating outside lobes, crossing through the icon between them.
  // Mirror the signed path so the second spirit starts from the opposite side.
  float enter=(float)Math.Min(1,p/.10),leave=(float)Math.Min(1,(1-p)/.10);
  float radius=Math.Min(enter,leave)*(float)Math.Sin(p*Math.PI*3)*270;
  float x=512+side*radius;
  float y=779-(float)p*526;
  return new PointF(x,y);
 }
 static void Current(Graphics g,double t,int stream,bool rear){
  double cycle=t/(Math.PI*2)%1;
  // Reset only beyond the top of the icon, with a soft emergence from the pool.
  double rise=Math.Min(1,cycle/.84);
  float strength=(float)(Math.Min(1,cycle/.08)*(cycle<.86?1:Math.Max(0,(1-cycle)/.14)));
  double heading=rise*Math.PI*2;
  var points=new PointF[48];
  for(int j=0;j<48;j++){
   double a=Math.Max(0,heading-j/47.0*2.8);
   points[j]=Flow(a,stream);
  }
  var state=g.Save();
  // Draw each complete path once, with no corner clipping or timed cut-off.
  for(int layer=0;layer<3;layer++)for(int j=0;j<47;j++){
   float p=j/47f,billow=.5f+(float)Math.Sin(p*Math.PI)*.6f;
   PointF a=points[j],b=points[j+1];
   a.X+=(float)Math.Sin(j*.32+t*2)*layer*5;a.Y+=layer*8;
   b.X+=(float)Math.Sin((j+1)*.32+t*2)*layer*5;b.Y+=layer*8;
   float fade=(1-p*.75f)*strength;
   Stroke(g,Color.FromArgb((int)(fade*25),36,141,245),49*billow,a,b);
   Stroke(g,Color.FromArgb((int)(fade*125),31,152+layer*18,223+layer*10),29*billow,a,b);
   Stroke(g,Color.FromArgb((int)(fade*160),137,242,255),9*billow,a,b);
  }
  for(int bead=0;bead<12;bead++){
   PointF p=points[bead*4];float size=3+bead%3*2;
   using(var foam=new SolidBrush(Color.FromArgb((int)(165*strength),209,255,255)))g.FillEllipse(foam,p.X-4,p.Y+bead%2*9,size,size*1.4f);
  }
  // The moving lead is an open water spiral, not a ball with a tail.
  PointF lead=points[0];var curl=new PointF[40];
  for(int j=0;j<40;j++){double a=j*.22+t;float r=4+j*.68f;curl[j]=new PointF(lead.X+(float)Math.Cos(a)*r,lead.Y+(float)Math.Sin(a)*r*.75f);}
  Stroke(g,Color.FromArgb((int)(180*strength),54,181,246),15,curl);Stroke(g,Color.FromArgb((int)(220*strength),185,255,255),4,curl);
  g.Restore(state);
 }
 public static void Write(string output){for(int frame=0;frame<36;frame++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  double t=frame*Math.PI*2/36;g.SmoothingMode=SmoothingMode.AntiAlias;
  // A water pool beneath the button; no stone platform, cloud or totems.
  using(var pool=new GraphicsPath()){
   pool.AddEllipse(286,718,452,122);
   using(var fill=new PathGradientBrush(pool)){fill.CenterPoint=new PointF(490,760);fill.CenterColor=Color.FromArgb(225,75,214,240);fill.SurroundColors=new Color[]{Color.FromArgb(25,18,84,168)};g.FillPath(fill,pool);}
  }
  for(int ripple=0;ripple<5;ripple++){
   float p=(float)((frame/36.0+ripple*.2)%1),w=70+p*370;
   using(var rim=new Pen(Color.FromArgb((int)((1-p)*145),160,246,255),3))g.DrawEllipse(rim,512-w/2,779-w*.12f,w,w*.24f);
  }
  // The talent remains submerged beneath an undulating water surface.
  float tide=412+(float)Math.Sin(t)*17;
  using(var flood=new GraphicsPath()){
   flood.AddBezier(329,tide,426,tide-22,586,tide+25,643,tide-3);
   flood.AddLine(643,tide-3,643,688);flood.AddLine(643,688,329,688);flood.CloseFigure();
   using(var water=new LinearGradientBrush(new PointF(512,tide-23),new PointF(512,688),Color.FromArgb(62,116,236,248),Color.FromArgb(139,17,112,190)))g.FillPath(water,flood);
  }
  for(int bubble=0;bubble<10;bubble++){
   float p=(float)((frame/36.0+bubble*.1)%1),x=352+bubble*29+(float)Math.Sin(t+bubble)*7,y=680-p*220;
   using(var rim=new Pen(Color.FromArgb((int)(Math.Sin(p*Math.PI)*150),187,255,251),2))g.DrawEllipse(rim,x,y,6+bubble%3*2,6+bubble%3*2);
  }
  // Sparse rain, with no cloud above the icon.
  for(int drop=0;drop<22;drop++){
   float p=(float)((frame/36.0*2+drop*.137)%1);
   float x=344+drop%11*29,y=310+p*382;
   int alpha=(int)(Math.Sin(p*Math.PI)*125);
   Stroke(g,Color.FromArgb(alpha,180,236,255),2,new PointF(x,y),new PointF(x-5,y+15));
  }
  // Visible rainfall across the talent face, safely inside its rank border.
  var rainState=g.Save();g.SetClip(new Rectangle(343,343,291,291));
  for(int drop=0;drop<34;drop++){
   float p=(float)((frame/36.0*3+drop*.173)%1);
   float x=351+drop%12*24+(float)Math.Sin(drop*2.7)*4,y=330+p*323;
   int alpha=(int)(125+Math.Sin(p*Math.PI)*85);
   Stroke(g,Color.FromArgb(alpha,188,244,255),drop%4==0?3:2,new PointF(x,y),new PointF(x-5,y+17+drop%3*3));
  }
  g.Restore(rainState);
  Current(g,t,0,false);Current(g,t,1,false);
  im.Save(Path.Combine(output,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[FarseerArt]::Write($destination)
Write-Output "Created Farseer animation: $destination"
