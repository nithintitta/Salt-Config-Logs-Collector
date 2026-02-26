# Written by Nithin Titta  | VCF GS Support
# Script to collect Logs, Diagnostic Data from Windows Salt Minion
# Script MUST be run as admin, It will need elivated previlages to query salt service, network configs, event viwer.  



if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Error: Please run as Administrator."
    exit
}

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Hostname = $env:COMPUTERNAME
$BundleName = "salt_diagnostic_${Hostname}_${Timestamp}"
$DestDir = "$env:TEMP\$BundleName"
$ArchiveDest = "$env:TEMP\${BundleName}.zip"

$SaltRoot = if (Test-Path "C:\ProgramData\Salt Project\Salt") { "C:\ProgramData\Salt Project\Salt" } else { "C:\salt" }
$SaltConfPath = "$SaltRoot\conf"
$SaltLogPath = "$SaltRoot\var\log\salt"

Write-Host "--- Initializing SaltStack Diagnostic Collection ---" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$DestDir\reports" | Out-Null
New-Item -ItemType Directory -Force -Path "$DestDir\services" | Out-Null
New-Item -ItemType Directory -Force -Path "$DestDir\events" | Out-Null

Write-Host "[1/9] Capturing Identity and Network Metadata..."
$IdReport = "$DestDir\reports\identity_metadata.txt"
"--- System Identity ---" | Out-File $IdReport -Encoding UTF8
"Hostname: $Hostname" | Out-File $IdReport -Append -Encoding UTF8

if (Test-Path "$SaltConfPath\minion_id") {
    $MinionId = Get-Content "$SaltConfPath\minion_id"
    "Minion ID (from file): $MinionId" | Out-File $IdReport -Append -Encoding UTF8
}

"`n--- Network Interface IPs ---" | Out-File $IdReport -Append -Encoding UTF8
(Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress | Out-File $IdReport -Append -Encoding UTF8

"`n--- Master Connection Info ---" | Out-File $IdReport -Append -Encoding UTF8
if (Test-Path "$SaltConfPath\minion") {
    $MasterLine = Select-String -Path "$SaltConfPath\minion" -Pattern "^master:" -Quiet
    if ($MasterLine) {
        Select-String -Path "$SaltConfPath\minion" -Pattern "^master:" | Select-Object -ExpandProperty Line | Out-File $IdReport -Append -Encoding UTF8
    } else {
        "Master: Default (salt)" | Out-File $IdReport -Append -Encoding UTF8
    }
}

Write-Host "[2/9] Capturing OS Information (systeminfo)..."
try { cmd.exe /c "systeminfo > ""$DestDir\reports\systeminfo.txt"" 2>&1" } catch {}

Write-Host "[3/9] Capturing Version Reports..."
try { cmd.exe /c "salt-minion --versions-report > ""$DestDir\reports\minion_versions.txt"" 2>&1" } catch {}

Write-Host "[4/9] Capturing Service Status..."
$Services = @("salt-minion") 
foreach ($svc in $Services) {
    $ServiceObj = Get-Service -Name $svc -ErrorAction SilentlyContinue
    if ($ServiceObj) {
        Write-Host "      -> Collecting $svc info"
        $ServiceObj | Format-List * | Out-File "$DestDir\services\${svc}_status.txt" -Encoding UTF8
        
        Get-WinEvent -LogName Application -MaxEvents 1000 -ErrorAction SilentlyContinue | 
            Where-Object { $_.ProviderName -match "salt" -or $_.Message -match "salt" } | 
            Format-Table TimeCreated, Id, LevelDisplayName, Message -AutoSize -Wrap | 
            Out-File "$DestDir\services\${svc}_quick_events.txt" -Encoding UTF8
    }
}

Write-Host "[5/9] Exporting Raw Windows Event Logs (.evtx)..."
Write-Host "      -> Exporting Application Log"
wevtutil epl Application "$DestDir\events\Application.evtx"
Write-Host "      -> Exporting System Log"
wevtutil epl System "$DestDir\events\System.evtx"

Write-Host "[6/9] Capturing Networking & Processes..."
Get-Process | Where-Object { $_.Name -match "salt|python|ssm" } | Format-Table -AutoSize | Out-File "$DestDir\reports\process_list.txt" -Encoding UTF8
Get-NetTCPConnection -ErrorAction SilentlyContinue | Where-Object { $_.LocalPort -in @(4505,4506) -or $_.RemotePort -in @(4505,4506) } | Format-Table -AutoSize | Out-File "$DestDir\reports\network_ports.txt" -Encoding UTF8

Write-Host "[7/9] Mirroring Configuration structures..."
if (Test-Path $SaltConfPath) {
    Copy-Item -Path $SaltConfPath -Destination "$DestDir\conf" -Recurse -Container -ErrorAction SilentlyContinue
}

Write-Host "[8/9] Mirroring Log structures..."
if (Test-Path $SaltLogPath) {
    Copy-Item -Path $SaltLogPath -Destination "$DestDir\log" -Recurse -Container -ErrorAction SilentlyContinue
}

Write-Host "[9/9] Capturing Live Salt Data..."
try { cmd.exe /c "salt-call --local grains.items > ""$DestDir\reports\minion_grains.txt"" 2>&1" } catch {}

Write-Host "--- Finalizing: Compressing bundle ---" -ForegroundColor Cyan
Compress-Archive -Path "$DestDir\*" -DestinationPath $ArchiveDest -Force
Remove-Item -Path $DestDir -Recurse -Force

Write-Host "------------------------------------------------"
Write-Host "Bundle Ready: $ArchiveDest" -ForegroundColor Green
Write-Host "------------------------------------------------"
