param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Arcane-Spellslinger-v22'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class SpellslingerArt {
 static void Stroke(Graphics g,Color c,float w,params PointF[] p){using(var pen=new Pen(c,w)){pen.LineJoin=LineJoin.Bevel;pen.StartCap=pen.EndCap=LineCap.Round;g.DrawLines(pen,p);}}
 static void Poly(Graphics g,Color c,params PointF[] p){using(var b=new SolidBrush(c))g.FillPolygon(b,p);}
 static void Rune(Graphics g,int form,float opacity){
  Color ink=Color.FromArgb((int)(opacity*255),250,147,255);
  switch(form%8){
   case 0:Stroke(g,ink,3,new PointF(-7,10),new PointF(-7,-11),new PointF(7,-5),new PointF(-7,1));break;
   case 1:Stroke(g,ink,3,new PointF(-8,-9),new PointF(0,-14),new PointF(8,-9),new PointF(0,0),new PointF(0,12));break;
   case 2:Stroke(g,ink,3,new PointF(-8,-11),new PointF(7,-11),new PointF(-5,3),new PointF(8,3),new PointF(8,11));break;
   case 3:Stroke(g,ink,3,new PointF(-7,9),new PointF(0,-12),new PointF(8,9),new PointF(-7,9));Stroke(g,ink,2,new PointF(0,-3),new PointF(0,14));break;
   case 4:Stroke(g,ink,3,new PointF(-8,-10),new PointF(-8,9),new PointF(7,9),new PointF(7,-10));Stroke(g,ink,2,new PointF(-3,-2),new PointF(11,-2));break;
   case 5:Stroke(g,ink,3,new PointF(-8,-9),new PointF(7,2),new PointF(-7,11));Stroke(g,ink,2,new PointF(-2,-13),new PointF(-2,13));break;
   case 6:Stroke(g,ink,3,new PointF(7,-11),new PointF(-7,-1),new PointF(7,8));Stroke(g,ink,2,new PointF(-8,-10),new PointF(7,-10));break;
   default:Stroke(g,ink,3,new PointF(-8,10),new PointF(-8,-10),new PointF(0,-3),new PointF(8,-10),new PointF(8,10));break;
  }
 }
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;
  double runeRotation=f/36.0*Math.PI*.5;
  var surface=g.Save();g.ExcludeClip(new Rectangle(653,655,100,94));
  // Fine concentric magic seals and handwritten angular rune bands.
  foreach(float r in new float[]{208,247}){
   using(var halo=new Pen(Color.FromArgb(60,217,65,255),15))g.DrawEllipse(halo,512-r,512-r,r*2,r*2);
   using(var line=new Pen(Color.FromArgb(250,245,154,255),3.5f))g.DrawEllipse(line,512-r,512-r,r*2,r*2);
  }
  for(int rune=0;rune<32;rune++){
   double a=rune*Math.PI/16+runeRotation;
   var glyph=g.Save();g.TranslateTransform(512+(float)Math.Cos(a)*228,512+(float)Math.Sin(a)*228);g.RotateTransform((float)(a*180/Math.PI)+90);
   float charge=.78f+.22f*(float)Math.Sin(f*Math.PI/9-rune*Math.PI/4);
   Rune(g,rune,charge);g.Restore(glyph);
  }
  // Crossing radial sigil strokes stay outside the clear talent center.
  for(int axis=0;axis<4;axis++){
   double a=axis*Math.PI/2+runeRotation;
   Stroke(g,Color.FromArgb(220,244,133,255),3,new PointF(512+(float)Math.Cos(a)*201,512+(float)Math.Sin(a)*201),new PointF(512+(float)Math.Cos(a)*270,512+(float)Math.Sin(a)*270));
   double b=a+.11;
   Stroke(g,Color.FromArgb(165,242,145,255),2,new PointF(512+(float)Math.Cos(b)*211,512+(float)Math.Sin(b)*211),new PointF(512+(float)Math.Cos(b)*260,512+(float)Math.Sin(b)*260));
  }
  g.Restore(surface);
  // Kirin Tor's radiant eye, curved brow and three elongated pendant strokes.
  var intellect=g.Save();g.TranslateTransform(512,190);
  float pulse=(float)(.5+.5*Math.Sin(f*Math.PI/18));
  using(var eye=new GraphicsPath()){
   eye.AddBezier(-76,0,-29,-49,30,-49,76,0);
   eye.AddBezier(76,0,30,35,-29,35,-76,0);
   using(var glow=new Pen(Color.FromArgb((int)(55+pulse*25),233,110,255),20))g.DrawPath(glow,eye);
   using(var light=new Pen(Color.FromArgb(245,255,220,255),7))g.DrawPath(light,eye);
   using(var core=new Pen(Color.FromArgb(220,255,247,255),2))g.DrawPath(core,eye);
  }
  using(var iris=new Pen(Color.FromArgb(250,255,230,255),7))g.DrawEllipse(iris,-18,-25,36,39);
  using(var brow=new GraphicsPath()){
   brow.AddBezier(-58,-33,-21,-65,22,-65,58,-33);
   using(var glow=new Pen(Color.FromArgb(60,238,116,255),16))g.DrawPath(glow,brow);
   using(var light=new Pen(Color.FromArgb(235,255,217,255),6))g.DrawPath(light,brow);
  }
  PointF[][] pendants=new PointF[][]{
   new PointF[]{new PointF(-50,26),new PointF(-33,31),new PointF(-39,70),new PointF(-54,85),new PointF(-63,73)},
   new PointF[]{new PointF(-9,34),new PointF(9,34),new PointF(12,86),new PointF(0,112),new PointF(-12,86)},
   new PointF[]{new PointF(33,31),new PointF(50,26),new PointF(63,73),new PointF(54,85),new PointF(39,70)}
  };
  foreach(var pendant in pendants){
   using(var haze=new Pen(Color.FromArgb((int)(40+pulse*25),235,115,255),16))g.DrawPolygon(haze,pendant);
   Poly(g,Color.FromArgb(245,255,226,255),pendant);
  }
  g.Restore(intellect);
  im.Save(Path.Combine(output,"enhancement_"+f.ToString("D4")+".png"),ImageFormat.Png);
 }}
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Choose a new output folder to preserve previous versions.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[SpellslingerArt]::Write($destination)
Write-Output "Created Spellslinger animation: $destination"
