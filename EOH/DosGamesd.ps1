Clear-Host

#$Games = Get-Content C:\temp\games.txt

$Source = 'C:\Users\henri.borsboom\Downloads\Games'
$Games = Get-ChildItem -Path $Source *.exe -Recurse -Force

For ($i = 0; $i -lt $Games.Count; $i ++) {
    $GameNameSplit = $Games[$i].Fullname.Split('\')
    [String] $Name1 = ($GameNameSplit[5]).ToString()
    [String] $Name2 = ($GameNameSplit[-1]).ToString()
    [String] $GameName = $Name1 + "_" + $Name2
    Write-Host (($i + 1).ToString() + '/' + $Games.Count.ToString() + ' Creating BASH file for ' + $GameName + ' - ') -NoNewline
    $Newfilename = ("C:\Temp\Games\" + $GameName)
    $BashText = @()
    $BashText += ,('@echo off')
    $BashText += ,('"c:\Program Files (x86)\DOSBox-0.74-2\DOSBox.exe" ' + '"' + $Games[$i].FullName + '"' + ' -exit')
    Try {
        $BashText | Out-File -FilePath ($Newfilename +".bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        
    }
    Catch {
        If (!(Test-Path ($Newfilename + "1.bat"))) {
            $BashText | Out-File -FilePath ($Newfilename + "1.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "2.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "2.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "3.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "3.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "4.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "4.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "5.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "5.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "6")))) {
            $BashText | Out-File -FilePath ($Newfilename + "6.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "7.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "7.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "8.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "8.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "9.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "9.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        ElseIf (!(Test-Path (($Newfilename + "10.bat")))) {
            $BashText | Out-File -FilePath ($Newfilename + "10.bat") -Encoding ascii -Force -NoClobber -ErrorAction Stop
        }
        Else {
            Write-Host $_ -ForegroundColor Red
            Read-Host
        }
    }
    Finally {
        Write-Host "Complete" -ForegroundColor Green
    }
}