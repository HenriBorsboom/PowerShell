Imports System.Collections.ObjectModel
Imports System.Management.Automation
Imports System.Management.Automation.Runspaces
Imports System.Text
Imports System.IO
Public Class PowerShellToVBNETCodeForm
    Private Sub ButtonCancel_Click(sender As Object, e As EventArgs) Handles ButtonCancel.Click
        Me.Close()
    End Sub
    Private Sub ButtonOK_Click(sender As Object, e As EventArgs) Handles ButtonOK.Click
        If (PowerShellTextBox.Text <> "") Then
            VBNETTextbox.Clear()
            Dim ScriptName As String = ScriptNameTextBox.Text.Replace(" ", "")
            VBNETTextbox.AppendText("Private Function " + ScriptName + "()" + vbCrLf)
            VBNETTextbox.AppendText("   Dim Script as New StringBuilder()" + vbCrLf)
            For Each Line As String In PowerShellTextBox.Lines()
                VBNETTextbox.AppendText("   Script.Append(""" + Line.Replace("""", """ + Chr(34) + """) + """ + vbCrLf)" + vbCrLf)
            Next
            VBNETTextbox.AppendText("   Return Script.ToString()" + vbCrLf)
            VBNETTextbox.AppendText("End Function" + vbCrLf)
        End If
    End Sub
    Private Function RunScript(ByVal scriptText As String) As Object
        Dim MyRunSpace As Runspace = RunspaceFactory.CreateRunspace()
        MyRunSpace.Open()
        Dim MyPipeline As Pipeline = MyRunSpace.CreatePipeline()
        MyPipeline.Commands.AddScript(scriptText)
        Dim results As Collection(Of PSObject) = MyPipeline.Invoke()
        MyRunSpace.Close()
        Dim MyStringBuilder As New StringBuilder()
        For Each obj As PSObject In results
            MyStringBuilder.AppendLine(obj.ToString())
        Next
        Return results
    End Function
    Private Sub ButtonClearPowerShell_Click(sender As Object, e As EventArgs) Handles ButtonClearPowerShell.Click
        PowerShellTextBox.Clear()
    End Sub
    Private Sub ButtonClearVBNET_Click(sender As Object, e As EventArgs) Handles ButtonClearVBNET.Click
        VBNETTextbox.Clear()
    End Sub
    Private Sub ButtonVBNETCopy_Click(sender As Object, e As EventArgs) Handles ButtonVBNETCopy.Click
        My.Computer.Clipboard.SetText(VBNETTextbox.Text)
        MsgBox("Copied to Clipboard", MsgBoxStyle.OkOnly)
    End Sub
    Private Sub ButtonPowerShellPaste_Click(sender As Object, e As EventArgs) Handles ButtonPowerShellPaste.Click
        PowerShellTextBox.Text = My.Computer.Clipboard.GetText()
    End Sub

    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        Dim GetFunctionCode As Form = ExecutePowerShellInVB
        GetFunctionCode.ShowDialog()
    End Sub
End Class
