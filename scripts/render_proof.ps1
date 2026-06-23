<#
.SYNOPSIS
    tq-threads render proof: render the test suites + example wrappers, run
    negative/assert tests, and print a PASS/FAIL summary. Exits NONZERO on any
    failure. Runs on Windows PowerShell 5.1 and PowerShell 7+ (no PS7-only syntax).

.DESCRIPTION
    Robust by design -- official proof does NOT depend on fragile `-D SHOW="..."`
    string quoting. Example selection uses zero-`-D` wrapper .scad files (and the
    shell-safe numeric `-D PART=n` where a flag is used at all).

.PARAMETER OpenSCAD  Path to openscad(.com/.exe). If supplied, it must resolve exactly.
.PARAMETER Heavy     Also render the heavy visual grid (slow).
.PARAMETER OutDir    Output dir for STL artifacts (default: proof/).

.EXAMPLE  pwsh scripts/render_proof.ps1
.EXAMPLE  powershell -ExecutionPolicy Bypass -File scripts\render_proof.ps1 -Heavy

.NOTES
    OpenSCAD builds disagree about stdout vs stderr for assertions/version text.
    This script captures and checks both streams.
#>
[CmdletBinding()]
param([string]$OpenSCAD = "", [switch]$Heavy, [string]$OutDir = "proof")

$root = Split-Path -Parent $PSScriptRoot

function Resolve-OpenSCAD([string]$hint) {
    if ($hint) {
        $cmd = Get-Command $hint -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
        if (Test-Path $hint) { return (Resolve-Path $hint).Path }
        throw "OpenSCAD path not found: $hint"
    }
    $cands = @(
        "C:\Program Files\OpenSCAD\openscad.com", "C:\Program Files\OpenSCAD\openscad.exe",
        "C:\Program Files\OpenSCAD (Nightly)\openscad.com", "C:\Program Files\OpenSCAD (Nightly)\openscad.exe",
        "C:\Users\Scott\Desktop\CODE\_tools\openscad\openscad-2021.01\openscad.com",
        "C:\Users\Scott\Desktop\CODE\_tools\openscad\openscad-2021.01\openscad.exe",
        "openscad.com", "openscad")
    foreach ($c in $cands) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
        if (Test-Path $c) { return $c }
    }
    throw "OpenSCAD not found. Pass -OpenSCAD <path>."
}

function Resolve-Python() {
    $cands = @("py", "python3", "python")
    foreach ($c in $cands) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    throw "Python not found; required for independent STL mesh checks."
}

