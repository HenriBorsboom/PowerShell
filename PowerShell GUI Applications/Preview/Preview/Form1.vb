Imports System.Collections.ObjectModel
Imports System.Management.Automation
Imports System.Management.Automation.Runspaces
Imports System.Text
Imports System.IO
Public Class Form1
    Private Sub Button1_Click(sender As Object, e As EventArgs) Handles Button1.Click
        TextBox1.Text = RunScript(GetServiceName2("win*")).ToString()
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
        Return MyStringBuilder
    End Function
    Private Function GetServiceName2(ByVal Filter As String)
        Dim Script As New StringBuilder()
        Script.Append("$Results = Get-Service | Sort Name | Where Name -like """ + Filter + """" + vbCrLf)
        Script.Append("$Results.Name" + vbCrLf)
        Return Script.ToString()
    End Function
End Class
