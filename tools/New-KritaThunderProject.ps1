param([string]$OutputPath=(Join-Path $PSScriptRoot '../art/krita/Enhancement-thunder-lightning-v5-sharp.ora'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -ReferencedAssemblies System.Drawing,System.IO.Compression,System.IO.Compression.FileSystem -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.IO.Compression;
using System.Text;
public static class EnhancementThunderProject {
 const int N=1024;
 static Bitmap Layer(){return new Bitmap(N,N,PixelFormat.Format32bppArgb);}
 static Graphics Draw(Bitmap b){var g=Graphics.FromImage(b);g.SmoothingMode=SmoothingMode.AntiAlias;g.PixelOffsetMode=PixelOffsetMode.HighQuality;return g;}
 static PointF[] P(params float[] a){var p=new PointF[a.Length/2];for(int i=0;i<p.Length;i++)p[i]=new PointF(a[i*2],a[i*2+1]);return p;}
 static void Fill(Graphics g,int r,int green,int b,PointF[] points){using(var brush=new SolidBrush(Color.FromArgb(r,green,b)))g.FillPolygon(brush,points);}
 static void Stroke(Graphics g,PointF[] points,Color color,float width){using(var pen=new Pen(color,width)){pen.LineJoin=LineJoin.Miter;pen.MiterLimit=2;pen.StartCap=LineCap.Flat;pen.EndCap=LineCap.Flat;g.DrawLines(pen,points);}}
 static PointF[][] LeftBolts(){return new PointF[][]{
  P(355,202,303,318,329,326,277,438,308,428,256,557,289,543,242,701),
  P(303,318,260,294,245,249),P(277,438,234,415,204,444),
  P(256,557,219,586,224,629),P(289,543,326,590,311,632)
 };}
 static PointF[][] RightBolts(){return new PointF[][]{
  P(676,223,724,335,697,328,751,446,722,434,774,564,743,550,790,701),
  P(724,335,765,305,784,261),P(751,446,797,417,824,438),
  P(774,564,811,588,802,631),P(743,550,705,591,721,633)
 };}
 static PointF[][] Cracks(){return new PointF[][]{
  P(278,760,357,742,398,767,456,738,503,765,554,739,610,764,678,746,748,770),
  P(398,767,410,809,445,830),P(554,739,576,707,612,697),P(678,746,694,801,727,820)
 };}
 static void Halo(Graphics g,PointF[][] paths,int strength){
  foreach(var path in paths)for(int width=34;width>=6;width-=2)
   Stroke(g,path,Color.FromArgb(width>18?strength:strength*2,19,97,255),width);
 }
 static void Lightning(Graphics g,PointF[][] paths){
  for(int i=0;i<paths.Length;i++){
   float width=i==0?18f:8f;
   Stroke(g,paths[i],Color.FromArgb(180,28,119,255),width+2);
   Stroke(g,paths[i],Color.FromArgb(240,104,194,255),width);
   Stroke(g,paths[i],Color.FromArgb(255,238,251,255),i==0?6f:2.8f);
  }
 }
 static void ZipText(ZipArchive zip,string name,string text,CompressionLevel level){var entry=zip.CreateEntry(name,level);using(var w=new StreamWriter(entry.Open(),new UTF8Encoding(false)))w.Write(text);}
 static void ZipImage(ZipArchive zip,string name,Bitmap image){var entry=zip.CreateEntry(name,CompressionLevel.Optimal);using(var stream=entry.Open())image.Save(stream,ImageFormat.Png);}
 public static void Write(string file){
  var layers=new Bitmap[8];for(int i=0;i<layers.Length;i++)layers[i]=Layer();
  using(var g=Draw(layers[0]))foreach(var path in Cracks())for(int width=64;width>=12;width-=4)
   Stroke(g,path,Color.FromArgb(width>36?6:12,196,122,43),width);
  using(var g=Draw(layers[1])){
   // Torn earthen banks form a single sundering scar, with a dark open center.
   Fill(g,116,65,30,P(269,754,354,720,398,742,456,715,504,740,554,717,609,738,678,724,756,763,682,759,610,779,554,759,503,786,455,758,398,787,355,763));
   Fill(g,185,119,52,P(278,760,357,742,398,767,456,738,503,765,554,739,610,764,678,746,748,770,681,785,611,797,553,781,502,810,455,783,397,811,353,785));
   foreach(var path in Cracks()){
    Stroke(g,path,Color.FromArgb(255,40,24,15),19);
    Stroke(g,path,Color.FromArgb(255,228,161,78),7);
    Stroke(g,path,Color.FromArgb(255,255,210,132),2.8f);
   }
  }
  using(var g=Draw(layers[2])){Halo(g,LeftBolts(),7);Halo(g,RightBolts(),7);}
  using(var g=Draw(layers[3])){
   Fill(g,62,155,255,P(355,202,292,369,322,349,260,505,296,480,242,701,327,505,298,518,351,383,322,395));
   Lightning(g,LeftBolts());
  }
  using(var g=Draw(layers[4])){
   Fill(g,62,155,255,P(676,223,736,383,707,363,767,512,735,490,790,701,709,518,737,528,686,394,714,406));
   Lightning(g,RightBolts());
  }
  using(var g=Draw(layers[5])){
   foreach(var center in P(277,438,751,446)){
    using(var path=new GraphicsPath()){
     path.AddPolygon(P(center.X,center.Y-70,center.X+17,center.Y-14,center.X+70,center.Y,
       center.X+17,center.Y+14,center.X,center.Y+70,center.X-17,center.Y+14,
       center.X-70,center.Y,center.X-17,center.Y-14));
     using(var brush=new PathGradientBrush(path)){
      brush.CenterColor=Color.FromArgb(145,225,246,255);
      brush.SurroundColors=new Color[]{Color.FromArgb(0,45,130,255)};
      g.FillPath(brush,path);
     }
    }
    Stroke(g,P(center.X-28,center.Y,center.X+28,center.Y),Color.FromArgb(160,233,248,255),1);
    Stroke(g,P(center.X,center.Y-23,center.X,center.Y+23),Color.FromArgb(160,233,248,255),1);
   }
  }
  using(var g=Draw(layers[6])){
   using(var pen=new Pen(Color.FromArgb(130,210,180,110),2)){pen.DashStyle=DashStyle.Dash;g.DrawRectangle(pen,320,320,384,384);}
   using(var brush=new SolidBrush(Color.FromArgb(150,220,210,190)))using(var font=new Font(FontFamily.GenericSansSerif,16))g.DrawString("ICON POSITION - HIDE BEFORE EXPORT",font,brush,310,742);
  }
  using(var g=Draw(layers[7]))g.Clear(Color.FromArgb(255,12,19,30));
  string[] names={"01 - Sundering / soft ochre earth glow","02 - Sundering / brown fractured ground","03 - Lightning / soft cobalt glow","04 - Lightning / left strike and branches","05 - Lightning / right strike and branches","ANIMATION - thunder flash (hidden)","GUIDE - icon position (hidden)","PREVIEW - dark background (hidden)"};
  using(var merged=Layer()){
   using(var g=Draw(merged))for(int i=0;i<5;i++)g.DrawImageUnscaled(layers[i],0,0);
   using(var stream=new FileStream(file,FileMode.CreateNew))using(var zip=new ZipArchive(stream,ZipArchiveMode.Create)){
    ZipText(zip,"mimetype","image/openraster",CompressionLevel.NoCompression);
    var xml=new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?><image version=\"0.0.3\" w=\"1024\" h=\"1024\" name=\"Enhancement - thunder lightning and sundering\"><stack>");
    int[] order={6,5,4,3,2,1,0,7};
    foreach(int i in order){xml.Append("<layer name=\"").Append(System.Security.SecurityElement.Escape(names[i])).Append("\" src=\"data/layer").Append(i).Append(".png\" x=\"0\" y=\"0\" opacity=\"1\" visibility=\"").Append(i<5?"visible":"hidden").Append("\" composite-op=\"svg:src-over\"/>");ZipImage(zip,"data/layer"+i+".png",layers[i]);}
    xml.Append("</stack></image>");ZipText(zip,"stack.xml",xml.ToString(),CompressionLevel.Optimal);ZipImage(zip,"mergedimage.png",merged);
   }
  }
  foreach(var layer in layers)layer.Dispose();
 }
}
'@
$absolute=[IO.Path]::GetFullPath($OutputPath)
if(Test-Path -LiteralPath $absolute){throw "File already exists: $absolute. Choose a new filename."}
[IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($absolute)) | Out-Null
[EnhancementThunderProject]::Write($absolute)
Write-Output "Layered Krita-compatible project saved: $absolute"