function Invoke-CapturedProcess([string]$exe, [string[]]$ArgList, [string]$basePath) {
    $stdout = "$basePath.stdout.txt"
    $stderr = "$basePath.stderr.txt"
    $log    = "$basePath.log.txt"
    $cleanArgs = @($ArgList | Where-Object { $null -ne $_ -and $_ -ne "" })
    $p = Start-Process -FilePath $exe -ArgumentList $cleanArgs -NoNewWindow -Wait -PassThru `
                       -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $outText = if (Test-Path $stdout) { Get-Content $stdout -Raw } else { "" }
    $errText = if (Test-Path $stderr) { Get-Content $stderr -Raw } else { "" }
    $combined = $outText + $errText
    [System.IO.File]::WriteAllText($log, $combined, [System.Text.UTF8Encoding]::new($false))
    return [pscustomobject]@{
        ExitCode = $p.ExitCode
        Stdout   = $outText
        Stderr   = $errText
        Text     = $combined
        Log      = $log
    }
}

function Invoke-MeshCheck([string]$name, [string]$stl) {
    $checker = Join-Path $root "scripts/check_stl_mesh.py"
    if (!(Test-Path $checker)) { return [pscustomobject]@{ Ok=$false; Text="mesh checker missing: $checker" } }
    $py = Resolve-Python
    $base = Join-Path $outAbs "$name.meshcheck"
    if ((Split-Path -Leaf $py) -ieq "py.exe" -or (Split-Path -Leaf $py) -ieq "py") {
        $args = @("-3", $checker, $stl, "--expect-manifold")
    } else {
        $args = @($checker, $stl, "--expect-manifold")
    }
    $cap = Invoke-CapturedProcess $py $args $base
    return [pscustomobject]@{ Ok=($cap.ExitCode -eq 0); Text=$cap.Text }
}

$oscad = Resolve-OpenSCAD $OpenSCAD
$script:oscad = $oscad
$outAbs = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $root $OutDir }
New-Item -ItemType Directory -Force -Path $outAbs | Out-Null
$verCap = Invoke-CapturedProcess $oscad @("--version") (Join-Path $outAbs "_version")
$verRaw = if ($verCap.Text.Trim()) { $verCap.Text.Trim() } else { "unknown" }

Write-Host "============================================================"
Write-Host " tq-threads render proof"
Write-Host " OpenSCAD : $oscad"
Write-Host " Version  : $verRaw"
Write-Host " Output   : $outAbs"
Write-Host "============================================================"

$pass = 0; $fail = 0; $rows = @()

# ---- run one render, return $true on success -------------------------------
function Invoke-Render([string]$name, [string]$scad, [string]$desc, [string[]]$ExtraArgs = @()) {
    $stl = Join-Path $outAbs "$name.stl"
    $sw  = [System.Diagnostics.Stopwatch]::StartNew()
    $args = @("-o", $stl) + $ExtraArgs + @($scad)
    $cap = Invoke-CapturedProcess $script:oscad $args (Join-Path $outAbs $name)
    $sw.Stop()
    $secs = [math]::Round($sw.Elapsed.TotalSeconds, 1)
    $warn = $cap.Text -match "WARNING|ERROR|not a valid 2-manifold"
    $facets = if ($cap.Text -match "Facets:\s*(\d+)") { $Matches[1] } else { "-" }
    $mesh = if (($cap.ExitCode -eq 0) -and (Test-Path $stl) -and ((Get-Item $stl).Length -gt 0)) {
        Invoke-MeshCheck $name $stl
    } else {
        [pscustomobject]@{ Ok=$false; Text="render did not produce a nonempty STL" }
    }
    $ok = ($cap.ExitCode -eq 0) -and (Test-Path $stl) -and ((Get-Item $stl).Length -gt 0) -and (-not $warn) -and $mesh.Ok
    $script:rows += [pscustomobject]@{ Test=$name; Kind="render"; Result=$(if($ok){"PASS"}else{"FAIL"}); Sec=$secs; Facets=$facets; Note=$desc }
    if ($ok) { $script:pass++ } else {
        $script:fail++
        if ($cap.Text) { Write-Host "  [$name] OpenSCAD output:`n$($cap.Text)" -ForegroundColor DarkYellow }
        if (-not $mesh.Ok) { Write-Host "  [$name] mesh check:`n$($mesh.Text)" -ForegroundColor DarkYellow }
    }
    return $ok
}

# ---- run one NEGATIVE test: expect a NONZERO exit (an assert must fire) -----
function Invoke-Negative([string]$name, [string]$snippet) {
    $tmp = Join-Path $env:TEMP "tqneg_$name.scad"
    $stl = Join-Path $env:TEMP "tqneg_$name.stl"
    $base = Join-Path $env:TEMP "tqneg_$name"
    [System.IO.File]::WriteAllText($tmp, "include <tq_threads.scad>`n$snippet", [System.Text.UTF8Encoding]::new($false))
    $oldp = $env:OPENSCADPATH; $env:OPENSCADPATH = $root
    $cap = Invoke-CapturedProcess $script:oscad @("-o", $stl, $tmp) $base
    $env:OPENSCADPATH = $oldp
    $ok = ($cap.ExitCode -ne 0) -and ($cap.Text -match "assert")   # PASS only when an assert rejects it
    $script:rows += [pscustomobject]@{ Test=$name; Kind="negative"; Result=$(if($ok){"PASS"}else{"FAIL"}); Sec="-"; Facets="-"; Note="must reject" }
    if ($ok) { $script:pass++ } else { $script:fail++; if ($cap.Text) { Write-Host "  [$name] OpenSCAD output:`n$($cap.Text)" -ForegroundColor DarkYellow } }
    Remove-Item $tmp,$stl,"$base.stdout.txt","$base.stderr.txt","$base.log.txt" -ErrorAction SilentlyContinue
    return $ok
}

