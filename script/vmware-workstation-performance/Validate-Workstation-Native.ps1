<#
.SYNOPSIS
  Validates that Hyper-V/VBS are disabled for native VMware Workstation performance,
  lists running Workstation VMs, and detects whether each VM uses native VT-x/AMD-V
  or Windows Hypervisor Platform (WHP/Hyper-V).

.DESCRIPTION
  Produces:
    1) Host checks:
       - Hyper-V / WHP / VMP / Sandbox state
       - Boot config (hypervisorlaunchtype)
       - Device Guard / VBS / HVCI state
       - Hypervisor presence hint (systeminfo)
       - WHP kernel driver status (winhv)
    2) VMware checks:
       - Auto-detects vmrun.exe
       - Lists running VMs (vmrun list)
       - Reads each VM’s latest vmware.log and heuristically reports:
         * "native (VT-x/AMD-V)" or "via Hyper-V (WHP)" or "unknown"

.PARAMETER VmrunPath
  Optional explicit path to vmrun.exe. Auto-detection covers most installs.

.NOTES
  v1.2 – Robust bcdedit parsing, non-admin friendly, vmrun auto-detect (PATH, registry, common folders, shallow search).
#>

[CmdletBinding()]
param(
  [string]$VmrunPath
)

function Test-IsAdmin {
  try {
    return ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
  } catch { return $false }
}

function Get-HyperVHostState {
  Write-Host "== Host virtualization/security state ==" -ForegroundColor Cyan

  $features = @(
    "Microsoft-Hyper-V-All",
    "WindowsHypervisorPlatform",
    "VirtualMachinePlatform",
    "Containers-DisposableClientVM"
  )

  $featStates = @{}
  foreach ($f in $features) {
    try {
      $res = Get-WindowsOptionalFeature -Online -FeatureName $f -ErrorAction Stop
      $featStates[$f] = $res.State
    } catch {
      $featStates[$f] = "Unknown"
    }
  }

  # Boot hypervisorlaunchtype
  $hlt = "Unknown"
  if (Test-IsAdmin) {
    try {
      $bcd = (bcdedit /enum {current} 2>$null)
      if ($bcd) {
        $m = ($bcd | Select-String -Pattern 'hypervisorlaunchtype\s+(\w+)' -AllMatches)
        if ($m -and $m.Matches.Count -gt 0) { $hlt = $m.Matches[0].Groups[1].Value }
        else { $hlt = "Not set" }
      } else {
        $hlt = "Unknown (no output)"
      }
    } catch {
      $hlt = "Unknown (bcdedit error)"
    }
  } else {
    $hlt = "Unknown (not elevated)"
  }

  # Device Guard / VBS / HVCI
  $vbsState = "Unknown"
  $hvci = "Unknown"
  try {
    $dg = Get-CimInstance -ClassName Win32_DeviceGuard -ErrorAction Stop
    $vbsState = switch ($dg.VirtualizationBasedSecurityStatus) {
      0 {'Disabled'} 1 {'Enabled - Not Running'} 2 {'Running'} default {'Unknown'}
    }
    $hvci = if ($dg.HypervisorEnforcedCodeIntegrity) { 'Enabled' } else { 'Disabled' }
  } catch { }

  # systeminfo hypervisor hint
  $hypervisorDetected = "No/Unknown"
  $sysInfo = ""
  try {
    $sysInfo = (systeminfo 2>$null | Select-String -Pattern 'Hyper-V Requirements|A hypervisor has been detected' -SimpleMatch) -join "`n"
    if ($sysInfo -match 'A hypervisor has been detected') { $hypervisorDetected = 'Yes' }
  } catch { }

  # WHP kernel driver
  $winhvState = "Unknown"
  try {
    $winhv = Get-CimInstance Win32_SystemDriver -Filter "Name='WinHv'" -ErrorAction Stop
    $winhvState = if ($winhv) { $winhv.State } else { 'Not present' }
  } catch {
    $winhvState = 'Not present'
  }

  [pscustomobject]@{
    HyperV_All                = $featStates['Microsoft-Hyper-V-All']
    WindowsHypervisorPlatform = $featStates['WindowsHypervisorPlatform']
    VirtualMachinePlatform    = $featStates['VirtualMachinePlatform']
    WindowsSandbox            = $featStates['Containers-DisposableClientVM']
    BCD_HypervisorLaunchType  = $hlt
    VBS_Status                = $vbsState
    HVCI                      = $hvci
    Hypervisor_Detected       = $hypervisorDetected
    WHP_Driver_winhv          = $winhvState
    SystemInfo_Snippet        = $sysInfo
  }
}

