New-Item -ItemType Directory -Force "$PSScriptRoot\out" | Out-Null
Add-Type -AssemblyName System.Drawing
$src = "c:\Users\camille\Eluminia\public\art\eluminia_sprint01_environment_fx"
$out = "$PSScriptRoot\out\crops-qa.png"

# name, file, x, y, w, h, tol (0 = pas de detourage, asset additif)
$crops = @(
  @("banner-0","fx\banner-wave-strip.png",6,0,58,104,72),
  @("banner-1","fx\banner-wave-strip.png",76,2,56,100,72),
  @("banner-2","fx\banner-wave-strip.png",140,0,60,104,72),
  @("banner-3","fx\banner-wave-strip.png",208,0,60,104,72),
  @("banner-shadow","fx\banner-shadow-overlay.png",78,30,64,110,72),
  @("canopy","fx\soft-shadow-overlay.png",14,14,200,100,84),
  @("clump-0","environment\flowers-grass.png",14,30,84,66,72),
  @("clump-1","environment\flowers-grass.png",98,32,70,64,72),
  @("clump-2","environment\flowers-grass.png",170,30,78,66,72),
  @("clump-3","environment\flowers-grass.png",248,32,72,64,72),
  @("clump-4","environment\flowers-grass.png",292,98,46,52,72),
  @("g-0","environment\ground-details.png",12,6,40,38,72),
  @("g-1","environment\ground-details.png",58,10,46,34,72),
  @("g-2","environment\ground-details.png",114,10,42,36,72),
  @("g-3","environment\ground-details.png",154,12,48,32,72),
  @("g-4","environment\ground-details.png",214,14,48,30,72),
  @("g-5","environment\ground-details.png",286,2,48,44,72),
  @("fallen-0","environment\fallen-leaves.png",8,46,32,30,72),
  @("fallen-1","environment\fallen-leaves.png",54,32,52,36,72),
  @("fallen-2","environment\fallen-leaves.png",10,86,36,30,72),
  @("fallen-3","environment\fallen-leaves.png",58,116,44,26,72),
  @("leaf-0","fx\leaf-particles.png",14,16,26,22,72),
  @("leaf-1","fx\leaf-particles.png",58,58,26,20,72),
  @("leaf-2","fx\leaf-particles.png",108,26,22,20,72),
  @("petal-0","fx\petal-particles.png",8,12,26,22,72),
  @("petal-1","fx\petal-particles.png",34,54,22,20,72),
  @("butterfly","fx\fireflies.png",100,56,76,86,60),
  @("button2","ui\button-background.png",6,32,138,56,60),
  @("icon-xp2","ui\button-background.png",134,24,80,84,60),
  @("icon-quest2","ui\xp-icon.png",6,18,88,92,60),
  @("icon-bag2","ui\quest-icon.png",10,20,80,92,60),
  @("panel2","ui\dialogue-panel.png",2,10,332,78,60),
  @("dlg-arrow","ui\dialogue-panel.png",336,26,46,42,60),
  @("ripple-0","fx\water-ripple-strip.png",6,5,58,48,0),
  @("splash-0","fx\fountain-splash-strip.png",7,5,56,55,0),
  @("rays-0","fx\god-rays.png",3,4,68,122,0),
  @("droplet","fx\fountain-particles.png",14,4,30,38,0),
  @("glint","fx\fountain-particles.png",12,72,34,34,0),
  @("ff","fx\fireflies.png",26,70,30,30,0),
  @("magic","fx\magic-sparkles.png",28,66,134,120,0),
  @("spark","ui\inventory-icon.png",46,34,40,40,0)
)

function Key-Crop($bmp, $tol) {
  $w = $bmp.Width; $h = $bmp.Height
  $bg = @(0,0,0)
  foreach ($c in @($bmp.GetPixel(0,0), $bmp.GetPixel($w-1,0), $bmp.GetPixel(0,$h-1), $bmp.GetPixel($w-1,$h-1))) {
    $bg[0] += $c.R / 4; $bg[1] += $c.G / 4; $bg[2] += $c.B / 4
  }
  $visited = New-Object 'bool[,]' $w, $h
  $queue = New-Object System.Collections.Generic.Queue[int[]]
  $push = {
    param($x, $y)
    if ($x -lt 0 -or $y -lt 0 -or $x -ge $w -or $y -ge $h) { return }
    if ($visited[$x, $y]) { return }
    $visited[$x, $y] = $true
    $p = $bmp.GetPixel($x, $y)
    $dr = $p.R - $bg[0]; $dg = $p.G - $bg[1]; $db = $p.B - $bg[2]
    if (($dr*$dr + $dg*$dg + $db*$db) -lt ($tol * $tol)) {
      $bmp.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(0,0,0,0))
      $queue.Enqueue(@($x, $y))
    }
  }
  for ($x = 0; $x -lt $w; $x++) { & $push $x 0; & $push $x ($h-1) }
  for ($y = 0; $y -lt $h; $y++) { & $push 0 $y; & $push ($w-1) $y }
  while ($queue.Count -gt 0) {
    $c = $queue.Dequeue()
    & $push ($c[0]-1) $c[1]; & $push ($c[0]+1) $c[1]; & $push $c[0] ($c[1]-1); & $push $c[0] ($c[1]+1)
  }
}

$cols = 7
$cell = 150
$rows = [Math]::Ceiling($crops.Count / $cols)
$sheet = New-Object System.Drawing.Bitmap ($cols * $cell), ($rows * ($cell + 20))
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.Clear([System.Drawing.Color]::FromArgb(90, 120, 90))
# damier de transparence
$light = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(110, 140, 110))
for ($cy = 0; $cy -lt $sheet.Height; $cy += 12) { for ($cx = (($cy/12) % 2) * 12; $cx -lt $sheet.Width; $cx += 24) { $g.FillRectangle($light, $cx, $cy, 12, 12) } }
$font = New-Object System.Drawing.Font 'Consolas', 9, ([System.Drawing.FontStyle]::Bold)
$i = 0
$sources = @{}
foreach ($c in $crops) {
  $name = $c[0]; $file = $c[1]
  if (-not $sources[$file]) { $sources[$file] = New-Object System.Drawing.Bitmap "$src\$file" }
  $srcBmp = $sources[$file]
  $crop = New-Object System.Drawing.Bitmap $c[4], $c[5]
  $cg = [System.Drawing.Graphics]::FromImage($crop)
  $cg.DrawImage($srcBmp, (New-Object System.Drawing.Rectangle 0,0,$c[4],$c[5]), (New-Object System.Drawing.Rectangle $c[2],$c[3],$c[4],$c[5]), [System.Drawing.GraphicsUnit]::Pixel)
  $cg.Dispose()
  if ($c[6] -gt 0) { Key-Crop $crop $c[6] }
  $x0 = ($i % $cols) * $cell; $y0 = [int][Math]::Floor($i / $cols) * ($cell + 20)
  $scale = [Math]::Min(($cell - 10) / $crop.Width, ($cell - 10) / $crop.Height)
  if ($scale -gt 2) { $scale = 2 }
  $g.InterpolationMode = 'NearestNeighbor'
  $g.DrawImage($crop, $x0 + 5, $y0 + 5, $crop.Width * $scale, $crop.Height * $scale)
  $g.DrawString($name, $font, [System.Drawing.Brushes]::White, $x0 + 4, $y0 + $cell - 2)
  $crop.Dispose()
  $i++
}
foreach ($s in $sources.Values) { $s.Dispose() }
$sheet.Save($out)
$g.Dispose(); $sheet.Dispose()
Write-Output "OK"


