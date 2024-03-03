$ScriptName = "Software Write-Blocker"

$showWindowAsync = Add-Type –memberDefinition @”
[DllImport("user32.dll")]
public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
“@ -name “Win32ShowWindowAsync” -namespace Win32Functions –passThru

Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

function Hide-PowerShell() { 
    [void]$showWindowAsync::ShowWindowAsync((Get-Process –id $pid).MainWindowHandle, 2) 
}

<#

A tool to enable Software Write-Blocking.

#>

Function GetBase64Icon {
    Param ($Icon)

    Switch ($Icon) {
        "Folder" { $data = "iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAc1JREFUOE+11D1LI0EYB/D/zK5vWdOIrWAj90JiksLK4goVRY/LcXAHBwqKRUQQBfFTiKAcihaioGAhiB5GRLjiCqsr8sqpaOEXsFITJbPzyE7GjSCJK8Rpdlj+89tnnhmWocqDVdnD24CXa6BKlbaOeP+wqvB8uTLY0rOIOvuscneav4A1dTMFpmbLg+0jceAq7qnV7N1SEaTTWMUte9IAsPcrGjwZrQ74YVWD/4ddkPSMHidlymPFpdCP4vzjugazg2q9JIIQBCElpE0oZzqruMFgcg7TZDC4xgObGsz8JCkJ9wWJm5zA1+ysp7btBmbQ6DNRV8PBOQMLbmkw/Z2ETbjNC/Qn5zxhj6GD8DSsBhOmwcDatzWY+kYF4VRn43Nm/lXgfnAKfkuDoR0NJqMlMPvLBbfbxlFf6/SJq3dCSOTvJX5cLLmZ/cAE/JYB0+Bg4T0NJgaoIEj1rz9ZqvB3cBKNPkP1yBlOj69vbUSzCy54EH5SYSSuwX+dGrTRl1h2w/FQ7Dl447Rlxc0cRsbg9xnqtFnHcekWFf62Ue6O0JXYcMNHoSFY9Qw1ZvFaqF3kJXrTm27mT2QIPifz6VyF3ub39apjfSFc9QofABVCsxXxqzJFAAAAAElFTkSuQmCC" }
        "Refresh" { $data ="iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAAAXNSR0IArs4c6QAAAKtJREFUOE+1lUESgCAIRfHM6tKVW72yNToToyRRpC0VXv8DkYHn52CuDTm/4gy9uOI4EOXX/D72BpyCcs5QSgHvvWAIBiCFceqfXLBADay+CIFDHZSNmgIlZTVpWucYI4QQmsIv6qSmwD5gHQ1r7RvLnMrmFBWmlMA5pwVi2VZZ3gvsR+GvZdVg06awy0Ezj7ec3uLf5dBY3KIUvwgSgJwVC3ZgS119+wtA6AlcejERm/xPTAAAAABJRU5ErkJggg==" }
        }
    return [System.IO.MemoryStream][System.Convert]::FromBase64String($data)
}

$enabling = New-Object System.Windows.Forms.Button
$enabling.enabled = $false
$enabling.Size = New-Object System.Drawing.Size(325,50)
$enabling.Font = "Segoe UI,10.5"
$enabling.Location = New-Object System.Drawing.Size(50,225)
$enabling.BackColor = "BlanchedAlmond"
$enabling.Text = "Enabling Write-Blocking..."
$enabling.Visible = $false

$disabling = New-Object System.Windows.Forms.Button
$disabling.enabled = $false
$disabling.Size = New-Object System.Drawing.Size(325,50)
$disabling.Font = "Segoe UI,10.5"
$disabling.Location = New-Object System.Drawing.Size(50,225)
$disabling.BackColor = "BlanchedAlmond"
$disabling.Text = "Disabling Write-Blocking..."
$disabling.Visible = $false
    
$enabled = New-Object System.Windows.Forms.Button
$enabled.enabled = $false
$enabled.Size = New-Object System.Drawing.Size(325,50)
$enabled.Font = "Segoe UI,10.5"
$enabled.Location = New-Object System.Drawing.Size(50,225)
$enabled.BackColor = "GreenYellow"
$enabled.Text = "Write-Blocking enabled. Ensure you test this with your device first!"
$enabled.Visible = $false

$disabled = New-Object System.Windows.Forms.Button
$disabled.enabled = $false
$disabled.Size = New-Object System.Drawing.Size(325,50)
$disabled.BackColor = "Coral"
$disabled.Font = "Segoe UI,10.5"
$disabled.Location = New-Object System.Drawing.Size(50,225)
$disabled.Text = "Write-blocking disabled! Ensure you test a device prior to continuing."
$disabled.Visible = $false

$explorer = New-Object System.Windows.Forms.Button
$explorer.Location = New-Object System.Drawing.Size(400,225)
$explorer.Size = New-Object System.Drawing.Size(50,50)
$explorer.BackColor = "#cccccc"
$explorer.Image = ([System.Drawing.Image]::FromStream((GetBase64Icon -Icon Folder)))
$explorer.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$explorer.FlatAppearance.BorderSize = 0
$explorer.FlatAppearance.MouseDownBackColor = '#999999' 
$explorer.Add_Click({explorer.exe})

function DisableBlock {
    try {
        reg delete HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices /f > $null 2>&1
        reg delete HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies /v WriteProtect /t REG_DWORD /d 0 /f > $null 2>&1
        reg delete HKLM\SYSTEM\CurrentControlSet\Control\Storage /v HotplugSecurityDescriptor /f > $null 2>&1
        #Sleep is here to enable the OS and any open handles which rely on these keys to apply the changes
        #and to prevent the user from inserting a USB device before keys have been applied.
        Start-sleep 5
        $disabled.Visible = $true
        }
    catch {
        return
        }
    }

