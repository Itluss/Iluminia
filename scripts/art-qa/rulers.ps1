New-Item -ItemType Directory -Force "$PSScriptRoot\out" | Out-Null
Add-Type -AssemblyName System.Drawing
$src = "c:\Users\camille\Eluminia\public\art\eluminia_sprint01_environment_fx"
$out = "$PSScriptRoot\out"
$files = @(
  @{ f = "fx\banner-wave-strip.png";  n = "ruler-banner.png" },
  @{ f = "environment\flowers-grass.png"; n = "ruler-flowers.png" },
  @{ f = "environment\ground-details.png"; n = "ruler-ground.png" },
  @{ f = "environment\fallen-leaves.png"; n = "ruler-fallen.png" }
)
foreach ($e in $files) {
  $img = [System.Drawing.Image]::FromFile("$src\$($e.f)")
  $s = 3
  $bmp = New-Object System.Drawing.Bitmap ($img.Width * $s + 40), ($img.Height * $s + 40)
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.InterpolationMode = 'NearestNeighbor'
  $g.PixelOffsetMode = 'Half'
  $g.Clear([System.Drawing.Color]::White)
  $g.DrawImage($img, 40, 40, $img.Width * $s, $img.Height * $s)
  $font = New-Object System.Drawing.Font 'Consolas', 9
  $red = [System.Drawing.Brushes]::Red
  $penMajor = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(160, 255, 0, 0)), 1
  $penMinor = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(70, 255, 120, 0)), 1
  for ($x = 0; $x -le $img.Width; $x += 10) {
    $px = 40 + $x * $s
    $pen = if ($x % 50 -eq 0) { $penMajor } else { $penMinor }
    $g.DrawLine($pen, $px, 40, $px, 40 + $img.Height * $s)
    if ($x % 50 -eq 0) { $g.DrawString("$x", $font, $red, $px - 10, 22) }
  }
  for ($y = 0; $y -le $img.Height; $y += 10) {
    $py = 40 + $y * $s
    $pen = if ($y % 50 -eq 0) { $penMajor } else { $penMinor }
    $g.DrawLine($pen, 40, $py, 40 + $img.Width * $s, $py)
    if ($y % 50 -eq 0) { $g.DrawString("$y", $font, $red, 2, $py - 6) }
  }
  $bmp.Save("$out\$($e.n)")
  $g.Dispose(); $bmp.Dispose(); $img.Dispose()
  Write-Output $e.n
}

