# Chrome Default Mode Configuration Scripts

## 🚀 Overview

This project provides PowerShell scripts to configure Google Chrome on Windows to launch in a specific mode by default: either **Guest Mode** or **Incognito Mode**. This is useful for ensuring a clean Browse session automatically or for privacy-focused default Browse.

When Incognito Mode is activated, these scripts can also set a default URL (or multiple URLs) to open automatically. For Guest Mode, while a default URL can be specified for shortcuts, Chrome typically opens its standard Guest landing page.

These scripts modify system settings (Chrome shortcuts and Windows Registry entries) to achieve this persistent behavior.

## 📋 Prerequisites

* **Operating System:** Windows (Designed and tested primarily on Windows 11).
* **Browser:** Google Chrome installed.
* **PowerShell:** Available by default on Windows.

## 🚨 IMPORTANT WARNINGS 🚨

* **ADMINISTRATOR PRIVILEGES REQUIRED:** All scripts **MUST** be run with Administrator privileges to modify system settings and the registry.
* **Registry Modification Risk:** Editing the Windows Registry can be risky. Incorrect changes can lead to system instability or application malfunctions. While these scripts are designed with care, use them at your own risk.
* **Backup Recommended:** Before running any activation script for the first time, it is **STRONGLY RECOMMENDED** to:
    * Create a System Restore Point.
    * Back up any registry keys that will be modified (primarily related to `HKEY_CLASSES_ROOT\ChromeHTML`). The activation scripts attempt to back up the original command they modify.
* **Use As-Is:** These scripts are provided as-is. No warranties are expressed or implied.
* **Chrome Updates:** Future Google Chrome updates might potentially revert these settings or change how Chrome handles associations. If this happens, you may need to re-run the appropriate script.

## 🛠️ Setup

1.  **Download/Place Scripts:**
    * Ensure you have the script files (e.g., `Enable-ChromeGuestMode.ps1`, `Disable-ChromeIncognitoWithDefaultURL.ps1`, etc.) in a dedicated folder on your computer (e.g., `C:\MyScripts\ChromeConfig`).
        * **Note on Script Names:** The script names used in this README (like `Enable-ChromeIncognitoWithDefaultURL.ps1`) reflect versions that include the default URL functionality. If your local script files have slightly different names (e.g., without "URL" or "WithDefault"), please adjust the commands accordingly.

2.  **PowerShell Execution Policy:**
    * Your system's PowerShell execution policy might prevent scripts from running. To check, open PowerShell as Administrator and run `Get-ExecutionPolicy`.
    * If it's `Restricted`, you'll need to change it. A common setting is `RemoteSigned`. You can set this for the current user by running the following in an Administrator PowerShell window:
        ```powershell
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        ```
        Confirm with `Y` if prompted.
    * Alternatively, for testing, you can set it for the current PowerShell process only:
        ```powershell
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
        ```

3.  **Unblock Script Files:**
    * If you downloaded the `.ps1` files from the internet or copied their content, Windows might block them for security reasons.
    * Right-click on each `.ps1` file, select "Properties".
    * In the "General" tab, if you see a security message at the bottom saying "This file came from another computer and might be blocked...", check the "Unblock" checkbox, then click "Apply" and "OK".

## ⚙️ How to Use

**Mandatory: All scripts must be run with Administrator privileges!**

There are two main ways to run the scripts:

**Method 1: Direct Execution (Right-Click)**
1.  Navigate to the folder containing the script in File Explorer.
2.  Right-click on the desired `.ps1` script file.
3.  Select "Run with PowerShell".
4.  If prompted by User Account Control (UAC), click "Yes" to grant administrator permissions.
    *(The scripts include a `Read-Host` at the end to keep the window open so you can see any messages.)*

**Method 2: Via PowerShell Console (Recommended for seeing all output)**
1.  Open PowerShell as an **Administrator**.
    * Search for "PowerShell" in the Start Menu.
    * Right-click "Windows PowerShell" and select "Run as administrator".
2.  Navigate to the directory where your scripts are saved. Replace the example path with your actual path:
    ```powershell
    cd "C:\path\to\your\scripts"
    ```
