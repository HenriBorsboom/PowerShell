$Files = Get-ChildItem -LiteralPath 'C:\Windows' -Recurse -Force -File

$10yAge = (Get-Date).AddYears(-10)
$07yAge = (Get-Date).AddYears(-7)
$05yAge = (Get-Date).AddYears(-5)
$02yAge = (Get-Date).AddYears(-2)

$10yFiles = @()
$07yFiles = @()
$05yFiles = @()
$02yFiles = @()

$FileAge = @()

For ($i = 0; $i -lt $Files.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Files.Count.ToString() + ' - Processing ' + $Files[$i].Name)
    If (($Files[$i].LastWriteTime).Date -lt $10yAge) {
        $10yFiles += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 10
        })
        $FileAge += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 10
        })
    }
    ElseIf (($Files[$i].LastWriteTime).Date -lt $07yAge -and ($Files[$i].LastWriteTime).Date -gt $10yAge) {
        $07yFiles += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 07
        })
        $FileAge += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 07
        })
    }
    ElseIf (($Files[$i].LastWriteTime).Date -lt $05yAge -and ($Files[$i].LastWriteTime).Date -gt $07yAge) {
        $05yFiles += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 05
        })
        $FileAge += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 05
        })
    }
    ElseIf (($Files[$i].LastWriteTime).Date -gt $02yAge -and ($Files[$i].LastWriteTime).Date -lt $05yAge) {
        $02yFiles += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 02
        })
        $FileAge += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 02
        })
    }
    Else {
        $FileAge += ,(New-Object -TypeName PSObject -Property @{
            ID = $i
            FileName = $Files[$i].FullName
            LastWriteTime = $Files[$i].LastWriteTime
            CreationTime = $Files[$i].CreationTime
            AgeCategory = 0
        })
    }
}

#$10yFiles | Select-Object ID, FileName, LastWriteTime, CreationTime, AgeCategory | Out-GridView
#$07yFiles | Select-Object ID, FileName, LastWriteTime, CreationTime, AgeCategory | Out-GridView
#$05yFiles | Select-Object ID, FileName, LastWriteTime, CreationTime, AgeCategory | Out-GridView
#$02yFiles | Select-Object ID, FileName, LastWriteTime, CreationTime, AgeCategory | Out-GridView
$FileAge  | Select-Object ID, FileName, LastWriteTime, CreationTime, AgeCategory | Out-GridView