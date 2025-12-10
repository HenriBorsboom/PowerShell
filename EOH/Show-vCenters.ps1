Param (
    [Parameter(Mandatory=$False)]
    [Switch] $Config, `
    [Parameter(Mandatory=$False)]
    [Switch] $Launch, `
    [Parameter(Mandatory=$False)]
    [Switch] $View, `
    [Parameter(Mandatory=$False)]
    [Switch] $Test, `
    [Parameter(Mandatory=$False)]
    [Switch] $RT)

Function Store-Credentials {
    $Credentials = Get-Credential -Message "Please supply credentials for vCenters"
    $UserFile = ($env:windir + "\vScriptUsername.txt")
    $PassFile = ($env:windir + "\vScriptPassword.txt")
    $Credentials.UserName | Out-File $UserFile
    ConvertFrom-SecureString -SecureString $Credentials.Password | Out-File $PassFile
}
Function Load-Credentials {
    #Creating PSCredential object
    $UserName = Get-Content ($env:windir + "\vScriptUsername.txt")
    $Password = Get-Content ($env:windir + "\vScriptPassword.txt") | ConvertTo-SecureString
    $AdminCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $UserName, $Password
    Return $AdminCredential
}
Function Launch-vCenters {
    Param (
        [Parameter(Mandatory=$False)]
        [Switch] $RT)

    Switch ($RT) {
        $True  {
            $WorkingDirectory = 'C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client\Launcher'
            $VPXClient        = 'vpxclient.exe'
            For ($i = 0; $i -lt $vCenters.Count; $i ++) {
                Write-Color -IndexCounter $i -TotalCounter $vCenters.Count -Text $vCenters[$i].IPAddress, " - ", $vCenters[$i].CommonName    -ForegroundColor White, White, Yellow
                If ($vCenters[$i].Parameter -eq 'RT') {
                    If ($vCenters[$i].Username -eq 'domain') {
                     Start-Process -FilePath ($WorkingDirectory + '\' + $VPXClient) -WorkingDirectory $WorkingDirectory -Credential $Global:AdminCredential -ArgumentList "-s", $vCenters[$i].IPAddress, "-passthroughAuth" 
                    }
                    Else {
                        Start-Process -FilePath ($WorkingDirectory + '\' + $VPXClient) -WorkingDirectory $WorkingDirectory -ArgumentList "-s", $vCenters[$i].IPAddress, "-u", $vCenters[$i].Username, "-p", $vCenters[$i].Password
                    }
                }
                Else {
                    Write-Color -Text 'Not part of RT - Skipped' -ForegroundColor $MyColors.Warning   
                }
            }
        }
        $False {
            $WorkingDirectory = 'C:\Program Files (x86)\VMware\Infrastructure\Virtual Infrastructure Client\Launcher'
            $VPXClient        = 'vpxclient.exe'
            For ($i = 0; $i -lt $vCenters.Count; $i ++) {
                Write-Color -IndexCounter $i -TotalCounter $vCenters.Count -Text $vCenters[$i].IPAddress, " - ", $vCenters[$i].CommonName    -ForegroundColor White, White, Yellow
                If ($vCenters[$i].Username -eq 'domain') {
                 Start-Process -FilePath ($WorkingDirectory + '\' + $VPXClient) -WorkingDirectory $WorkingDirectory -Credential $Global:AdminCredential -ArgumentList "-s", $vCenters[$i].IPAddress, "-passthroughAuth" 
                }
                Else {
                    Start-Process -FilePath ($WorkingDirectory + '\' + $VPXClient) -WorkingDirectory $WorkingDirectory -ArgumentList "-s", $vCenters[$i].IPAddress, "-u", $vCenters[$i].Username, "-p", $vCenters[$i].Password
                }
            }
        }
    }
}
Function View-vCenters {
    $ForeGroundColors = @('White', 'Yellow', 'Green', 'Green')
    $vCenters | Select $Properties | Format-Table -AutoSize
}
Function Test-vCenters {
    $ForeGroundColors = @('White', 'Yellow', 'Green', 'Green')
    For ($i = 0; $i -lt $vCenters.Count; $i ++) {
        Write-Color -IndexCounter $i -TotalCounter $vCenters.Count -Text "Testing connectivity to ", $vCenters[$i].IPAddress, " - " -ForegroundColor $MyColors.Text, $MyColors.Value, $MyColors.Text -NoNewLine
        Try {
            If (Test-Connection $vCenters[$i].IPAddress -Quiet) {
                Write-Color -Text "Online" -ForegroundColor Green
            }
            Else {
                Write-Color -Text "Offline" -ForegroundColor Red
            }
        }
        Catch {
            Write-Color -Text $_ -ForegroundColor Red
        }
    }
}
#region Colors
$MyColors = @{}
$MyColors.Add("Text",    ([ConsoleColor]::White))
$MyColors.Add("Value",   ([ConsoleColor]::Cyan))
$MyColors.Add("Warning", ([ConsoleColor]::Yellow))
$MyColors.Add("Error",   ([ConsoleColor]::Red))
#endregion
#region vCenters
$vCenters = @()
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.5.254'   ; CommonName = 'EOH Midrand Waterfall'; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.33.8'    ; CommonName = 'EOH PE'               ; Username = 'root'  ; Password = 'P@ssw0rd'  ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.130.5'   ; CommonName = 'EOH ERS'              ; Username = 'root'  ; Password = 'EohAbacus!'; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.144.27'  ; CommonName = 'EOH Pinmill'          ; Username = 'root'  ; Password = 'con42esx05'; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.169.5'   ; CommonName = 'EOH Health'           ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.172.11'  ; CommonName = 'PTA R21'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
#$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.207.11'  ; CommonName = 'Alpine (ECI)'         ; Username = 'root'  ; Password = 'Fro0ple'   ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.1.238.11'  ; CommonName = 'Autospec'             ; Username = 'root'  ; Password = 'Fro0ple.'  ; Parameter = 'RT'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.9.2'     ; CommonName = 'EOH KZN'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.17.11'   ; CommonName = 'KZN Gridey'           ; Username = 'root'  ; Password = 'Fro0ple.'  ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.2.20.11'   ; CommonName = 'Armstrong'            ; Username = 'root'  ; Password = 'Fro0ple'   ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.11'    ; CommonName = 'EOH BT Cape Town'     ; Username = 'root'  ; Password = 'password'  ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.0.12'    ; CommonName = 'EOH Cape Town'        ; Username = 'root'  ; Password = 'password'  ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.4.15'    ; CommonName = 'More SBT'             ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.3.17.11'   ; CommonName = 'EOH-CLEARCPT-VHS1'    ; Username = 'root'  ; Password = 'Fro0ple'   ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.4.100'  ; CommonName = 'Gilloolys'            ; Username = 'domain'; Password = ''          ; Parameter = 'RT'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.6.16'   ; CommonName = 'EOH FIN'              ; Username = 'root'  ; Password = 'Passw00rd' ; Parameter = ''})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.10.180.35' ; CommonName = 'Amethyst'             ; Username = 'domain'; Password = ''          ; Parameter = 'RT'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.5.230'  ; CommonName = 'Teraco'               ; Username = 'root'  ; Password = 'P@ssw0rd1' ; Parameter = 'RT'})
$vCenters += ,(New-Object -TypeName PSObject -Property @{ IPAddress = '10.12.255.110'; CommonName = 'IMSSD'                ; Username = 'domain'; Password = ''          ; Parameter = 'RT'})
$Properties = @('IPAddress', 'CommonName', 'Username', 'Password')
#endregion
Switch ($Config) {
    $True  { Store-Credentials; Return }
    $False { $Global:AdminCredential = Load-Credentials }
}
Switch ($Launch) {
    $True  { Launch-vCenters }
}
Switch ($View) {
    $True  { $vCenters | Select $Properties | Format-Table -AutoSize }
}
Switch ($Test) {
    $True  { Test-vCenters }
}
Switch ($RT) {
    $True  { Launch-vCenters -RT}
}

If (!$Config -and !$View -and !$Launch -and !$Test -and $RT) { $vCenters | Select $Properties | Format-Table -AutoSize }