function Resolve-VmrunPath {
  param([string]$VmrunPath)

  # 0) Respect explicit parameter
  if ($VmrunPath -and (Test-Path $VmrunPath)) {
    return (Resolve-Path $VmrunPath).Path
  }

  # 1) Try PATH
  try {
    $cmd = Get-Command vmrun.exe -ErrorAction Stop
    if ($cmd -and (Test-Path $cmd.Source)) { return $cmd.Source }
  } catch {}

  # 2) Registry – official install path (both 64/32-bit views)
  $regKeys = @(
    'HKLM:\SOFTWARE\VMware, Inc.\VMware Workstation',
    'HKLM:\SOFTWARE\WOW6432Node\VMware, Inc.\VMware Workstation'
  )
  foreach ($k in $regKeys) {
    try {
      $ip = (Get-ItemProperty -Path $k -Name InstallPath -ErrorAction Stop).InstallPath
      if ($ip) {
        $candidate = Join-Path $ip 'vmrun.exe'
        if (Test-Path $candidate) { return (Resolve-Path $candidate).Path }
      }
    } catch {}
  }

  # 3) Common install folders
  $pf  = ${env:ProgramFiles}
  $pfx = ${env:ProgramFiles(x86)}
  $candidates = @(
    (Join-Path $pf  'VMware\VMware Workstation\vmrun.exe'),
    (Join-Path $pfx 'VMware\VMware Workstation\vmrun.exe'),
    (Join-Path $pf  'VMware\VMware Player\vmrun.exe'),
    (Join-Path $pfx 'VMware\VMware Player\vmrun.exe')
  ) | Where-Object { $_ -and (Test-Path $_) }
  if ($candidates.Count -gt 0) { return (Resolve-Path $candidates[0]).Path }

  # 4) Last resort: shallow search under VMware folders
  $roots = @($pf, $pfx) | Where-Object { $_ -and (Test-Path $_) }
  foreach ($root in $roots) {
    $vmwareDirs = Get-ChildItem -Path (Join-Path $root 'VMware') -Directory -ErrorAction SilentlyContinue
    foreach ($d in $vmwareDirs) {
      $hit = Get-ChildItem -Path $d.FullName -Filter vmrun.exe -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
      if ($hit) { return (Resolve-Path $hit.FullName).Path }
    }
  }

  Write-Warning "vmrun.exe not found. Install VMware Workstation or pass -VmrunPath 'C:\Full\Path\vmrun.exe'."
  return $null
}

function Get-RunningVMs {
  param([string]$Vmrun)
  if (-not $Vmrun) { return @() }
  $raw = & $Vmrun list 2>$null
  if (-not $raw) { return @() }

  $paths = @()
  foreach ($line in $raw) { if ($line -like '*.vmx') { $paths += $line.Trim() } }
  return $paths
}

function Get-VMHypervisorMode {
  param([string]$VmxPath)

  $dir = Split-Path $VmxPath -Parent
  $logs = Get-ChildItem -Path $dir -Filter "vmware.log*" -ErrorAction SilentlyContinue |
          Sort-Object LastWriteTime -Descending
  if (-not $logs) {
    return [pscustomobject]@{ VMX=$VmxPath; Mode="unknown (no vmware.log)"; Evidence=""; LogFile=""; LogUpdated=$null }
  }

  $logFile = $logs[0]
  $text = (Get-Content -Path $logFile.FullName -Tail 400 -ErrorAction SilentlyContinue -Encoding UTF8) -join "`n"

  $mode = "unknown (check log)"
  $evidence = ""

  if ($text -match '(?i)\bWHPX?\b|Windows Hypervisor Platform|WHv|using Hyper-V|WinHv') {
    $mode = "via Hyper-V (WHP)"
    $evidence = (($text | Select-String -Pattern '(?i)WHPX?|Windows Hypervisor Platform|WHv|Hyper-V|WinHv' -AllMatches | Select-Object -First 3) -join " | ")
  } elseif ($text -match '(?i)VT-x|AMD-V|VMX\s+enabled|SVM\s+enabled|Hardware virtualization') {
    $mode = "native (VT-x/AMD-V)"
    $evidence = (($text | Select-String -Pattern '(?i)VT-x|AMD-V|VMX\s+enabled|SVM\s+enabled|Hardware virtualization' -AllMatches | Select-Object -First 3) -join " | ")
  }

  [pscustomobject]@{
    VMX        = $VmxPath
    Mode       = $mode
    Evidence   = $evidence
    LogFile    = $logFile.Name
    LogUpdated = $logFile.LastWriteTime
  }
}

# ------- MAIN -------
$hostStateObj = Get-HyperVHostState
Write-Host ""
Write-Host "== VMware Workstation running VMs ==" -ForegroundColor Cyan

$vmrun = Resolve-VmrunPath -VmrunPath $VmrunPath
$vmxList = Get-RunningVMs -Vmrun $vmrun

if (-not $vmxList -or $vmxList.Count -eq 0) {
  Write-Host "No running VMs detected." -ForegroundColor Yellow
} else {
  $results = foreach ($vmx in $vmxList) { Get-VMHypervisorMode -VmxPath $vmx }
  $results | Sort-Object Mode, VMX | Format-Table -AutoSize VMX, Mode, LogFile, LogUpdated
}

Write-Host ""
Write-Host "== Host summary ==" -ForegroundColor Cyan
$hostStateObj | Format-List
