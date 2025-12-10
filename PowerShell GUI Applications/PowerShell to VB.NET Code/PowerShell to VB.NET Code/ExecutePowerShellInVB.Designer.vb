<Global.Microsoft.VisualBasic.CompilerServices.DesignerGenerated()> _
Partial Class ExecutePowerShellInVB
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
        Dim resources As System.ComponentModel.ComponentResourceManager = New System.ComponentModel.ComponentResourceManager(GetType(ExecutePowerShellInVB))
        Me.ButtonOK = New System.Windows.Forms.Button()
        Me.GroupBox1 = New System.Windows.Forms.GroupBox()
        Me.RunScriptTextBox = New System.Windows.Forms.TextBox()
        Me.ButtonCopy = New System.Windows.Forms.Button()
        Me.GroupBox1.SuspendLayout()
        Me.SuspendLayout()
        '
        'ButtonOK
        '
        Me.ButtonOK.Location = New System.Drawing.Point(488, 301)
        Me.ButtonOK.Name = "ButtonOK"
        Me.ButtonOK.Size = New System.Drawing.Size(75, 23)
        Me.ButtonOK.TabIndex = 4
        Me.ButtonOK.Text = "C&lose"
        Me.ButtonOK.UseVisualStyleBackColor = True
        '
        'GroupBox1
        '
        Me.GroupBox1.Controls.Add(Me.RunScriptTextBox)
        Me.GroupBox1.Location = New System.Drawing.Point(12, 12)
        Me.GroupBox1.Name = "GroupBox1"
        Me.GroupBox1.Size = New System.Drawing.Size(551, 283)
        Me.GroupBox1.TabIndex = 2
        Me.GroupBox1.TabStop = False
        Me.GroupBox1.Text = "Function"
        '
        'RunScriptTextBox
        '
        Me.RunScriptTextBox.AcceptsReturn = True
        Me.RunScriptTextBox.AcceptsTab = True
        Me.RunScriptTextBox.Dock = System.Windows.Forms.DockStyle.Fill
        Me.RunScriptTextBox.Location = New System.Drawing.Point(3, 16)
        Me.RunScriptTextBox.Multiline = True
        Me.RunScriptTextBox.Name = "RunScriptTextBox"
        Me.RunScriptTextBox.Size = New System.Drawing.Size(545, 264)
        Me.RunScriptTextBox.TabIndex = 1
        Me.RunScriptTextBox.Text = resources.GetString("RunScriptTextBox.Text")
        '
        'ButtonCopy
        '
        Me.ButtonCopy.Location = New System.Drawing.Point(407, 301)
        Me.ButtonCopy.Name = "ButtonCopy"
        Me.ButtonCopy.Size = New System.Drawing.Size(75, 23)
        Me.ButtonCopy.TabIndex = 2
        Me.ButtonCopy.Text = "Co&py"
        Me.ButtonCopy.UseVisualStyleBackColor = True
        '
        'ExecutePowerShellInVB
        '
        Me.AcceptButton = Me.ButtonOK
        Me.AutoScaleDimensions = New System.Drawing.SizeF(6.0!, 13.0!)
        Me.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font
        Me.ClientSize = New System.Drawing.Size(575, 336)
        Me.Controls.Add(Me.GroupBox1)
        Me.Controls.Add(Me.ButtonCopy)
        Me.Controls.Add(Me.ButtonOK)
        Me.Name = "ExecutePowerShellInVB"
        Me.ShowIcon = False
        Me.Text = "Run Script Function"
        Me.GroupBox1.ResumeLayout(False)
        Me.GroupBox1.PerformLayout()
        Me.ResumeLayout(False)

    End Sub

    Friend WithEvents ButtonOK As Button
    Friend WithEvents GroupBox1 As GroupBox
    Friend WithEvents RunScriptTextBox As TextBox
    Friend WithEvents ButtonCopy As Button
End Class
