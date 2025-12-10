Public Class ExecutePowerShellInVB
    Private Sub ButtonOK_Click(sender As Object, e As EventArgs) Handles ButtonOK.Click
        Me.Close()
    End Sub

    Private Sub ButtonCopy_Click(sender As Object, e As EventArgs) Handles ButtonCopy.Click
        My.Computer.Clipboard.SetText(RunScriptTextBox.Text)
        MsgBox("Copied to Clipboard", MsgBoxStyle.OkOnly)
    End Sub
End Class