function EnableBlock {
    try {
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\'{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}' /v Deny_Write /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\'{53f56307-b6bf-11d0-94f2-00a0c91efb8b}' /v Deny_Write /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom\Deny_Write /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom\Deny_Write /v Deny_Write /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom\Deny_Write\List /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom\Deny_Write\List /v "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" /d "{53f5630d-b6bf-11d0-94f2-00a0c91efb8b}" /f > $null 2>&1
        reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\RemovableStorageDevices\Custom\Deny_Write\List /v "{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" /d "{53f56307-b6bf-11d0-94f2-00a0c91efb8b}" /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\StorageDevicePolicies /v WriteProtect /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP /v DenyAllGPState /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /v EnumerateDevices /t REG_DWORD /d 1 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /v AccessBitMask /t REG_DWORD /d 0 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /v UserPolicy /t REG_DWORD /d 0 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /v AuditPolicyOnly /t REG_DWORD /d 0 /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage\EnabledDenyGP\'{53F5630D-B6BF-11D0-94F2-00A0C91EFB8B}' /v SecurityDescriptor /t REG_SZ /d "D:(D;;DCLCRPCRSD;;;IU)(A;;FA;;;SY)(A;;FA;;;LS)(A;;0x1200a9;;;IU)" /f > $null 2>&1
        reg add HKLM\SYSTEM\CurrentControlSet\Control\Storage /v HotplugSecurityDescriptor /t REG_BINARY /d "01000480000000000000000000000000140000000200580004000000010014001601010001010000000000050400000000001400ff011f0001010000000000051200000000001400ff011f0001010000000000051300000000001400a9001200010100000000000504000000" /f > $null 2>&1
        #Sleep is here to enable the OS and any open handles which rely on these keys to apply the changes
        #and to prevent the user from inserting a USB device before keys have been applied.
        Start-sleep 5
        $enabled.Visible = $true
        }
    catch {
        DisableBlock
        return
        }
    }

Function MainForm {

    $prgBar = New-Object System.Windows.Forms.ProgressBar
    $prgBar.Location = New-Object System.Drawing.Size(-1,0)
    $prgBar.Size = New-Object System.Drawing.Size(897,4)
    $prgBar.Style = [System.Windows.Forms.ProgressBarStyle]::Marquee
    $prgBar.MarqueeAnimationSpeed = 24
    $prgBar.Visible = $false

    $frmMain = New-Object System.Windows.Forms.Form
    $frmMain.MinimumSize = $frmMain.MaximumSize = New-Object System.Drawing.Size(500,350)
    $frmMain.MinimizeBox = $frmMain.MaximizeBox = $false
    $frmMain.Text = $ScriptName
    $frmMain.Backcolor = [System.Drawing.Color]::White
    $frmMain.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $frmMain.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
    $frmMain.KeyPreview = $true
    $frmMain.Add_KeyDown({
        If ($_.KeyCode -eq 'Escape') { $frmMain.Close() }
    })

    $lblTitle = New-Object System.Windows.Forms.Label
    $lblTitle.Location = New-Object System.Drawing.Size(28,8)
    $lblTitle.Size = New-Object System.Drawing.Size(512,32)
    $lblTitle.Text = "Software Write-Blocker"
    $lblTitle.Font = 'Segoe UI,20'

    $WriteBlockON = New-Object System.Windows.Forms.Button
    $WriteBlockON.Size = New-Object System.Drawing.Size(175,125)
    $WriteBlockON.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $WriteBlockON.FlatAppearance.BorderSize = 0
    $WriteBlockON.FlatAppearance.MouseDownBackColor = '#999999'
    $WriteBlockON.Font = "Segoe UI,10.5"
    $WriteBlockON.BackColor = "#cccccc"
    $WriteBlockON.Location = New-Object System.Drawing.Size(50,75)
    $WriteBlockON.Text = "Write-Block ON"
    $WriteBlockON.Add_Click({
        $disabled.Visible = $false
        $disabling.Visible = $false
        $enabling.Visible = $true
        EnableBlock
        $enabling.Visible = $false
    })

    $WriteBlockOFF = New-Object System.Windows.Forms.Button
    $WriteBlockOFF.Size = New-Object System.Drawing.Size(175,125)
    $WriteBlockOFF.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $WriteBlockOFF.FlatAppearance.BorderSize = 0
    $WriteBlockOFF.FlatAppearance.MouseDownBackColor = '#999999'
    $WriteBlockOFF.Font = "Segoe UI,10.5"
    $WriteBlockOFF.BackColor = "#cccccc"
    $WriteBlockOFF.Location = New-Object System.Drawing.Size(275,75)
    $WriteBlockOFF.Text = "Write-Block OFF"
    $WriteBlockOFF.Add_Click({
        $enabled.Visible = $false
        $enabling.Visible = $false
        $disabling.Visible = $true
        DisableBlock
        $disabling.Visible = $false
    })

    $frmMain.Controls.AddRange(@($lblTitle,$prgBar))

    $frmMain.Controls.AddRange(@($WriteBlockON,$WriteBlockOFF))
    $frmMain.Controls.AddRange(@($enabling,$enabled,$disabling,$disabled))
    $frmMain.Controls.AddRange(@($explorer))
    
    [Void]$frmMain.ShowDialog()

}

Hide-PowerShell

MainForm