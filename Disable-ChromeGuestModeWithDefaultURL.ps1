# Disable-ChromeGuestModeWithDefaultURL.ps1
# Restores Google Chrome's normal default launch behavior.

# --- START: Administrator Privilege Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    Write-Host "Please right-click on the script and select 'Run as administrator'."
    Read-Host "Press Enter to exit."
    exit 1
}
# --- END: Administrator Privilege Check ---

$DefaultURL = "galenotest1.web.app" # <--- Must be the SAME as in the activation script
$GuestArgument = "--guest"
Write-Host "Starting restoration of Chrome's normal default configuration..." -ForegroundColor Cyan

# --- START: Find Chrome Path (CORRECTED VERSION) ---
function Get-ChromePath {
    $chromePath = $null
    $chromeExecutableName = "chrome.exe"

    # Priority 1: Common environment variables
    $baseInstallPaths = @(
        [System.Environment]::GetEnvironmentVariable("ProgramFiles"),
        [System.Environment]::GetEnvironmentVariable("ProgramFiles(x86)"),
        [System.Environment]::GetEnvironmentVariable("LOCALAPPDATA")
    )
    $chromeSubDir = "Google\Chrome\Application"

    foreach ($basePath in $baseInstallPaths) {
        if (-not [string]::IsNullOrEmpty($basePath)) {
            try {
                $fullAppDir = Join-Path -Path $basePath -ChildPath $chromeSubDir -ErrorAction SilentlyContinue
                if ($fullAppDir -and (Test-Path $fullAppDir -PathType Container)) {
                    $exePath = Join-Path -Path $fullAppDir -ChildPath $chromeExecutableName -ErrorAction SilentlyContinue
                    if ($exePath -and (Test-Path $exePath -PathType Leaf)) {
                        $chromePath = $exePath
                        Write-Verbose "Chrome found via environment variable path: $chromePath"
                        return $chromePath # Found, exit function
                    }
                }
            } catch {
                Write-Verbose "Exception constructing path from '$basePath': $($_.Exception.Message)"
            }
        }
    }

    # Priority 2: Registry (uninstall keys)
    Write-Verbose "Chrome not found in common paths, checking Registry..."
    try {
        $uninstallKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
            "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome",
            "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Google Chrome", # User-specific install
            "HKCU:\SOFTWARE\Google\Chrome\BLBeacon" 
        )
        foreach ($keyPath in $uninstallKeys) {
             if (Test-Path $keyPath) {
                $props = Get-ItemProperty -Path $keyPath -ErrorAction SilentlyContinue
                
                $pathsToTest = [System.Collections.Generic.List[string]]::new()
                
                if ($props.InstallLocation) {
                    $pathsToTest.Add((Join-Path -Path $props.InstallLocation -ChildPath $chromeExecutableName))
                }
                if ($props.DisplayIcon) {
                    # DisplayIcon might be "C:\Path\To\chrome.exe,0", remove the ",index" part
                    $pathsToTest.Add(($props.DisplayIcon -split ',')[0].Trim('"'))
                }
                 if ($props.ApplicationPath) { # Used by HKCU\SOFTWARE\Google\Chrome\BLBeacon
                     $pathsToTest.Add((Join-Path -Path $props.ApplicationPath -ChildPath $chromeExecutableName))
                 }

                foreach ($potentialPath in $pathsToTest) {
                    if (-not [string]::IsNullOrEmpty($potentialPath) -and (Test-Path $potentialPath -PathType Leaf)) {
                        $chromePath = $potentialPath
                        Write-Verbose "Chrome found via Registry ('$keyPath'): $chromePath"
                        return $chromePath # Found, exit function
                    }
                }
            }
        }
    } catch {
         Write-Verbose "Exception checking Registry: $($_.Exception.Message)"
    }
    
    if (-not $chromePath) {
        Write-Verbose "Chrome could not be located after all checks."
    }
    return $chromePath
}
# --- END: Find Chrome Path (CORRECTED VERSION) ---

$ChromeExePath = Get-ChromePath
if ($ChromeExePath) {
    Write-Host "Chrome found at: $ChromeExePath" -ForegroundColor Green
} else {
    Write-Warning "Google Chrome installation could not be found. Will attempt to revert settings anyway."
}

