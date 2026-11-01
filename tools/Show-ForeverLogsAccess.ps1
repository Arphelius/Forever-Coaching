$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Forever Coaching - API access'
$form.ClientSize = New-Object System.Drawing.Size(580, 270)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$instruction = New-Object System.Windows.Forms.Label
$instruction.Text = 'Paste your Forever Logs API key below, then click Check access.'
$instruction.Location = New-Object System.Drawing.Point(18, 18)
$instruction.Size = New-Object System.Drawing.Size(544, 28)
$form.Controls.Add($instruction)

$keyBox = New-Object System.Windows.Forms.TextBox
$keyBox.UseSystemPasswordChar = $true
$keyBox.Location = New-Object System.Drawing.Point(18, 55)
$keyBox.Size = New-Object System.Drawing.Size(544, 28)
$form.Controls.Add($keyBox)

$check = New-Object System.Windows.Forms.Button
$check.Text = 'Check access'
$check.Location = New-Object System.Drawing.Point(18, 100)
$check.Size = New-Object System.Drawing.Size(140, 34)
$form.Controls.Add($check)
$form.AcceptButton = $check

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Your key is sent only to Forever Logs and is not saved.'
$status.Location = New-Object System.Drawing.Point(18, 151)
$status.Size = New-Object System.Drawing.Size(544, 100)
$form.Controls.Add($status)

$checker = Join-Path $PSScriptRoot 'Test-ForeverLogsAccess.ps1'
$check.Add_Click({
    $enteredKey = $keyBox.Text.Trim()
    if (-not $enteredKey.StartsWith('alog_') -or $enteredKey -match '\s') {
        $status.ForeColor = [System.Drawing.Color]::Firebrick
        $status.Text = 'Paste only your API key in the box above, then click Check access.'
        return
    }
    $previousKey = $env:FOREVERLOGS_API_KEY
    $check.Enabled = $false
    $keyBox.Enabled = $false
    $form.UseWaitCursor = $true
    $status.ForeColor = [System.Drawing.Color]::Black
    $status.Text = 'Checking with Forever Logs. This may take up to 30 seconds...'
    $form.Refresh()
    try {
        $env:FOREVERLOGS_API_KEY = $enteredKey
        & $checker | Out-Null
        $status.ForeColor = [System.Drawing.Color]::ForestGreen
        $status.Text = 'Access confirmed! Your key has events:read access. You can close this window and tell Codex that access is confirmed.'
    } catch {
        # The checker supplies safe messages without request headers or keys.
        $status.ForeColor = [System.Drawing.Color]::Firebrick
        $status.Text = $_.Exception.Message
    } finally {
        $env:FOREVERLOGS_API_KEY = $previousKey
        $enteredKey = $null
        $keyBox.Clear()
        $keyBox.Enabled = $true
        $check.Enabled = $true
        $form.UseWaitCursor = $false
    }
}.GetNewClosure())
$form.Add_Shown({ $keyBox.Focus() })
try { [void]$form.ShowDialog() } finally { $keyBox.Clear(); $form.Dispose() }