3.  Execute the desired script by typing its name prefixed with `.\`:

---

### Guest Mode Configuration
Configures Chrome to launch in Guest Mode by default. Guest Mode provides a temporary, isolated Browse session that doesn't save history or cookies after all guest windows are closed.
*(Note: While scripts might attempt to set a default URL for shortcuts in Guest Mode, Chrome typically ignores this and opens its standard Guest landing page.)*

* **To Activate Guest Mode by Default:**
    *(Assuming your script is named `Enable-ChromeGuestMode.ps1` or `Enable-ChromeGuestModeWithDefaultURL.ps1` if it attempts to set a URL)*
    ```powershell
    .\Enable-ChromeGuestMode.ps1
    ```

* **To Deactivate Guest Mode by Default (Revert to Normal):**
    ```powershell
    .\Disable-ChromeGuestMode.ps1
    ```

---

### Incognito Mode Configuration
Configures Chrome to launch in Incognito Mode by default. Incognito Mode prevents Chrome from saving your Browse history, cookies, site data, or information entered in forms for that session. You can still access your existing bookmarks. These scripts also allow setting a default URL (or multiple) for shortcuts.

* **To Activate Incognito Mode by Default (with default URL):**
    *(Assuming your script is named `Enable-ChromeIncognitoWithDefaultURL.ps1` or similar)*
    ```powershell
    .\Enable-ChromeIncognitoWithDefaultURL.ps1
    ```

* **To Deactivate Incognito Mode by Default (Revert to Normal):**
    ```powershell
    .\Disable-ChromeIncognitoWithDefaultURL.ps1
    ```

---

### 🔧 Managing Default URLs (for Incognito Mode Scripts)

The activation scripts for Incognito Mode (e.g., `Enable-ChromeIncognitoWithDefaultURL.ps1`) typically have a variable at the top to set a default URL that opens when Chrome is launched from a modified shortcut.

**1. Changing the Default URL:**
* Open the activation script (e.g., `Enable-ChromeIncognitoWithDefaultURL.ps1`) in a text editor (like VS Code or Notepad).
* Near the top of the script, find the line:
    ```powershell
    $DefaultURL = "[https://your-default-homepage.com](https://your-default-homepage.com)"
    ```
* Change the URL within the quotes to your desired new default homepage.
* Save the script and re-run it (as Administrator) to apply the new default URL. You might need to run the deactivation script first if you want a clean application of the new URL.

**2. Setting Multiple Default URLs:**
* Chrome can open multiple URLs passed on the command line; it usually opens them in separate tabs.
* To set multiple default URLs, modify the `$DefaultURL` variable in the activation script to include all URLs, separated by spaces. Ensure the entire string of URLs is properly quoted if handled as a single argument string to Chrome, or just list them space-separated directly after the mode flag.
* Example:
    ```powershell
    # For launching multiple specific URLs with --incognito from shortcuts
    # The script's shortcut modification logic would set arguments like: --incognito "[https://page1.com](https://page1.com)" "[https://page2.com](https://page2.com)"
    # To achieve this, you'd modify the $DefaultURL variable and how it's used:
    $DefaultURLs = '"[https://site1.example.com](https://site1.example.com)" "[https://site2.example.com](https://site2.example.com)"' # One way to group them
    # And then in the shortcut modification part:
    # $newArguments = "$IncognitoArgument $DefaultURLs"
    ```
    Or, if Chrome handles them as separate arguments directly:
    ```powershell
    $DefaultURL_1 = "[https://site1.example.com](https://site1.example.com)"
    $DefaultURL_2 = "[https://site2.example.com](https://site2.example.com)"
    # And in the shortcut modification:
    # $newArguments = "$IncognitoArgument `"$DefaultURL_1`" `"$DefaultURL_2`""
    ```
    *Note: The exact implementation for multiple URLs might require adjusting the `$newArguments` line in the "Modify Shortcuts" section of the activation script to correctly pass multiple URLs to `chrome.exe`.*

**3. Unsetting/Removing the Default URL (Launching Incognito to New Tab Page):**
* **Method A: Edit the Script**
    * Open the activation script (e.g., `Enable-ChromeIncognitoWithDefaultURL.ps1`).
    * Find the `$DefaultURL` line.
    * Change it to an empty string:
        ```powershell
        $DefaultURL = ""
        ```
    * Save the script.
    * Run the deactivation script first to clear previous settings.
    * Then run the modified activation script. Now, shortcuts should open Incognito mode to its default New Tab Page.
* **Method B: Use a Script Version Without URL Logic**
    * If you have a version of the activation script that *only* sets the `--incognito` flag and doesn't include any `$DefaultURL` logic (e.g., a script named `Enable-ChromeIncognito.ps1`), you can run that after deactivating any URL-setting version.

---

## ℹ️ Script Details (What they do)

* **Activation Scripts:**
    * Modify Google Chrome shortcuts (Desktop, Start Menu) to append the necessary command-line flag (`--guest` or `--incognito`). For Incognito mode, a default URL (or multiple) can also be added for shortcuts.
    * Modify Windows Registry entries for `ChromeHTML` (handling `http`/`https` protocols and `.html` file associations) to include the appropriate flag (`--guest` or `--incognito`). **Note:** The default URL is *not* added to these registry commands, ensuring that clicking specific links opens *those links* in the chosen mode, not the default homepage.
    * The activation scripts back up the original registry command they modify. This backup is stored in `HKEY_CURRENT_USER\Software\Chrome[ModeName]Helper` (e.g., `ChromeIncognitoModeHelper` or `ChromeGuestModeHelper`).

* **Deactivation Scripts:**
    * Remove the command-line flags (and any default URLs for Incognito mode) from Chrome shortcuts.
    * Restore the original command in the Windows Registry, primarily using the backup created by the activation script. If the backup is not found, it attempts to manually remove the known flags.

## ⚠️ Troubleshooting

* **"Nothing happens" / Window closes immediately:**
    * Ensure you are running the script from an **Administrator PowerShell console** (Method 2 above). This will keep the window open and display any messages or errors.
    * Check your PowerShell **Execution Policy**.
    * **Unblock** the script file(s) if they were downloaded.
* **Errors during execution:**
    * Double-check that you are running PowerShell **as Administrator**.
    * Ensure the script content is an exact copy of the provided code and hasn't been corrupted.
    * Verify that Google Chrome is installed in a standard location.
* **Taskbar shortcuts not updating:** If pinned taskbar shortcuts don't reflect the changes immediately, try unpinning Chrome from the taskbar and then re-pinning it from the (now modified) Start Menu shortcut.

## ⚖️ Disclaimer

These scripts are provided for educational and personal use. Modifying system settings, especially the Windows Registry, carries inherent risks. The author or provider of these scripts is not responsible for any damage or loss of data that may occur from their use. **Use at your own risk and ensure you have backed up important data and system configurations.**