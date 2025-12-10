function Main {
    Show-MainForm
}
function PlayButtonFunction { 
    $info = $env:COMPUTERNAME 
    $Textbox.text=  "Your PC Name is: " + $info 
}
function Show-MainForm {
    $MainForm = New-Object 'System.Windows.Forms.Form'
    $TextBox = New-Object 'System.Windows.Forms.TextBox'
    $button1 = New-Object 'System.Windows.Forms.Button'
    $button_close = New-Object 'System.Windows.Forms.Button'

    $MainForm.ClientSize = '700, 500'
    $MainForm.StartPosition = 'CenterScreen'
    $MainForm.AutoSize = $true
    $MainForm.Text = 'MainForm'

    $TextBox.Location = New-Object System.Drawing.Point(20,20)
    $TextBox.Font = New-Object System.Drawing.Font("Lucida Console",16,[System.Drawing.FontStyle]::Regular)
    $Textbox.ClientSize = '650, 400'
    $TextBox.Multiline = $true

    $button1.Location = '400, 450'
    $button1.Size = '100, 30'
    $button1.Text = 'Play'
    $button1.add_Click( {PlayButtonFunction} )

    $button_close.Location = '550, 450'
    $button_close.Size = '100, 30'
    $button_close.Text = 'Close'
    $button_close.add_Click( {$MainForm.Close()} )

    $MainForm.Controls.AddRange(@($label1,$Textbox,$button1,$button_close))
    return $MainForm.ShowDialog()
}

Main | Out-Null 