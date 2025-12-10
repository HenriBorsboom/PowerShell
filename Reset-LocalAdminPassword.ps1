Clear-Host
$ErrorActionPreference = "Stop"
Function Write-Color {
    Param(
        [String[]] $Text, `
        [ConsoleColor[]] $Color, `
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "DEBUG!!!!! - Write-Color" -ForegroundColor Red
        Write-Host "The amount of Text variables and the amount of color variables does not match"
        Write-Host "Text Variables:  " $Text.Count
        Write-Host "Color Variables: " $Color.Length
        Break
    }
    Else {
        For ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
        }
        Switch ($EndLine){
            $true {Write-Host}
            $false {Write-Host -NoNewline}
        }
    }
}
Function SetPassword {
    Param (
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $UserAccount, `
        [Parameter(Mandatory = $True, Position = 2)]
        [String] $Password)
    $User = $UserAccount
    $User = [adsi]"WinNT://$computer/$User,user"
    $User.SetPassword($Password)
    $User.SetInfo()
}
Function UpdatePolicy {
    Param (
        [Parameter(Mandatory = $True, Position = 1)]
        [String] $Server)
    Try {
        Write-Color -Text "Attempting to force policy update on ", $Server.ToUpper(), " - " -Color White, Yellow, White
            $Result = Invoke-Command -ComputerName $Server -ScriptBlock { GPUpdate /Force }
        Write-Host "Completed"
        Return $Result
    }
    Catch { Write-Host "Failed" -ForegroundColor Red; Return $_ }
}
Function Timer {
    Param(
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCount)

    $Duration = New-TimeSpan -Seconds($x)
    $s = $Duration.TotalSeconds
    $ts =  [timespan]::fromseconds($s)
    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
    Return $ReturnVariable
}
Function JobUpdate {
    Param (
        [Parameter(Mandatory=$true, Position = 1)]
        [Int64] $StartCounter)
    
    $Counter = Timer -StartCount $StartCounter
    Write-Color -Text "Getting AD Computer Objects starting with ", "'NR*'", " - ", $Counter, " - " -Color White, Yellow, White, Red, White 
    Sleep 1
    
}
Function MultiThread {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $JobName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock)
    $x = 1
    $GetChildItemJob = Start-Job -Name $JobName -ScriptBlock {Param($Script); Invoke-Expression $Script} -ArgumentList $ScriptBlock -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Delete-LastLine -SameLine        
        JobUpdate -StartCounter $x
        $x ++
    }
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}
Function Delete-LastLine {
    Param (
        [Parameter(Mandatory = $false)]
        [Switch] $SameLine)
    $x = [Console]::CursorLeft
    $y = [Console]::CursorTop
    #Write-Host "x - $x; y - $y; SameLine - $SameLine"
    #Break
    Switch ($SameLine) {
        $true {
            [Console]::SetCursorPosition(0,$y)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition(0,$y)
        }
        $False {
            [Console]::SetCursorPosition($x,$y - 1)
            Write-Host "                                                                                                                                            "
            [Console]::SetCursorPosition($x,$y - 1)
        }
    }
}
Function ResetPassword {
    Write-Color -Text "Getting AD Computer Objects starting with ", "'NR*'", " - " -Color White, Yellow, White
        [ADComputer] $Computers = MultiThread -JobName "ADComputers" -ScriptBlock 'Get-ADComputer -Filter {Name -like "NRA*"}'
        $Computers = $Computers | Sort Name
        $Computers = $Computers.Name
    Write-Host "Complete" -ForegroundColor Green
    $Local_LocalAdmin = "LocalAdmin"
    $Local_Administrator = "Administrator"
    $Password = "^Pr1v@teCl0ud!"
    Try {
        $Counter = 1
        $ComputersCount = $Computers.Count
        Foreach ($Computer in $Computers) {
            If ($Computer -eq "NRAZUREGCS102" -or $Computer -eq "NRAZUREGCS202" -or $Computer -eq "NRAZUREVMH103" -or $Computer -eq "NRAZUREVMH104" -or $Computer -eq "NRAZUREVMH105" -or $Computer -eq "NRAZUREDBSC102" -or $Computer -eq "NRAZUREWGS101" -or $Computer -eq "NRAZUREWGS201" -or $Computer -eq "NRAZUREWGC101") {}
            Else {
                $Success = $false
                Try {
                    Write-Color -Text "$Counter/$ComputersCount", " - Attemping to set password on ", $Computer, " for ", $Local_LocalAdmin, " - " -Color Cyan, White, Cyan, White, Yellow, White
                    #If ((Read-Host "Confirm (Y/N) ") -eq "y") {
                        $x = 1
                        $ResetLocalAdminJob = Start-Job -Name "ResetPassword" -ScriptBlock {Param($computer,$User,$Password);$User = [adsi]"WinNT://$computer/$User,user"; $User.SetPassword($Password);$User.SetInfo();} -ArgumentList $Computer,$Local_LocalAdmin,$Password -ErrorAction Stop
                        $ResetLocalAdminJobState = Get-Job $ResetLocalAdminJob.Id
                        While ($ResetLocalAdminJobState.State -eq "Running") {
                            Delete-LastLine -SameLine
                            $Duration = New-TimeSpan -Seconds($x)
                            $s = $Duration.TotalSeconds
                            $ts =  [timespan]::fromseconds($s)
                            $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
                            Write-Color -Text "$Counter/$ComputersCount", " - Attemping to set password on ", $Computer, " for ", $Local_LocalAdmin, " - ", $ReturnVariable, " - " -Color Cyan, White, Cyan, White, Yellow, White, Red, White
                            Sleep 1
                            $x ++
                        }
                        $ResetLocalAdminJobResult = Receive-Job -Job $ResetLocalAdminJob
                        $empty = Remove-Job -Job $ResetLocalAdminJob
                        $ResetLocalAdminJob = $null
                        $ResetLocalAdminJobState = $null
                        $ResetLocalAdminJobResult = $null
                        Write-Host "Complete" -ForegroundColor Green
                        $x = 1
                    #}
                    $Success = $true
                }
                Catch { Write-Host "Failed" -ForegroundColor Red; $empty = Remove-Job -Job $ResetLocalAdminJob }
                
                If ($Success -eq $false) {
                    #If ((Read-Host "Attempt forcing policy update (Y/N) ") -eq "y") {
                        Write-Host (UpdatePolicy -Server $Computer)
                        If ((Read-Host "Re-attempt settting password (Y/N) ") -eq "y") {
                            Try {
                                $x = 1
                                $ResetLocalAdminJob = Start-Job -Name "ResetPassword" -ScriptBlock {Param($computer,$User,$Password);$User = [adsi]"WinNT://$computer/$User,user"; $User.SetPassword($Password);$User.SetInfo();} -ArgumentList $Computer,$Local_LocalAdmin,$Password -ErrorAction Stop
                                $ResetLocalAdminJobState = Get-Job $ResetLocalAdminJob.Id
                                While ($ResetLocalAdminJobState.State -eq "Running") {
                                    Delete-LastLine -SameLine
                                    $Duration = New-TimeSpan -Seconds($x)
                                    $s = $Duration.TotalSeconds
                                    $ts =  [timespan]::fromseconds($s)
                                    $ReturnVariable = ("{0:hh\:mm\:ss}" -f $ts)
                                    Write-Color -Text "$Counter/$ComputersCount", " - Attemping to set password on ", $Computer, " for ", $Local_LocalAdmin, " - ", $ReturnVariable, " - " -Color Cyan, White, Cyan, White, Yellow, White, Red, White
                                    Sleep 1
                                    $x ++
                                }
                                $ResetLocalAdminJobResult = Receive-Job -Job $ResetLocalAdminJob
                                $empty = Remove-Job -Job $ResetLocalAdminJob
                                $ResetLocalAdminJob = $null
                                $ResetLocalAdminJobState = $null
                                $ResetLocalAdminJobResult = $null
                                Write-Host "Complete" -ForegroundColor Green
                                $x = 1
                                $Success = $true
                            }
                            Catch { 
                                Write-Host "Failed" -ForegroundColor Red; $empty = Remove-Job -Job $ResetLocalAdminJob
                            }
                        }
                    #}
                    #Else {
                    #    Try {
                    #        $ResetUser = $Local_Administrator
                    #        Write-Color -Text "$Counter/$ComputersCount", " - Attemping to set password on ", $Computer, " for ", $Local_LocalAdmin -Color Cyan, White, Cyan, White, Red -EndLine
                    #            If ((Read-Host "Confirm (Y/N): ") -eq "y") {
                    #                SetPassword -UserAccount $ResetUser -Password $Password
                    #            }
                    #        Write-Host "Complete" -ForegroundColor Green
                    #    }
                    #    Catch { Write-Host "Failed" -ForegroundColor Red; Write-Output $_ }
                    #}
                }
            }
            $Counter ++
        }
    }
    Catch { Write-Host "Failed" -ForegroundColor Red; Write-Output $_ }
}

ResetPassword