# --- START: Modify Shortcuts ---
Write-Host "Restoring shortcuts..." -ForegroundColor Cyan
$GuestArgumentPattern = [regex]::Escape($GuestArgument)
$DefaultURLPattern = [regex]::Escape($DefaultURL)
$QuotedDefaultURLPattern = [regex]::Escape("`"$DefaultURL`"") 

$shortcutLocations = @(
    ([System.Environment]::GetFolderPath('Desktop')),
    ([System.Environment]::GetFolderPath('CommonDesktopDirectory')),
    ([System.Environment]::GetFolderPath('StartMenu') + "\Programs"),
    ([System.Environment]::GetFolderPath('CommonStartMenu') + "\Programs")
)

$WshShell = New-Object -ComObject WScript.Shell
$modifiedShortcutsCount = 0

foreach ($location in $shortcutLocations) {
    if (Test-Path $location) {
        Get-ChildItem -Path $location -Recurse -Filter "*.lnk" | ForEach-Object {
            try {
                $shortcut = $WshShell.CreateShortcut($_.FullName)
                if (($ChromeExePath -and $shortcut.TargetPath -eq $ChromeExePath) -or (-not $ChromeExePath -and $shortcut.TargetPath -like "*chrome.exe*")) {
                    Write-Verbose "Processing shortcut: $($_.FullName)"
                    $currentArgs = $shortcut.Arguments
                    $originalArgs = $currentArgs 

                    $newArgs = $currentArgs
                    $newArgs = $newArgs -replace $GuestArgumentPattern, ""
                    $newArgs = $newArgs -replace $QuotedDefaultURLPattern, "" 
                    $newArgs = $newArgs -replace $DefaultURLPattern, ""       
                    
                    $newArgs = $newArgs.Trim() -replace "\s{2,}", " " 
                    
                    if ($originalArgs -ne $newArgs) {
                        $shortcut.Arguments = $newArgs
                        $shortcut.Save()
                        Write-Host "  Restored: $($_.FullName) - New arguments: '$($shortcut.Arguments)'" -ForegroundColor Green
                        $modifiedShortcutsCount++
                    } else {
                         Write-Verbose "  No changes needed or already normal: $($_.FullName)"
                    }
                }
            } catch {
                Write-Warning "Could not process shortcut: $($_.FullName) - Error: $($_.Exception.Message)"
            }
        }
    }
}
if ($modifiedShortcutsCount -gt 0) {
    Write-Host "Restoration of $modifiedShortcutsCount shortcuts completed." -ForegroundColor Green
} else {
    Write-Host "No shortcuts were modified (or they were already normal)."
}
# --- END: Modify Shortcuts ---

# --- START: Modify Registry ---
Write-Host "Restoring Registry for protocol associations..." -ForegroundColor Cyan
$RegistryPath = "Registry::HKEY_CLASSES_ROOT\ChromeHTML\shell\open\command"
$BackupRegistryPath = "Registry::HKEY_CURRENT_USER\Software\ChromeGuestModeHelper" 
$BackupValueName = "OriginalChromeHTMLOpenCommand"

if (-not (Test-Path $RegistryPath)) {
    Write-Warning "Registry path '$RegistryPath' does not exist. Cannot restore."
} else {
    try {
        $backupCommandProperty = Get-ItemProperty -Path $BackupRegistryPath -Name $BackupValueName -ErrorAction SilentlyContinue
        if ($backupCommandProperty -ne $null) {
            $originalCommand = $backupCommandProperty.$BackupValueName
            Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value $originalCommand -Force
            Write-Host "Registry restored from backup. Original command: $originalCommand" -ForegroundColor Green
            
        } else {
            Write-Warning "Backup of original command not found in '$BackupRegistryPath'."
            Write-Warning "Attempting to manually remove '$GuestArgument' if present..."
            $currentCommand = (Get-ItemProperty -Path $RegistryPath -Name "(Default)")."(Default)"
            if ($currentCommand -like "*$GuestArgument*") {
                $restoredCommand = ($currentCommand -replace $GuestArgumentPattern, "").Trim() -replace "\s{2,}", " "
                Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value $restoredCommand -Force
                Write-Host "Manually removed '$GuestArgument'. New command: $restoredCommand" -ForegroundColor Green
            } else {
                Write-Verbose "Current command does not appear to contain '$GuestArgument'. No manual changes made."
            }
        }
    } catch {
        Write-Error "Error restoring Registry: $($_.Exception.Message)"
    }
}
Write-Host "Registry restoration completed." -ForegroundColor Green
# --- END: Modify Registry ---

Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "Restoration complete. Chrome should now open normally." -ForegroundColor Green
Write-Host "If taskbar shortcuts are not updated," -ForegroundColor Yellow
Write-Host "unpin and re-pin them from the Start Menu." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
Read-Host "Press Enter to exit."