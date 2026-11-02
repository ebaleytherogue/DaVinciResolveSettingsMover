# DaVinci Resolve Settings Mover
# Conservative settings/presets/templates/LUT mover
# Preferences are exported for manual reference only, not restored automatically.

$ScriptVersion = "1.1"
$Root = "C:\apps\DaVinciResolveSettingsMover"
$Exports = Join-Path $Root "exports"
$Backups = Join-Path $Root "backups"
$Logs = Join-Path $Root "logs"
$Temp = Join-Path $Root "temp"
$SevenZip = "C:\Program Files\7-Zip\7z.exe"

$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$RunTemp = Join-Path $Temp "run-$Timestamp"
$LogFile = Join-Path $Logs "DaVinciResolveSettingsMover-$Timestamp.log"

$SettingsItems = @(
    @{
        Name = "User Fusion Support"
        Source = "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Fusion"
        RelativePath = "AppDataRoaming\Blackmagic Design\DaVinci Resolve\Support\Fusion"
        Type = "Folder"
        RestoreOnImport = $true
    },
    @{
        Name = "User LUTs"
        Source = "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\LUT"
        RelativePath = "AppDataRoaming\Blackmagic Design\DaVinci Resolve\Support\LUT"
        Type = "Folder"
        RestoreOnImport = $true
    },
    @{
        Name = "User Presets"
        Source = "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Presets"
        RelativePath = "AppDataRoaming\Blackmagic Design\DaVinci Resolve\Support\Presets"
        Type = "Folder"
        RestoreOnImport = $true
    },
    @{
        Name = "Keyboard Customization"
        Source = "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Support\Keyboards"
        RelativePath = "AppDataRoaming\Blackmagic Design\DaVinci Resolve\Support\Keyboards"
        Type = "Folder"
        RestoreOnImport = $true
    },
    @{
        Name = "Resolve Preferences Folder - BACKUP ONLY"
        Source = "$env:APPDATA\Blackmagic Design\DaVinci Resolve\Preferences"
        RelativePath = "AppDataRoaming\Blackmagic Design\DaVinci Resolve\Preferences"
        Type = "Folder"
        RestoreOnImport = $false
    }
)

function Initialize-Folders {
    foreach ($Folder in @($Root, $Exports, $Backups, $Logs, $Temp, $RunTemp)) {
        if (!(Test-Path $Folder)) {
            New-Item -ItemType Directory -Path $Folder -Force | Out-Null
        }
    }
}

function Write-Log {
    param([string]$Message)
    $Line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  $Message"
    Write-Host $Line
    Add-Content -Path $LogFile -Value $Line
}

function Confirm-SevenZip {
    if (!(Test-Path $SevenZip)) {
        throw "7-Zip was not found at $SevenZip"
    }
}

function Confirm-ResolveClosed {
    $Process = Get-Process -Name "Resolve" -ErrorAction SilentlyContinue
    if ($Process) {
        throw "DaVinci Resolve appears to be running. Please close Resolve and run this script again."
    }
}

