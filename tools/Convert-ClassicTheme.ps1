$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$theme=Join-Path (Split-Path $PSScriptRoot -Parent) 'addons/ForeverCoaching/Media/ClassicTheme'
foreach($file in Get-ChildItem -LiteralPath $theme -Filter '*.jpg'){
 $source=[Drawing.Image]::FromFile($file.FullName)
 $width=if($file.BaseName -eq 'ClassicBackdrop'){1024}else{256}
 $height=512
 $bitmap=[Drawing.Bitmap]::new($width,$height,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 $graphics=[Drawing.Graphics]::FromImage($bitmap)
 try{
  $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.DrawImage($source,[Drawing.Rectangle]::new(0,0,$width,$height))
  $data=$bitmap.LockBits([Drawing.Rectangle]::new(0,0,$width,$height),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
  try{
   $pixels=[byte[]]::new($width*$height*4);[Runtime.InteropServices.Marshal]::Copy($data.Scan0,$pixels,0,$pixels.Length)
   $header=[byte[]]::new(18);$header[2]=2;$header[12]=$width-band 255;$header[13]=$width-shr 8;$header[14]=$height-band 255;$header[15]=$height-shr 8;$header[16]=32;$header[17]=40
   $stream=[IO.File]::Create((Join-Path $theme ($file.BaseName+'.tga')))
   try{$stream.Write($header,0,18);$stream.Write($pixels,0,$pixels.Length)}finally{$stream.Dispose()}
  }finally{$bitmap.UnlockBits($data)}
 }finally{$graphics.Dispose();$bitmap.Dispose();$source.Dispose()}
}
Write-Output 'Converted original artwork to power-of-two TGA textures.'
