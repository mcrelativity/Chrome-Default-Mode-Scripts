# Enable-ChromeGuestModeWithDefaultURL.ps1
# Configures Google Chrome to launch in Guest Mode by default.
# Shortcuts will attempt to open with a specified default URL in Guest Mode (Chrome might ignore the URL for Guest Mode).
# Protocol/file associations will open the target content in Guest Mode.

# --- START: Administrator Privilege Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    Write-Host "Please right-click on the script and select 'Run as administrator'."
    Read-Host "Press Enter to exit."
    exit 1
}
# --- END: Administrator Privilege Check ---

$DefaultURL = "galenotest1.web.app" # <--- Your specified default URL
$GuestArgument = "--guest"
Write-Host "Starting configuration for Chrome to default to Guest Mode, attempting to open URL: $DefaultURL from shortcuts." -ForegroundColor Cyan

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
if (-not $ChromeExePath) {
    Write-Error "Google Chrome installation could not be found. Aborting."
    Read-Host "Press Enter to exit."
    exit 1
}
Write-Host "Chrome found at: $ChromeExePath" -ForegroundColor Green

# --- START: Modify Shortcuts ---
Write-Host "Modifying shortcuts to include $GuestArgument and attempt to open default URL..." -ForegroundColor Cyan
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
                if ($shortcut.TargetPath -eq $ChromeExePath) {
                    Write-Verbose "Processing shortcut: $($_.FullName)"
                    $newArguments = "$GuestArgument `"$DefaultURL`"" # Attempt to add URL
                    
                    if ($shortcut.Arguments -ne $newArguments) {
                         $shortcut.Arguments = $newArguments
                         $shortcut.Save()
                         Write-Host "  Modified: $($_.FullName) - New arguments: $($shortcut.Arguments)" -ForegroundColor Green
                         $modifiedShortcutsCount++
                    } else {
                         Write-Verbose "  Already configured correctly: $($_.FullName)"
                    }
                } elseif ($shortcut.TargetPath -like "*chrome.exe*") {
                     Write-Warning "  Shortcut '$($_.FullName)' points to Chrome, but its TargetPath ('$($shortcut.TargetPath)') is not exactly '$ChromeExePath'. Review manually if needed."
                }
            } catch {
                Write-Warning "Could not process shortcut: $($_.FullName) - Error: $($_.Exception.Message)"
            }
        }
    }
}
if ($modifiedShortcutsCount -gt 0) {
    Write-Host "Modification of $modifiedShortcutsCount shortcuts completed." -ForegroundColor Green
} else {
    Write-Host "No shortcuts were modified (or they were already configured)."
}
# --- END: Modify Shortcuts ---

# --- START: Modify Registry (ONLY for $GuestArgument) ---
Write-Host "Modifying Registry for protocol associations (for $GuestArgument only)..." -ForegroundColor Cyan
$RegistryPath = "Registry::HKEY_CLASSES_ROOT\ChromeHTML\shell\open\command"
$BackupRegistryPath = "Registry::HKEY_CURRENT_USER\Software\ChromeGuestModeHelper" 
$BackupValueName = "OriginalChromeHTMLOpenCommand"

if (-not (Test-Path $RegistryPath)) {
    Write-Error "Registry path '$RegistryPath' does not exist. Is Chrome installed and registered correctly?"
    Read-Host "Press Enter to exit."
    exit 1
}

try {
    $currentCommand = (Get-ItemProperty -Path $RegistryPath -Name "(Default)")."(Default)"
    Write-Verbose "Current command in Registry: $currentCommand"

    if (-not (Test-Path $BackupRegistryPath)) {
        New-Item -Path $BackupRegistryPath -Force | Out-Null
    }
    
    $existingBackup = Get-ItemProperty -Path $BackupRegistryPath -Name $BackupValueName -ErrorAction SilentlyContinue
    if (($existingBackup -eq $null) -or ($currentCommand -notlike "*$GuestArgument*")) {
        Set-ItemProperty -Path $BackupRegistryPath -Name $BackupValueName -Value $currentCommand -Force
        Write-Host "Backup of original command saved to '$BackupRegistryPath\$BackupValueName'" -ForegroundColor Yellow
    }
    
    if ($currentCommand -notlike "*$GuestArgument*") {
        $newCommand = $currentCommand -replace ('("?.*?chrome.exe"?)(.*)'), ('$1 ' + $GuestArgument + '$2') 
        
        if (($newCommand -eq $currentCommand) -and ($currentCommand -match '^("?.*?chrome.exe"?)$')) { 
            $executablePart = $Matches[1]
            $newCommand = "$executablePart $GuestArgument"
        } elseif ($newCommand -eq $currentCommand) {
            Write-Warning "Primary regex did not modify the command. Attempting simpler insertion."
            $parts = $currentCommand.Split(@(" "), 2) 
            $executable = $parts[0]
            $argumentsAfterExecutable = if ($parts.Length -gt 1) { $parts[1] } else { "" }
            $newCommand = "$executable $GuestArgument $argumentsAfterExecutable".Trim() -replace "\s{2,}", " "
        }

        Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value $newCommand -Force
        Write-Host "Registry modified. New command: $newCommand" -ForegroundColor Green
    } else {
        Write-Verbose "Registry command already includes '$GuestArgument'."
    }
} catch {
    Write-Error "Error modifying Registry: $($_.Exception.Message)"
    Write-Warning "If a backup was saved, you can try restoring it with the deactivation script."
    Read-Host "Press Enter to exit."
    exit 1
}
Write-Host "Registry modification completed." -ForegroundColor Green
# --- END: Modify Registry ---

Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
Write-Host "Configuration complete. Chrome should now open in Guest Mode." -ForegroundColor Green
Write-Host "Shortcuts will attempt to load $DefaultURL (Chrome may ignore this in Guest Mode)." -ForegroundColor Green
Write-Host "Links opened from other applications will open in Guest Mode." -ForegroundColor Green
Write-Host "If taskbar shortcuts are not updated," -ForegroundColor Yellow
Write-Host "unpin and re-pin them from the Start Menu." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
Read-Host "Press Enter to exit."