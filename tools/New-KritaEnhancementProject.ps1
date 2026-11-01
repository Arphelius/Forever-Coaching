param([string]$OutputPath=(Join-Path $PSScriptRoot '../art/krita/Enhancement-earth-lightning-v1.ora'))
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
public static class EnhancementKritaProject {
 const int N=1024;
 static Bitmap Layer(){return new Bitmap(N,N,PixelFormat.Format32bppArgb);}
 static Graphics Draw(Bitmap b){var g=Graphics.FromImage(b);g.SmoothingMode=SmoothingMode.AntiAlias;g.PixelOffsetMode=PixelOffsetMode.HighQuality;return g;}
 static PointF[] P(params float[] a){var p=new PointF[a.Length/2];for(int i=0;i<p.Length;i++)p[i]=new PointF(a[i*2],a[i*2+1]);return p;}
 static void Fill(Graphics g,int r,int green,int b,PointF[] points){using(var brush=new SolidBrush(Color.FromArgb(r,green,b)))g.FillPolygon(brush,points);}
 static void Stroke(Graphics g,PointF[] points,Color color,float width){using(var pen=new Pen(color,width)){pen.LineJoin=LineJoin.Round;pen.StartCap=LineCap.Round;pen.EndCap=LineCap.Round;g.DrawLines(pen,points);}}
 static void Rock(Bitmap b,bool right){using(var g=Draw(b)){
  if(!right){
   Fill(g,70,49,35,P(132,590,218,566,266,621,253,700,195,750,102,717,80,651));
   Fill(g,142,107,70,P(132,590,218,566,199,638,120,656,80,651));
   Fill(g,101,75,49,P(218,566,266,621,253,700,199,638));
   Fill(g,46,38,32,P(120,656,199,638,195,750,102,717));
   Fill(g,81,57,39,P(199,638,253,700,195,750));
   Stroke(g,P(132,590,218,566,262,621),Color.FromArgb(210,194,153,98),3);
   Stroke(g,P(120,656,199,638,222,659),Color.FromArgb(120,24,24,25),2);
   Fill(g,121,91,57,P(93,560,111,546,126,557,112,579));
   Fill(g,84,65,46,P(236,750,253,741,267,758,249,776));
  }else{
   Fill(g,66,48,34,P(805,540,888,514,941,552,956,620,910,671,846,652,785,603));
   Fill(g,157,117,72,P(805,540,888,514,869,578,800,588));
   Fill(g,116,86,52,P(888,514,941,552,956,620,869,578));
   Fill(g,40,34,29,P(800,588,869,578,846,652,785,603));
   Fill(g,82,61,40,P(869,578,956,620,910,671,846,652));
   Stroke(g,P(805,540,888,514,939,551),Color.FromArgb(210,201,158,97),3);
   Stroke(g,P(869,578,910,610,901,636),Color.FromArgb(130,22,24,29),2);
   Fill(g,120,87,54,P(939,492,956,480,971,491,963,512));
   Fill(g,85,62,41,P(796,676,811,668,824,687,807,700));
  }
 }}
 static PointF[][] Bolts(){return new PointF[][]{
  P(194,607,164,557,192,526,159,492,196,449,174,420,230,367,214,329,297,256,341,265,411,215,451,228),
  P(451,228,493,197,534,219,569,198,614,235,658,212,703,243,744,218,784,250,816,240),
  P(816,240,801,293,844,322,824,367,870,399,849,432,883,474,866,516,881,551),
  P(196,449,126,428,143,397,104,378),P(230,367,274,359,286,321,319,302),
  P(341,265,348,205,379,188,370,153),P(614,235,642,183,626,152),
  P(844,322,906,296,922,311,953,277),P(883,474,927,448,935,411),
  P(188,618,217,643,205,674),P(880,550,851,579,867,608)
 };}
 static void ZipText(ZipArchive zip,string name,string text,CompressionLevel level){var entry=zip.CreateEntry(name,level);using(var w=new StreamWriter(entry.Open(),new UTF8Encoding(false)))w.Write(text);}
 static void ZipImage(ZipArchive zip,string name,Bitmap image){var entry=zip.CreateEntry(name,CompressionLevel.Optimal);using(var stream=entry.Open())image.Save(stream,ImageFormat.Png);}
 public static void Write(string file){
  var layers=new Bitmap[6];for(int i=0;i<layers.Length;i++)layers[i]=Layer();
  Rock(layers[0],false);Rock(layers[1],true);
  using(var g=Draw(layers[2]))foreach(var path in Bolts())for(int width=40;width>=6;width-=2)Stroke(g,path,Color.FromArgb(width>20?3:8,20,91,255),width);
  using(var g=Draw(layers[3]))foreach(var path in Bolts()){
   Stroke(g,path,Color.FromArgb(190,32,123,255),4.8f);
   Stroke(g,path,Color.FromArgb(245,112,199,255),2.1f);
   Stroke(g,path,Color.FromArgb(255,231,248,255),.85f);
  }
  using(var g=Draw(layers[4])){
   using(var pen=new Pen(Color.FromArgb(130,210,180,110),2)){pen.DashStyle=DashStyle.Dash;g.DrawRectangle(pen,320,320,384,384);}
   using(var brush=new SolidBrush(Color.FromArgb(150,220,210,190)))using(var font=new Font(FontFamily.GenericSansSerif,16))g.DrawString("ICON POSITION - HIDE BEFORE EXPORT",font,brush,310,742);
  }
  using(var g=Draw(layers[5]))g.Clear(Color.FromArgb(255,12,19,30));
  string[] names={"01 - Rock left / facets","02 - Rock right / facets","03 - Electric blue glow","04 - Lightning / core and branches","GUIDE - icon position (hidden)","PREVIEW - dark background (hidden)"};
  using(var merged=Layer()){
   using(var g=Draw(merged))for(int i=0;i<4;i++)g.DrawImageUnscaled(layers[i],0,0);
   using(var stream=new FileStream(file,FileMode.CreateNew))using(var zip=new ZipArchive(stream,ZipArchiveMode.Create)){
    ZipText(zip,"mimetype","image/openraster",CompressionLevel.NoCompression);
    var xml=new StringBuilder("<?xml version=\"1.0\" encoding=\"UTF-8\"?><image version=\"0.0.3\" w=\"1024\" h=\"1024\" name=\"Enhancement - earth and lightning\"><stack>");
    int[] order={4,3,2,1,0,5};
    foreach(int i in order){xml.Append("<layer name=\"").Append(System.Security.SecurityElement.Escape(names[i])).Append("\" src=\"data/layer").Append(i).Append(".png\" x=\"0\" y=\"0\" opacity=\"1\" visibility=\"").Append(i<4?"visible":"hidden").Append("\" composite-op=\"svg:src-over\"/>");ZipImage(zip,"data/layer"+i+".png",layers[i]);}
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
[EnhancementKritaProject]::Write($absolute)
Write-Output "Layered Krita-compatible project saved: $absolute"
