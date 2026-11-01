param(
 [string]$Source=(Join-Path $PSScriptRoot '../art/krita/Enhancement-thunder-lightning-v5-sharp.ora'),
 [string]$OutputDirectory=(Join-Path $PSScriptRoot '../art/krita/Enhancement-animation-v5-sharp')
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -ReferencedAssemblies System.Drawing,System.IO.Compression,System.IO.Compression.FileSystem -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.IO;
using System.IO.Compression;
public static class EnhancementAnimation {
 static void DrawLayer(Graphics g,Bitmap layer,float opacity,float dx,float dy) {
  using(var attributes=new ImageAttributes()) {
   var matrix=new ColorMatrix();matrix.Matrix33=Math.Max(0,Math.Min(1,opacity));attributes.SetColorMatrix(matrix);
   g.DrawImage(layer,new PointF[]{new PointF(dx,dy),new PointF(dx+1024,dy),new PointF(dx,dy+1024)},
    new RectangleF(0,0,1024,1024),GraphicsUnit.Pixel,attributes);
  }
 }
 public static void Write(string source,string output) {
  var layers=new Bitmap[6];
  using(var zip=ZipFile.OpenRead(source)) {
   for(int i=0;i<6;i++)using(var stream=zip.GetEntry("data/layer"+i+".png").Open())using(var image=new Bitmap(stream))layers[i]=new Bitmap(image);
  }
  for(int frame=0;frame<36;frame++) {
   double phase=frame*Math.PI*2/36;
   float left=(float)(.65+.35*Math.Pow(Math.Max(0,Math.Sin(phase)),3));
   float right=(float)(.65+.35*Math.Pow(Math.Max(0,Math.Sin(phase+2.1)),3));
   float earth=(float)(.85+.15*(.5+.5*Math.Sin(phase-.7)));
   // Two brief, local thunder highlights per three-second loop.
   float flash=frame==8?.75f:frame==9?.25f:frame==26?.65f:frame==27?.18f:0;
   using(var image=new Bitmap(1024,1024,PixelFormat.Format32bppArgb)) {
    using(var g=Graphics.FromImage(image)) {
     g.SmoothingMode=SmoothingMode.AntiAlias;g.InterpolationMode=InterpolationMode.HighQualityBicubic;g.PixelOffsetMode=PixelOffsetMode.HighQuality;
     DrawLayer(g,layers[0],earth,0,0);DrawLayer(g,layers[1],earth,0,0);
     DrawLayer(g,layers[2],Math.Max(left,right)*.85f,0,0);
     DrawLayer(g,layers[3],left,(float)Math.Sin(phase*3)*1.4f,0);
     DrawLayer(g,layers[4],right,(float)Math.Sin(phase*3+1)*1.2f,0);
     DrawLayer(g,layers[5],flash,0,0);
    }
    image.Save(Path.Combine(output,"enhancement_"+frame.ToString("D4")+".png"),ImageFormat.Png);
   }
  }
  foreach(var layer in layers)layer.Dispose();
 }
}
'@
$destination=[IO.Path]::GetFullPath($OutputDirectory)
if(Test-Path -LiteralPath $destination){throw 'Output folder already exists; choose a new version to preserve earlier work.'}
[IO.Directory]::CreateDirectory($destination) | Out-Null
[EnhancementAnimation]::Write([IO.Path]::GetFullPath($Source),$destination)
[IO.File]::WriteAllText((Join-Path $destination 'animation.json'),'{"fps":12,"firstFrame":0,"lastFrame":35,"frames":36,"durationSeconds":3,"width":1024,"height":1024,"alpha":true}',[Text.UTF8Encoding]::new($false))
Write-Output "Animation created: 36 transparent PNG frames at 12 fps in $destination"
