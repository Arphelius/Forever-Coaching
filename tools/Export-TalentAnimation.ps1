param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '../art/krita/Enhancement-animation-v15'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '../addons/ForeverCoaching/Media/TalentEffects/Enhancement.tga')
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
# Pack the authored frames into one power-of-two, 32-bit BGRA TGA.
# WoW samples individual cells; the transparent pixels remain transparent.
$atlas = New-Object System.Drawing.Bitmap(1024, 1024)
$graphics = [System.Drawing.Graphics]::FromImage($atlas)
$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
try {
    for ($frame = 0; $frame -lt 36; $frame++) {
        $source = Join-Path $SourceDirectory ('enhancement_{0:D4}.png' -f $frame)
        $image = [System.Drawing.Image]::FromFile($source)
        try {
            $rect = [System.Drawing.Rectangle]::new([int](($frame % 8) * 128), [int]([math]::Floor($frame / 8) * 128), 128, 128)
            $graphics.DrawImage($image, $rect)
        } finally { $image.Dispose() }
    }
    [System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($OutputPath))) | Out-Null
    $stream = [System.IO.File]::Create($OutputPath)
    $writer = New-Object System.IO.BinaryWriter($stream)
    try {
        # Uncompressed true-color, top-left origin, eight alpha bits.
        $writer.Write([byte[]]@(0,0,2,0,0,0,0,0,0,0,0,0,0,4,0,4,32,40))
        $rect = New-Object System.Drawing.Rectangle(0,0,1024,1024)
        $data = $atlas.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $row = New-Object byte[] 4096
            for ($y = 0; $y -lt 1024; $y++) {
                [System.Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($data.Scan0, $y * $data.Stride), $row, 0, 4096)
                $writer.Write($row)
            }
        } finally { $atlas.UnlockBits($data) }
    } finally { $writer.Dispose() }
} finally { $graphics.Dispose(); $atlas.Dispose() }
Write-Output "Exported talent animation: $OutputPath"
