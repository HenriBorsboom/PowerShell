$Servers = @()
$Servers += ,('CBWLNQADBW193')
$Servers += ,('CBARRQA01')
$Servers += ,('CBDLSQA02')
$Servers += ,('CBDLSQA01')
$Servers += ,('CCQAWF002')
$Servers += ,('CCQAWF001')
$Servers += ,('CCQADB029')
$Servers += ,('CBBANCSDBQA07')
$Servers += ,('CBBANCSDBQA08')
$Servers += ,('CBBANCSDBQA07')
$Servers += ,('CBBANCSDBQA07')
$Servers += ,('CBBANCSDBQA07')
$Servers += ,('CBAWNQADBW015')
$Servers += ,('CCQADB075')
$Servers += ,('CBDBNQADBW044')
$Servers += ,('CBWLNQADBW003')
$Servers += ,('CBVMNQADBW011')
$Servers += ,('CBDBNQADBW010')
$Servers += ,('CBWLNQADBW009')

$Date = (Get-Date).AddMonths(-6)

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i] + ' - ') -NoNewline
    Try {
        $Events = get-winevent -LogName setup -ComputerName $Servers[$i] | Where-Object {$_.Message -like '*A reboot is necessary*' -and $_.TimeCreated -gt $Date}
        If ($Events -eq $Null) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                i = $i
                Server = $Servers[$i]
                TimeCreated = $null
                Message = "No matching criteria"
            })
        }
        Else {
            Foreach ($Event in $Events) {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    i = $i
                    Server = $Servers[$i]
                    TimeCreated = $Event.TimeCreated
                    Message = $Event.Message
                })
            }
        }
        
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            i = $i
            Server = $Servers[$i]
            TimeCreated = $null
            Message = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Out-GridView
#$Events = get-winevent -LogName setup | Where-Object {$_.Message -like '*A reboot is necessary*' -and $_.TimeCreated -gt ((Get-Date).AddYears(-1))}

#$Events[0] | Select TimeCreated, Message
