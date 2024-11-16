# Quick and dirty IntuneWinAppUtil GUI
# Downloaded from https://github.com/Microsoft/Microsoft-Win32-Content-Prep-Tool

#region User Configuration

# Path to IntuneWinAppUtil.exe
$intuneWinAppUtil = "$env:USERPROFILE\OneDrive\Documents\Scripts\Intune\IntuneWinAppUtil.exe"

# Path where the output .intunewin files will be saved
$outputPath = "$env:USERPROFILE\OneDrive\Documents\Scripts\Intune\~IntuneWin"

#endregion

# Load the necessary assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'IntuneWin App Packager'
$form.Size = New-Object System.Drawing.Size(550, 250)
$form.StartPosition = 'CenterScreen'

# Source Path Label
$labelSourcePath = New-Object System.Windows.Forms.Label
$labelSourcePath.Location = New-Object System.Drawing.Point(20, 20)
$labelSourcePath.Size = New-Object System.Drawing.Size(100, 20)
$labelSourcePath.Text = 'Source Path:'
$form.Controls.Add($labelSourcePath)

# Source Path TextBox
$textBoxSourcePath = New-Object System.Windows.Forms.TextBox
$textBoxSourcePath.Location = New-Object System.Drawing.Point(20, 40)
$textBoxSourcePath.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($textBoxSourcePath)

# Setup File Label
$labelSetupFile = New-Object System.Windows.Forms.Label
$labelSetupFile.Location = New-Object System.Drawing.Point(20, 80)
$labelSetupFile.Size = New-Object System.Drawing.Size(400, 20)
$labelSetupFile.Text = 'Setup File (e.g., setup.exe, installer.msi, install.ps1):'
$form.Controls.Add($labelSetupFile)

# Setup File TextBox
$textBoxSetupFile = New-Object System.Windows.Forms.TextBox
$textBoxSetupFile.Location = New-Object System.Drawing.Point(20, 100)
$textBoxSetupFile.Size = New-Object System.Drawing.Size(400, 20)
$form.Controls.Add($textBoxSetupFile)

# Browse Source Button
$buttonBrowseSource = New-Object System.Windows.Forms.Button
$buttonBrowseSource.Location = New-Object System.Drawing.Point(430, 40)
$buttonBrowseSource.Size = New-Object System.Drawing.Size(75, 20)
$buttonBrowseSource.Text = 'Browse'
$buttonBrowseSource.Add_Click({
        $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
        $result = $folderBrowser.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $textBoxSourcePath.Text = $folderBrowser.SelectedPath
        }
    })
$form.Controls.Add($buttonBrowseSource)

# Browse Setup File Button
$buttonBrowseSetup = New-Object System.Windows.Forms.Button
$buttonBrowseSetup.Location = New-Object System.Drawing.Point(430, 100)
$buttonBrowseSetup.Size = New-Object System.Drawing.Size(75, 20)
$buttonBrowseSetup.Text = 'Browse'
$buttonBrowseSetup.Add_Click({
        $fileBrowser = New-Object System.Windows.Forms.OpenFileDialog
        $fileBrowser.Filter = "Setup Files (*.exe;*.msi;*.ps1)|*.exe;*.msi;*.ps1;*.bat;*.cmd|All Files (*.*)|*.*"
        $fileBrowser.InitialDirectory = $textBoxSourcePath.Text
        $result = $fileBrowser.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $textBoxSetupFile.Text = Split-Path $fileBrowser.FileName -Leaf
        }
    })
$form.Controls.Add($buttonBrowseSetup)

# Status Label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Location = New-Object System.Drawing.Point(20, 180)
$labelStatus.Size = New-Object System.Drawing.Size(550, 60)
$labelStatus.Text = ''
$form.Controls.Add($labelStatus)

# Create Button
$buttonCreate = New-Object System.Windows.Forms.Button
$buttonCreate.Location = New-Object System.Drawing.Point(20, 140)
$buttonCreate.Size = New-Object System.Drawing.Size(100, 30)
$buttonCreate.Text = 'Create Package'
$buttonCreate.Add_Click({
        if ([string]::IsNullOrWhiteSpace($textBoxSourcePath.Text) -or
            [string]::IsNullOrWhiteSpace($textBoxSetupFile.Text)) {
            [System.Windows.Forms.MessageBox]::Show('Please fill in all fields.', 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        # Validate paths
        if (-not (Test-Path $textBoxSourcePath.Text)) {
            [System.Windows.Forms.MessageBox]::Show('Source path does not exist.', 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $setupFilePath = Join-Path $textBoxSourcePath.Text $textBoxSetupFile.Text
        if (-not (Test-Path $setupFilePath)) {
            [System.Windows.Forms.MessageBox]::Show('Setup file does not exist in the source path.', 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        # Create output directory if it doesn't exist
        if (-not (Test-Path $outputPath)) {
            New-Item -ItemType Directory -Path $outputPath | Out-Null
        }

        # Build arguments - note the changed parameter format
        $arguments = "-c `"$($textBoxSourcePath.Text)`" -s `"$($textBoxSetupFile.Text)`" -o `"$outputPath`" -q"

        try {
            $labelStatus.Text = "Creating package... Please wait."
            $labelStatus.Refresh()

            $process = Start-Process -FilePath $intuneWinAppUtil -ArgumentList $arguments -Wait -NoNewWindow -PassThru

            if ($process.ExitCode -eq 0) {
                $labelStatus.Text = "Package created successfully!`nLocation: $outputPath"
                [System.Windows.Forms.MessageBox]::Show("Package created successfully!`nLocation: $outputPath", 'Success', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            }
            else {
                throw "IntuneWinAppUtil.exe exited with code: $($process.ExitCode)"
            }
        }
        catch {
            $errorMessage = "Error creating package: $_"
            $labelStatus.Text = $errorMessage
            [System.Windows.Forms.MessageBox]::Show($errorMessage, 'Error', [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        }
    })
$form.Controls.Add($buttonCreate)

# Show the form
$form.ShowDialog()