param([string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Shadow-MindBlast-v7'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;using System.IO;using System.Drawing;using System.Drawing.Drawing2D;using System.Drawing.Imaging;
public static class MindBlastArt {
 static void Glow(Graphics g,float x,float y,float rx,float ry,Color color){using(var path=new GraphicsPath()){path.AddEllipse(x-rx,y-ry,rx*2,ry*2);using(var b=new PathGradientBrush(path)){b.CenterColor=color;b.SurroundColors=new Color[]{Color.Transparent};g.FillPath(b,path);}}}
 public static void Write(string output){for(int f=0;f<36;f++)using(var im=new Bitmap(1024,1024,PixelFormat.Format32bppArgb))using(var g=Graphics.FromImage(im)){
  g.SmoothingMode=SmoothingMode.AntiAlias;double t=f*Math.PI*2/36;float pulse=(float)(.5+.5*Math.Sin(t*2));
  // Darkness covers the whole spell face, while the point badge remains readable.
  var spellFace=g.Save();g.SetClip(new Rectangle(309,309,406,406));
  using(var dark=new SolidBrush(Color.FromArgb(145,6,3,13)))g.FillRectangle(dark,309,309,406,406);
  // Moving curtains of shadow wash over the artwork, leaving it recognizable.
  for(int lane=0;lane<9;lane++)for(int puff=0;puff<4;puff++){
   float age=(float)((f/36.0+puff*.241+lane*.079)%1);
   float x=317+lane*47+(float)Math.Sin(t+lane+age*5)*12,y=305+age*418;
   float fade=(float)Math.Sin(age*Math.PI);
   Glow(g,x,y,33,43,Color.FromArgb((int)(fade*75),15,7,29));
   Glow(g,x-9,y,24,38,Color.FromArgb((int)(fade*22),79,42,101));
  }
  g.Restore(spellFace);
  // Rolling shadow mist wraps all four borders and extends beyond the spell.
  for(int edge=0;edge<4;edge++)for(int wisp=0;wisp<18;wisp++){
   float age=(float)((f/36.0+wisp*.0837+edge*.17)%1),wave=(float)Math.Sin(t+edge+wisp)*7;
   float x=(edge==0||edge==3)?301+age*422:(edge==1?287:737)+wave*1.5f;
   float y=edge==0?287+wave*1.5f:edge==3?737+wave*1.5f:306+age*390;
   Glow(g,x,y,47,49,Color.FromArgb(92,20,8,36));
   Glow(g,x,y,25,34,Color.FromArgb(43,81,40,111));
  }
  // The same descending-and-spreading movement as the icy mist, in dark vapor.
  for(int lane=0;lane<12;lane++)for(int puff=0;puff<5;puff++){
   float age=(float)((f/36.0+puff*.193+lane*.061)%1),spread=age*age*age;
   float origin=354+lane*27,side=lane<6?-1:1,curl=(float)Math.Sin(t*2+lane*.93+puff*1.7);
   float x=origin+side*spread*134+curl*(3+age*7);
   float y=674+112*(float)(1-Math.Exp(-2.2*age))+age*15+(float)Math.Sin(t+lane)*age*5;
   float fade=(float)(Math.Sin(Math.Min(1,age*6)*Math.PI*.5)*Math.Pow(1-age,1.15));
   Glow(g,x,y,12+age*18+curl*2,20+age*4,Color.FromArgb((int)(fade*110),14,6,28));
   Glow(g,x+4,y,9+age*12,14,Color.FromArgb((int)(fade*28),73,33,104));
  }
  // A dark psychic bloom above the icon holds a warm, hypnotic Mind Blast core.
  Glow(g,512,247,122,108,Color.FromArgb(200,39,17,49));
  Glow(g,512,247,88,79,Color.FromArgb((int)(145+pulse*60),167,105,135));
  for(int petal=0;petal<9;petal++){
   double a=petal*Math.PI*2/9+t*.12;
   float x=512+(float)Math.Cos(a)*70,y=247+(float)Math.Sin(a)*62;
   using(var fold=new GraphicsPath()){
    fold.AddBezier(x,y,x+(float)Math.Cos(a)*42,y+(float)Math.Sin(a)*36,x-(float)Math.Sin(a)*58,y+(float)Math.Cos(a)*58,512+(float)Math.Cos(a+.8)*64,247+(float)Math.Sin(a+.8)*58);
    using(var shadow=new Pen(Color.FromArgb(185,23,10,29),24))g.DrawPath(shadow,fold);
    using(var edge=new Pen(Color.FromArgb(100,151,105,161),4))g.DrawPath(edge,fold);
   }
  }
  Glow(g,512,247,64,61,Color.FromArgb((int)(180+pulse*65),244,181,107));
  Glow(g,512,247,34,33,Color.FromArgb(200,255,233,167));
  // Uneven luminous spiral, rather than a solid orb or a crown.
  PointF[] spiral=new PointF[150];
  for(int j=0;j<spiral.Length;j++){
   float p=j/149f,r=6+p*66;double a=p*Math.PI*6-t;
   float ripple=1+(float)Math.Sin(p*21+t*2)*.05f;
   spiral[j]=new PointF(512+(float)Math.Cos(a)*r*ripple,247+(float)Math.Sin(a)*r*.9f*ripple);
  }
  using(var glow=new Pen(Color.FromArgb(70,249,181,106),14))g.DrawCurve(glow,spiral);
  using(var core=new Pen(Color.FromArgb((int)(175+pulse*70),255,231,172),5))g.DrawCurve(core,spiral);
  // Subtle psychic shockwaves expand into the surrounding shadow.
  for(int wave=0;wave<3;wave++){
   float age=(float)((f/36.0+wave*.3333)%1),r=60+age*60;
   using(var ripple=new Pen(Color.FromArgb((int)((1-age)*45),191,140,205),2))g.DrawEllipse(ripple,512-r,247-r*.85f,r*2,r*1.7f);
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
[MindBlastArt]::Write($destination)
