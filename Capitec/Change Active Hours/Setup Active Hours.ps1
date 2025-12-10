$ErrorActionPreference = 'Stop'
$Servers = @()
$Servers += ,('CBVMPPRAPW004')
$Servers += ,('CBWLPPRAPW387')
$Servers += ,('CBWLPPRAPW502')
$Servers += ,('CBWLPPRWFW088')


$Details = @()
#D:\Apps\Captools\Scripts\ChangeActiveHours
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            $OS = (Get-WMIObject -Class Win32_OperatingSystem -Property Caption -ComputerName $Servers[$i]).Caption
            If ($OS -like '*2012*') {
                $Details += ,(New-Object -TypeName psobject -Property @{
                    Server = $Servers[$i]
                    OS = $OS
                    Status = 'Skipped'
                })
                Write-host $OS -ForegroundColor Yellow
            }
            Else {
                If (Test-Path ('\\' + $Servers[$i] + '\d$\Temp') -PathType Container) {

                }
                Else {
                    Try {Remove-Item ('\\' + $Servers[$i] + '\d$\Temp') -Force}
                    Catch {}
                    New-item ('\\' + $Servers[$i] + '\d$\Temp') -ItemType Directory
                }
                If (Test-Path ('\\' + $Servers[$i] + '\d$\Apps\Captools\Scripts\ChangeActiveHours') -PathType Container) {

                }
                Else {
                    Try { Remove-Item ('\\' + $Servers[$i] + '\d$\Apps\Captools\Scripts\ChangeActiveHours') -Force}
                    Catch {}
                    Try {New-item ('\\' + $Servers[$i] + '\d$\Apps\Captools\Scripts') -ItemType Directory}
                    Catch {}
                    New-item ('\\' + $Servers[$i] + '\d$\Apps\Captools\Scripts\ChangeActiveHours') -ItemType Directory
                }
                Copy-Item 'D:\Temp\Henri\Change Active Hours.zip' -Destination ('\\' + $Servers[$i] + '\d$\Temp')
                $ScriptBlock = {
                    If (Test-Path D:\Apps\Captools\Scripts\ChangeActiveHours) {
                        Remove-Item D:\Apps\Captools\Scripts\ChangeActiveHours -Recurse -Force
                    }
                    Expand-Archive -Path 'D:\Temp\Change Active Hours.zip' -DestinationPath D:\Apps\Captools\Scripts\ChangeActiveHours -Force
                    Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
                    If (Get-ScheduledTask | Where-Object taskname -like 'Change Active Hours*') {
                        Write-Host "Removing Scheduled Tasks"
                        Get-ScheduledTask | Where-Object taskname -like 'Change Active Hours*' | Unregister-ScheduledTask -Confirm:$False
                        
                    }
                    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 03-15.xml')) -TaskName 'Change Active Hours - 03-15'
                    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 06-18.xml')) -TaskName 'Change Active Hours - 06-18'
                    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 15-03.xml')) -TaskName 'Change Active Hours - 15-03'
                    Register-ScheduledTask -Xml ([String] (Get-Content 'D:\Apps\Captools\Scripts\ChangeActiveHours\Change Active Hours - 18-06.xml')) -TaskName 'Change Active Hours - 18-15'
                    Start-ScheduledTask -TaskName 'Change Active Hours - 15-03'
                    Start-Sleep -Seconds 2
                    Get-WinEvent -LogName Application -MaxEvents 10 | Where-Object {$_.ProviderName -eq 'ChangeActiveHours'} | Select-Object Message
                }
                Invoke-Command -ComputerName $Servers[$i] -ScriptBlock $ScriptBlock
            }
            $Details += ,(New-Object -TypeName psobject -Property @{
                Server = $Servers[$i]
                OS = $OS
                Status = 'Complete'
            })
        }
        Else {
            Write-Host "Offline" -ForegroundColor Red
            $Details += ,(New-Object -TypeName psobject -Property @{
                Server = $Servers[$i]
                Status = 'Offline'
            })
        }
    }
    Catch {
        Write-Host $_ -ForegroundColor Red
        $Details += ,(New-Object -TypeName psobject -Property @{
                Server = $Servers[$i]
                OS = $OS
                Status = $_
            })
    }
}
$Details | Out-GridView