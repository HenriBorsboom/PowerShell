<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class PowerShellToVBNETCodeForm
    Inherits System.Windows.Forms.Form

    'Form overrides dispose to clean up the component list.
    <System.Diagnostics.DebuggerNonUserCode()> _
    Protected Overrides Sub Dispose(ByVal disposing As Boolean)
        Try
            If disposing AndAlso components IsNot Nothing Then
                components.Dispose()
            End If
        Finally
            MyBase.Dispose(disposing)
        End Try
    End Sub

    'Required by the Windows Form Designer
    Private components As System.ComponentModel.IContainer

    'NOTE: The following procedure is required by the Windows Form Designer
    'It can be modified using the Windows Form Designer.  
    'Do not modify it using the code editor.
    <System.Diagnostics.DebuggerStepThrough()> _
    Private Sub InitializeComponent()
        Me.ButtonOK = New System.Windows.Forms.Button()
        Me.ButtonCancel = New System.Windows.Forms.Button()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.PowerShellTextBox = New System.Windows.Forms.TextBox()
        Me.GroupBox2 = New System.Windows.Forms.GroupBox()
        Me.VBNETTextbox = New System.Windows.Forms.TextBox()
        Me.ButtonClearPowerShell = New System.Windows.Forms.Button()
        Me.ButtonClearVBNET = New System.Windows.Forms.Button()
        Me.Label1 = New System.Windows.Forms.Label()
        Me.ScriptNameTextBox = New System.Windows.Forms.TextBox()
        Me.ButtonPowerShellPaste = New System.Windows.Forms.Button()
        Me.ButtonVBNETCopy = New System.Windows.Forms.Button()
        Me.Button1 = New System.Windows.Forms.Button()
        Me.GroupBox1.SuspendLayout()
        Me.GroupBox2.SuspendLayout()
        Me.SuspendLayout()
        '
        'ButtonOK
        '
        Me.ButtonOK.Location = New System.Drawing.Point(578, 110)
        Me.ButtonOK.Name = "ButtonOK"
        Me.ButtonOK.Size = New System.Drawing.Size(75, 23)
        Me.ButtonOK.TabIndex = 3
        Me.ButtonOK.Text = "Co&nvert"
        Me.ButtonOK.UseVisualStyleBackColor = True
        '
        'ButtonCancel
        '
        Me.ButtonCancel.Location = New System.Drawing.Point(578, 395)
        Me.ButtonCancel.Name = "ButtonCancel"
        Me.ButtonCancel.Size = New System.Drawing.Size(75, 23)
        Me.ButtonCancel.TabIndex = 4
        Me.ButtonCancel.Text = "&Close"
        Me.ButtonCancel.UseVisualStyleBackColor = True
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.PowerShellTextBox)
        Me.GroupBox1.Location = New System.Drawing.Point(12, 38)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Size = New System.Drawing.Size(560, 250)
        Me.GroupBox1.TabIndex = 2
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "PowerShell Code"
        '
        'PowerShellTextBox
        '
        Me.PowerShellTextBox.AcceptsReturn = True
        Me.PowerShellTextBox.AcceptsTab = True
        Me.PowerShellTextBox.Dock = System.Windows.Forms.DockStyle.Fill
        Me.PowerShellTextBox.Location = New System.Drawing.Point(3, 16)
        Me.PowerShellTextBox.Multiline = True
        Me.PowerShellTextBox.Name = "PowerShellTextBox"
        Me.PowerShellTextBox.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.PowerShellTextBox.Size = New System.Drawing.Size(554, 231)
        Me.PowerShellTextBox.TabIndex = 1
        Me.PowerShellTextBox.WordWrap = False
        '
        'GroupBox2
        '
        Me.GroupBox2.Controls.Add(Me.VBNETTextbox)
        Me.GroupBox2.Location = New System.Drawing.Point(12, 294)
        Me.GroupBox2.Name = "GroupBox2"
        Me.GroupBox2.Size = New System.Drawing.Size(560, 250)
        Me.GroupBox2.TabIndex = 3
        Me.GroupBox2.TabStop = False
        Me.GroupBox2.Text = "VB.NET Code"
        '
        'VBNETTextbox
        '
        Me.VBNETTextbox.AcceptsReturn = True
        Me.VBNETTextbox.AcceptsTab = True
        Me.VBNETTextbox.Dock = System.Windows.Forms.DockStyle.Fill
        Me.VBNETTextbox.HideSelection = False
        Me.VBNETTextbox.Location = New System.Drawing.Point(3, 16)
        Me.VBNETTextbox.Multiline = True
        Me.VBNETTextbox.Name = "VBNETTextbox"
        Me.VBNETTextbox.ScrollBars = System.Windows.Forms.ScrollBars.Both
        Me.VBNETTextbox.Size = New System.Drawing.Size(554, 231)
        Me.VBNETTextbox.TabIndex = 2
        Me.VBNETTextbox.WordWrap = False
        '
        'ButtonClearPowerShell
        '
        Me.ButtonClearPowerShell.Location = New System.Drawing.Point(578, 52)
        Me.ButtonClearPowerShell.Name = "ButtonClearPowerShell"
        Me.ButtonClearPowerShell.Size = New System.Drawing.Size(75, 23)
        Me.ButtonClearPowerShell.TabIndex = 5
        Me.ButtonClearPowerShell.Text = "C&lear"
        Me.ButtonClearPowerShell.UseVisualStyleBackColor = True
        '
        'ButtonClearVBNET
        '
        Me.ButtonClearVBNET.Location = New System.Drawing.Point(578, 308)
        Me.ButtonClearVBNET.Name = "ButtonClearVBNET"
        Me.ButtonClearVBNET.Size = New System.Drawing.Size(75, 23)
        Me.ButtonClearVBNET.TabIndex = 6
        Me.ButtonClearVBNET.Text = "Cl&ear"
        Me.ButtonClearVBNET.UseVisualStyleBackColor = True
        '
        'Label1
        '
        Me.Label1.AutoSize = True
        Me.Label1.Location = New System.Drawing.Point(9, 15)
        Me.Label1.Name = "Label1"
        Me.Label1.Size = New System.Drawing.Size(111, 13)
        Me.Label1.TabIndex = 7
        Me.Label1.Text = "Script/Function Name"
        '
        'ScriptNameTextBox
        '
        Me.ScriptNameTextBox.Location = New System.Drawing.Point(126, 12)
        Me.ScriptNameTextBox.Name = "ScriptNameTextBox"
        Me.ScriptNameTextBox.Size = New System.Drawing.Size(446, 20)
        Me.ScriptNameTextBox.TabIndex = 8
        '
        'ButtonPowerShellPaste
        '
        Me.ButtonPowerShellPaste.Location = New System.Drawing.Point(578, 81)
        Me.ButtonPowerShellPaste.Name = "ButtonPowerShellPaste"
        Me.ButtonPowerShellPaste.Size = New System.Drawing.Size(75, 23)
        Me.ButtonPowerShellPaste.TabIndex = 0
        Me.ButtonPowerShellPaste.Text = "&Paste"
        Me.ButtonPowerShellPaste.UseVisualStyleBackColor = True
        '
        'ButtonVBNETCopy
        '
        Me.ButtonVBNETCopy.Location = New System.Drawing.Point(578, 337)
        Me.ButtonVBNETCopy.Name = "ButtonVBNETCopy"
        Me.ButtonVBNETCopy.Size = New System.Drawing.Size(75, 23)
        Me.ButtonVBNETCopy.TabIndex = 0
        Me.ButtonVBNETCopy.Text = "C&opy"
        Me.ButtonVBNETCopy.UseVisualStyleBackColor = True
        '
        'Button1
        '
        Me.Button1.Location = New System.Drawing.Point(578, 366)
        Me.Button1.Name = "Button1"
        Me.Button1.Size = New System.Drawing.Size(75, 23)
        Me.Button1.TabIndex = 9
        Me.Button1.Text = "&Function"
        Me.Button1.UseVisualStyleBackColor = True
        '
        'PowerShellToVBNETCodeForm
        '
        Me.AcceptButton = Me.ButtonOK
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(663, 561)
        Me.Controls.Add(Me.Button1)
        Me.Controls.Add(Me.ButtonVBNETCopy)
        Me.Controls.Add(Me.ButtonPowerShellPaste)
        Me.Controls.Add(Me.ScriptNameTextBox)
        Me.Controls.Add(Me.Label1)
        Me.Controls.Add(Me.ButtonClearVBNET)
        Me.Controls.Add(Me.ButtonClearPowerShell)
        Me.Controls.Add(Me.GroupBox2)
        Me.Controls.Add(Me.GroupBox1)
        Me.Controls.Add(Me.ButtonCancel)
        Me.Controls.Add(Me.ButtonOK)
        Me.Name = "PowerShellToVBNETCodeForm"
        Me.ShowIcon = False
        Me.Text = "PowerShell to VB.NET Code"
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.GroupBox2.ResumeLayout(False)
        Me.GroupBox2.PerformLayout()
        Me.ResumeLayout(False)
        Me.PerformLayout()

    End Sub

    Friend WithEvents ButtonOK As Button
    Friend WithEvents ButtonCancel As Button
    Friend WithEvents GroupBox1 As GroupBox
    Friend WithEvents PowerShellTextBox As TextBox
    Friend WithEvents GroupBox2 As GroupBox
    Friend WithEvents VBNETTextbox As TextBox
    Friend WithEvents ButtonClearPowerShell As Button
    Friend WithEvents ButtonClearVBNET As Button
    Friend WithEvents Label1 As Label
    Friend WithEvents ScriptNameTextBox As TextBox
    Friend WithEvents ButtonPowerShellPaste As Button
    Friend WithEvents ButtonVBNETCopy As Button
    Friend WithEvents Button1 As Button
End Class