# ============================ POSITIVE RENDERS ==============================
Write-Host "`n-- standards self-test + suites --"
Invoke-Render "selftest"   (Join-Path $root "tq_threads_selftest.scad")    "preset table + ISO 965 asserts" | Out-Null
$fastScad = Join-Path $root "tq_threads_fast_tests.scad"
foreach ($i in 0..36) {
    Invoke-Render ("fast_{0:00}" -f $i) $fastScad ("fast smoke cell {0}" -f $i) @("-D", "TQ_FAST_PART=$i") | Out-Null
}
if ($Heavy) { Invoke-Render "heavy" (Join-Path $root "tq_threads_heavy_tests.scad") "full visual grid" | Out-Null }

Write-Host "`n-- example wrappers (zero -D, every shell) --"
foreach ($w in "bolt","hexbolt","nut","csk_bolt","washer","wood","coupler","standoff","cap","auger","phillips","tap") {
    Invoke-Render "ex_$w" (Join-Path $root "examples/$w.scad") "examples/$w.scad" | Out-Null
}

# ============================ NEGATIVE TESTS ===============================
Write-Host "`n-- negative / assert tests (must reject) --"
Invoke-Negative "bad_d"        'tq_thread(-3,0.5,6);'                       | Out-Null
Invoke-Negative "bad_pitch"    'tq_thread(6,0,6);'                          | Out-Null
Invoke-Negative "bad_length"   'tq_thread(6,1,0);'                          | Out-Null
Invoke-Negative "bad_hand"     'tq_thread(6,1,6,hand="up");'               | Out-Null
Invoke-Negative "bad_profile"  'tq_thread(6,1,6,profile="triangle");'      | Out-Null
Invoke-Negative "bad_starts"   'tq_thread(6,1,6,starts=0);'                | Out-Null
Invoke-Negative "bad_arc"      'tq_thread(6,1,6,arc=400);'                 | Out-Null
Invoke-Negative "fit_mismatch" 'tq_thread(6,1,6,fit="6H");'               | Out-Null
Invoke-Negative "fit_unknown"  'tq_thread(6,1,6,fit="2A");'               | Out-Null
Invoke-Negative "bad_minor_d"  'tq_thread(10,1.5,6,minor_d=12);'           | Out-Null
Invoke-Negative "bad_taper"    'tq_thread(10,1.5,6,taper=20);'             | Out-Null
Invoke-Negative "wood_core"    'tq_wood_screw(5,20,core_d=6);'             | Out-Null
Invoke-Negative "bolt_shank"   'tq_bolt(6,1,10,shank=10);'                 | Out-Null
Invoke-Negative "bad_thread_size" 'tq_thread(6,1,6,thread_size=2);'         | Out-Null
Invoke-Negative "bad_thread_size_rect" 'tq_thread(6,1,6,profile="rectangle",thread_size=2);' | Out-Null
Invoke-Negative "bad_thread_size_square_internal" 'tq_thread(6,1,6,internal=true,profile="square",thread_size=2);' | Out-Null
Invoke-Negative "bad_side_angle"  'tq_thread(6,1,6,side_angle=90);'         | Out-Null
Invoke-Negative "bad_rect_ratio"  'tq_thread(6,1,6,profile="rectangle",rect_ratio=0);' | Out-Null
Invoke-Negative "bad_lead_ends"   'tq_thread(6,1,6,lead_ends="middle");'    | Out-Null

# ================================ SUMMARY ==================================
Write-Host "`n============================================================"
$rows | Format-Table -AutoSize | Out-String | Write-Host
$total = $pass + $fail
Write-Host ("RESULT: {0}/{1} passed  ({2} render, {3} negative)" -f $pass, $total, ($rows | Where-Object {$_.Kind -eq 'render'}).Count, ($rows | Where-Object {$_.Kind -eq 'negative'}).Count)
Write-Host " OpenSCAD: $verRaw"
if ($fail -gt 0) { Write-Host "PROOF FAILED ($fail)" -ForegroundColor Red; exit 1 }
Write-Host "PROOF PASSED" -ForegroundColor Green
exit 0
