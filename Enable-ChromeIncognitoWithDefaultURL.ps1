# Enable-ChromeIncognitoWithDefaultURL.ps1
# Configures Google Chrome to launch in Incognito Mode by default.
# Shortcuts will open with a specified default URL in Incognito Mode.
# Protocol/file associations will open the target content in Incognito Mode.

# --- START: Administrator Privilege Check ---
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    Write-Host "Please right-click on the script and select 'Run as administrator'."
    Read-Host "Press Enter to exit."
    exit 1
}
# --- END: Administrator Privilege Check ---

$DefaultURL = "https://your-default-homepage.com" # <--- EXAMPLE URL: Change this to your desired default homepage
$IncognitoArgument = "--incognito"
Write-Host "Starting configuration for Chrome to default to Incognito Mode with URL: $DefaultURL" -ForegroundColor Cyan

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
Write-Host "Modifying shortcuts to include $IncognitoArgument and the default URL..." -ForegroundColor Cyan
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
                # Only modify if the TargetPath is exactly chrome.exe (no previous arguments in TargetPath)
                if ($shortcut.TargetPath -eq $ChromeExePath) {
                    Write-Verbose "Processing shortcut: $($_.FullName)"
                    # For shortcuts, --incognito and the URL are the main arguments
                    $newArguments = "$IncognitoArgument `"$DefaultURL`"" # Ensures URL is quoted if it contains special characters
                    
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

# --- START: Modify Registry (ONLY for $IncognitoArgument, NOT for the default URL here) ---
Write-Host "Modifying Registry for protocol associations (for $IncognitoArgument only)..." -ForegroundColor Cyan
$RegistryPath = "Registry::HKEY_CLASSES_ROOT\ChromeHTML\shell\open\command"
# Backup path for original command, stored in Current User hive
$BackupRegistryPath = "Registry::HKEY_CURRENT_USER\Software\ChromeIncognitoModeHelper" 
$BackupValueName = "OriginalChromeHTMLOpenCommand"

if (-not (Test-Path $RegistryPath)) {
    Write-Error "Registry path '$RegistryPath' does not exist. Is Chrome installed and registered correctly?"
    Read-Host "Press Enter to exit."
    exit 1
}

try {
    $currentCommand = (Get-ItemProperty -Path $RegistryPath -Name "(Default)")."(Default)"
    Write-Verbose "Current command in Registry: $currentCommand"

    # Create backup path if it doesn't exist
    if (-not (Test-Path $BackupRegistryPath)) {
        New-Item -Path $BackupRegistryPath -Force | Out-Null
    }
    
    $existingBackup = Get-ItemProperty -Path $BackupRegistryPath -Name $BackupValueName -ErrorAction SilentlyContinue
    # Save backup if it doesn't exist OR if the current command does NOT contain the incognito argument
    # (to avoid overwriting the original backup with an already modified state if script is run multiple times)
    if (($existingBackup -eq $null) -or ($currentCommand -notlike "*$IncognitoArgument*")) {
        Set-ItemProperty -Path $BackupRegistryPath -Name $BackupValueName -Value $currentCommand -Force
        Write-Host "Backup of original command saved to '$BackupRegistryPath\$BackupValueName'" -ForegroundColor Yellow
    }
    
    if ($currentCommand -notlike "*$IncognitoArgument*") {
        # Insert $IncognitoArgument after "chrome.exe" and before other arguments like -- or %1
        # Example: "chrome.exe" -- "%1"  => "chrome.exe" --incognito -- "%1"
        $newCommand = $currentCommand -replace ('("?.*?chrome.exe"?)(.*)'), ('$1 ' + $IncognitoArgument + '$2') # Adds a space before $2
        
        # Additional check if the regex didn't make a change and $2 (original arguments) was empty.
        if (($newCommand -eq $currentCommand) -and ($currentCommand -match '^("?.*?chrome.exe"?)$')) { 
            # Case where there were no arguments after chrome.exe in the original command
            $executablePart = $Matches[1]
            $newCommand = "$executablePart $IncognitoArgument"
        } elseif ($newCommand -eq $currentCommand) {
             # If still no changes, it might be that $2 is only spaces or something unexpected.
             # This is a fallback; the main regex should work for most standard cases.
            Write-Warning "Primary regex did not modify the command. Attempting simpler insertion."
            $parts = $currentCommand.Split(@(" "), 2) # Split on the first space
            $executable = $parts[0]
            $argumentsAfterExecutable = if ($parts.Length -gt 1) { $parts[1] } else { "" }
            $newCommand = "$executable $IncognitoArgument $argumentsAfterExecutable".Trim() -replace "\s{2,}", " "
        }

        Set-ItemProperty -Path $RegistryPath -Name "(Default)" -Value $newCommand -Force
        Write-Host "Registry modified. New command: $newCommand" -ForegroundColor Green
    } else {
        Write-Verbose "Registry command already includes '$IncognitoArgument'."
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
Write-Host "Configuration complete. Chrome should now open in Incognito Mode" -ForegroundColor Green
Write-Host "and load $DefaultURL from shortcuts." -ForegroundColor Green
Write-Host "Links opened from other applications will open in Incognito Mode" -ForegroundColor Green
Write-Host "displaying the specific link's content." -ForegroundColor Green
Write-Host "If taskbar shortcuts are not updated," -ForegroundColor Yellow
Write-Host "unpin and re-pin them from the Start Menu." -ForegroundColor Yellow
Write-Host "--------------------------------------------------------------------" -ForegroundColor DarkCyan
Read-Host "Press Enter to exit."