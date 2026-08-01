New-Item -ItemType Directory -Force "$PSScriptRoot\out" | Out-Null
Add-Type -AssemblyName System.Drawing
$src = "c:\Users\camille\Eluminia\public\art"
$out = "$PSScriptRoot\out\crops-qa-ui.png"

$crops = @(
  @("portrait","image1.png",1082,449,62,62,46),
  @("icon-scroll","image1.png",1094,508,64,66,46),
  @("icon-pack","image1.png",1176,506,66,68,46),
  @("icon-map2","image1.png",1264,508,66,64,46),
  @("coin","image1.png",1316,460,32,32,46),
  @("gem","image1.png",1398,461,30,29,46),
  @("star","image1.png",1460,459,32,31,46)
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
Write-Output "OK : $out"
