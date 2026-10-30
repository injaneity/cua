# Usage: repro.ps1 -Driver <cua-driver.exe> -Layout <KLID> -Label <name>
param([string]$Driver, [string]$Layout, [string]$Label)
$ErrorActionPreference = 'Stop'
$out = Join-Path $env:RUNNER_TEMP "$Label.txt"
$target = Start-Process pwsh -ArgumentList @('-STA', '-NoProfile', '-File', (Join-Path $PSScriptRoot 'target.ps1'), '-Layout', $Layout, '-Out', $out) -RedirectStandardError "$out.err" -PassThru
foreach ($i in 1..300) { if (Test-Path "$out.layout") { break }; if ($target.HasExited) { break }; Start-Sleep -Milliseconds 200 }
if (-not (Test-Path "$out.layout")) { "target did not start (exited=$($target.HasExited))"; Get-Content "$out.err" -ErrorAction SilentlyContinue; return }
Start-Sleep -Seconds 1
"layout on target thread: $(Get-Content "$out.layout")"
$p = $target.Id
# Thai Kedmanee: VK_A types U+0E1F, so press_key "ฟ" should send VK_A.
$thaiFo = [string][char]0x0E1F
$calls = @(
  @{ key = '|' },
  @{ key = '3' }, @{ key = '1' }, @{ key = 'a' }, @{ key = 'A' }, @{ key = $thaiFo },
  @{ key = '3'; delivery_mode = 'foreground' }, @{ key = 'a'; delivery_mode = 'foreground' },
  @{ key = $thaiFo; delivery_mode = 'foreground' },
  @{ key = '|' }
)
foreach ($c in $calls) {
  $c.pid = $p
  $json = $c | ConvertTo-Json -Compress
  $r = (& $Driver call press_key $json 2>&1 | Out-String).Trim()
  "press_key $json -> exit $LASTEXITCODE :: $($r -replace '\s+', ' ')"
  Start-Sleep -Milliseconds 400
}
$r = (& $Driver call type_text (@{ pid = $p; text = 'T:3a' } | ConvertTo-Json -Compress) 2>&1 | Out-String).Trim()
"type_text -> exit $LASTEXITCODE"
Start-Sleep -Seconds 1
$text = [IO.File]::ReadAllText($out, [Text.Encoding]::UTF8)
"RESULT [$Label] text box: <$text>"
"RESULT [$Label] code points: " + (($text.ToCharArray() | ForEach-Object { 'U+{0:X4}' -f [int]$_ }) -join ' ')
Stop-Process -Id $p -Force -ErrorAction SilentlyContinue