function Get-DestinationPath {
    param([string]$RelativePath)

    if ($RelativePath.StartsWith("AppDataRoaming\")) {
        return Join-Path $env:APPDATA ($RelativePath.Substring("AppDataRoaming\".Length))
    }

    throw "Unknown destination mapping: $RelativePath"
}

function New-Manifest {
    param([array]$IncludedItems)

    $Manifest = [ordered]@{
        Tool = "DaVinci Resolve Settings Mover"
        ScriptVersion = $ScriptVersion
        ExportedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SourceComputer = $env:COMPUTERNAME
        SourceUser = $env:USERNAME
        IncludedItems = $IncludedItems
        Exclusions = @(
            "Project libraries",
            "Resolve databases",
            "Project files",
            "Cache files",
            "Optimized media",
            "Proxy media",
            "Render cache",
            "Automatic restore of Preferences folder"
        )
    }

    return $Manifest
}

function Export-Settings {
    Write-Log "Starting export."
    Confirm-SevenZip
    Confirm-ResolveClosed

    $Payload = Join-Path $RunTemp "payload"
    New-Item -ItemType Directory -Path $Payload -Force | Out-Null

    $IncludedItems = @()

    foreach ($Item in $SettingsItems) {
        if (Test-Path $Item.Source) {
            $Target = Join-Path $Payload $Item.RelativePath
            $TargetParent = Split-Path $Target -Parent
            New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null

            Write-Log "Copying: $($Item.Name)"
            Copy-Item -Path $Item.Source -Destination $Target -Recurse -Force

            $IncludedItems += [ordered]@{
                Name = $Item.Name
                RelativePath = $Item.RelativePath
                Type = $Item.Type
                RestoreOnImport = $Item.RestoreOnImport
            }
        }
        else {
            Write-Log "Skipping missing item: $($Item.Name) [$($Item.Source)]"
        }
    }

    $Manifest = New-Manifest -IncludedItems $IncludedItems
    $ManifestPath = Join-Path $Payload "manifest.json"
    $Manifest | ConvertTo-Json -Depth 6 | Set-Content -Path $ManifestPath -Encoding UTF8

    $Archive = Join-Path $Exports "DaVinciResolveSettingsExport-$Timestamp.7z"

    Write-Log "Creating archive: $Archive"
    & $SevenZip a -t7z $Archive "$Payload\*" | Out-Null

    Write-Log "Export complete: $Archive"
}

function Select-Archive {
    $Archives = Get-ChildItem -Path $Exports -Filter "*.7z" -File | Sort-Object LastWriteTime -Descending

    if (!$Archives) {
        throw "No .7z files were found in $Exports"
    }

    Write-Host ""
    Write-Host "Available export archives:"
    for ($i = 0; $i -lt $Archives.Count; $i++) {
        Write-Host "$($i + 1). $($Archives[$i].Name)"
    }

    $Choice = Read-Host "Choose an archive number"
    $Index = [int]$Choice - 1

    if ($Index -lt 0 -or $Index -ge $Archives.Count) {
        throw "Invalid archive selection."
    }

    return $Archives[$Index].FullName
}

function Extract-Archive {
    param([string]$Archive)

    $ExtractPath = Join-Path $RunTemp "extracted"
    New-Item -ItemType Directory -Path $ExtractPath -Force | Out-Null

    Write-Log "Extracting archive to temp folder."
    & $SevenZip x $Archive "-o$ExtractPath" -y | Out-Null

    return $ExtractPath
}

function Validate-ExtractedArchive {
    param([string]$ExtractPath)

    $ManifestPath = Join-Path $ExtractPath "manifest.json"

    if (!(Test-Path $ManifestPath)) {
        throw "Archive is missing manifest.json."
    }

    $Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

    if ($Manifest.Tool -ne "DaVinci Resolve Settings Mover") {
        throw "Archive manifest does not identify this as a valid settings mover archive."
    }

    Write-Log "Archive validated."
    Write-Log "Source computer: $($Manifest.SourceComputer)"
    Write-Log "Source user: $($Manifest.SourceUser)"
    Write-Log "Exported at: $($Manifest.ExportedAt)"
    Write-Log "Script version: $($Manifest.ScriptVersion)"

    return $Manifest
}

function Backup-ExistingSettings {
    param($Manifest)

    $BackupPayload = Join-Path $RunTemp "backup-payload"
    New-Item -ItemType Directory -Path $BackupPayload -Force | Out-Null

    $BackedUpAnything = $false

    foreach ($Item in $Manifest.IncludedItems) {
        $Destination = Get-DestinationPath -RelativePath $Item.RelativePath

        if (Test-Path $Destination) {
            $BackupTarget = Join-Path $BackupPayload $Item.RelativePath
            $BackupParent = Split-Path $BackupTarget -Parent
            New-Item -ItemType Directory -Path $BackupParent -Force | Out-Null

            Write-Log "Backing up existing destination: $Destination"
            Copy-Item -Path $Destination -Destination $BackupTarget -Recurse -Force
            $BackedUpAnything = $true
        }
        else {
            Write-Log "No existing destination to back up: $Destination"
        }
    }

    $BackupArchive = Join-Path $Backups "DaVinciResolveSettingsBackup-$Timestamp.7z"

    if ($BackedUpAnything) {
        Write-Log "Creating backup archive: $BackupArchive"
        & $SevenZip a -t7z $BackupArchive "$BackupPayload\*" | Out-Null
        Write-Log "Backup complete: $BackupArchive"
    }
    else {
        Write-Log "No existing settings were found to back up."
    }
}

function Import-Settings {
    param([bool]$DryRun)

    if ($DryRun) {
        Write-Log "Starting dry-run import."
    }
    else {
        Write-Log "Starting import."
    }

    Confirm-SevenZip
    Confirm-ResolveClosed

    $Archive = Select-Archive
    Write-Log "Selected archive: $Archive"

    $ExtractPath = Extract-Archive -Archive $Archive
    $Manifest = Validate-ExtractedArchive -ExtractPath $ExtractPath

    foreach ($Item in $Manifest.IncludedItems) {
        $Source = Join-Path $ExtractPath $Item.RelativePath
        $Destination = Get-DestinationPath -RelativePath $Item.RelativePath

        if ($Item.RestoreOnImport -eq $false) {
            Write-Log "Backup-only item, not restored by script: $($Item.Name)"
            Write-Log "Contained in archive at: $Source"
            continue
        }

        if (Test-Path $Source) {
            Write-Log "Ready to restore: $($Item.Name)"
            Write-Log "Source: $Source"
            Write-Log "Destination: $Destination"
        }
        else {
            Write-Log "WARNING: Expected item missing from archive payload: $($Item.Name)"
        }
    }

    if ($DryRun) {
        Write-Log "Dry run complete. No files were changed."
        return
    }

    Backup-ExistingSettings -Manifest $Manifest

    foreach ($Item in $Manifest.IncludedItems) {
        if ($Item.RestoreOnImport -eq $false) {
            Write-Log "Skipping backup-only item during restore: $($Item.Name)"
            continue
        }

        $Source = Join-Path $ExtractPath $Item.RelativePath
        $Destination = Get-DestinationPath -RelativePath $Item.RelativePath

        if (Test-Path $Source) {
            $DestinationParent = Split-Path $Destination -Parent
            New-Item -ItemType Directory -Path $DestinationParent -Force | Out-Null

            Write-Log "Restoring: $($Item.Name)"
            Copy-Item -Path $Source -Destination $DestinationParent -Recurse -Force
        }
    }

    Write-Log "Import complete."
}

function Validate-ArchiveOnly {
    Write-Log "Starting archive validation."

    Confirm-SevenZip
    $Archive = Select-Archive
    Write-Log "Selected archive: $Archive"

    $ExtractPath = Extract-Archive -Archive $Archive
    $Manifest = Validate-ExtractedArchive -ExtractPath $ExtractPath

    foreach ($Item in $Manifest.IncludedItems) {
        $Path = Join-Path $ExtractPath $Item.RelativePath

        if (Test-Path $Path) {
            if ($Item.RestoreOnImport -eq $false) {
                Write-Log "Found backup-only item: $($Item.Name)"
            }
            else {
                Write-Log "Found restorable item: $($Item.Name)"
            }
        }
        else {
            Write-Log "Missing: $($Item.Name)"
        }
    }

    Write-Log "Validation complete. No files were changed."
}

function Cleanup-RunTemp {
    if (Test-Path $RunTemp) {
        Write-Log "Cleaning this run's temp folder: $RunTemp"
        Remove-Item -Path $RunTemp -Recurse -Force
    }
}

Initialize-Folders

try {
    Write-Log "DaVinci Resolve Settings Mover v$ScriptVersion started."

    Write-Host ""
    Write-Host "DaVinci Resolve Settings Mover"
    Write-Host ""
    Write-Host "1. Export settings"
    Write-Host "2. Import settings"
    Write-Host "3. Dry-run import"
    Write-Host "4. Validate export archive"
    Write-Host "5. Exit"
    Write-Host ""

    $Choice = Read-Host "Choose an option"

    switch ($Choice) {
        "1" { Export-Settings }
        "2" { Import-Settings -DryRun $false }
        "3" { Import-Settings -DryRun $true }
        "4" { Validate-ArchiveOnly }
        "5" { Write-Log "Exiting."; return }
        default { Write-Log "Invalid choice." }
    }
}
catch {
    Write-Log "ERROR: $($_.Exception.Message)"
}
finally {
    Cleanup-RunTemp
    Write-Log "Done."
}

