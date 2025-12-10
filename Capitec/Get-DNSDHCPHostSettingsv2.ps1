Function Stop-Jobs {
    Get-Job | Stop-Job
    Get-Job | Remove-Job
}
Function Wait-Jobs {
    While ((get-job).State -eq 'Running') { "Still busy...."; sleep 1 }
}
Function Start-Jobs {
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("TargetOnly","ArgumentsOnly","Both","None")]
        [String] $PassTargetToScriptBlock, `
        [Parameter(Mandatory=$True, Position=2)]
        [ScriptBlock] $ScriptBlock, `
        [Parameter(Mandatory=$False, Position=3)]
        [Object[]] $ScriptBlockArguments, `
        [Parameter(Mandatory=$True, Position=4)]
        [Object[]] $Targets, `
        [Parameter(Mandatory=$False, Position=5)]
        [Switch] $ReportImmediate=$False, `
        [Parameter(Mandatory=$False, Position=6)]
        [Int32]    $MaximumJobs=$env:NUMBER_OF_PROCESSORS
    )

    $Jobs = @()
    
    For ($Index = 0; $Index -lt $Targets.Count; $Index ++) {
        $Target = $Targets[$index]
        Write-Host (($Index + 1).ToString() + '/' + $Targets.Count.ToString() + ' - Starting Job for ' + $Target)
        Switch ($PassTargetToScriptBlock) {
            "TargetOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Target)}
            "ArgumentsOnly" {$Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $ScriptBlockArguments)}
            "Both" {
                $Arguments = @()
                $Arguments = $Arguments + $Target
                ForEach ($ScriptBlockArgument in $ScriptBlockArguments) {
                    $Arguments = $Arguments + $ScriptBlockArgument
                }
                $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments)
            }
            "None" { $Jobs = $Jobs + (Start-Job -ScriptBlock $ScriptBlock ) }
        }
        $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})

        While ($RunningJobs.Count -ge $MaximumJobs) {
            $ActiveJob = Get-Job | Where State -eq 'Completed'
            Switch ($ReportImmediate) {
                $True {
                    Get-Job | Where State -eq 'Running' | Receive-Job
                }
                $False {
                    If ($Null -ne $ActiveJob) {
                        Receive-Job $ActiveJob | Remove-Job $ActiveJob
                    }
                }
            }
            $RunningJobs = @($Jobs | Where-Object {$_.State -eq 'Running'})
        }
    }
    Wait-Job -Job $Jobs | Out-Null
    $FailedJobs = @($Jobs | Where-Object {$_.State -eq 'Failed'})
    If ($FailedJobs.Count -gt 0) {
        ForEach ($FailedJob in $FailedJobs) {
            $FailedJob.ChildJobs[0].JobStateInfo.Reason.Message
        }
    }
    Get-Job | Wait-Job | Remove-Job
    Return $JobResults
}
#Example of Use
Clear-Host
$DNSDHCPHostSettings = {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$False, Position=2)]
        [PSCredential] $Credential
    )
    
    $ErroractionPreference = 'Stop'
    
    $OutFile = ('C:\Temp\Henri\DNSDHCPHostSettings5\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.txt')
    $CSVOutFile = ('C:\Temp\Henri\DNSDHCPHostSettings5\' + $Server + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

    $Details = @()
    Try {
        ('Invoking command on' + $Server + ', with ' + $Credential.UserName) | Out-File $OutFile -Encoding ascii -Append
        $Result = Invoke-Command -ComputerName $server -ScriptBlock {
            Function Get-ConfiguredHosts {
                # Define the path to the hosts file
                $Hosts = @()
                # Read and filter the hosts file
                Get-Content -Path "C:\windows\system32\drivers\etc\hosts" | ForEach-Object {
                    # Skip lines starting with '#' (comments) or empty lines
                    if ($_ -notmatch "^\s*#|^\s*$") {
                        # Use regex to match and split IP and hostname
                        if ($_ -match "^\s*(\d{1,3}(\.\d{1,3}){3}|::1)\s+(\S+)") {
                            # Output the matched IP and hostname
                            $Hosts += ,($matches[1] + " " + $matches[3])
                        }
                    }
                }
                Return $Hosts -join ';'
            }
            [Object[]] $AdapterGUIDs = Get-NetAdapter | Select-Object InterfaceGuid
            ForEach ($AdapterGUID in $AdapterGUIDs) {
                $DHCPServerPublished = $False
                $DHCPNameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).DhcpNameServer
                $NameServer = (Get-ItemProperty ("HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\" + $AdapterGUID.InterfaceGuid)).NameServer
                If ($DHCPNameServer -ne '') {
                    $DHCPServerPublished = $True
                }
                Else {
                    $DHCPServerPublished = $False
                }
                If ($NameServer -eq '') {
                    $DHCPInUse = $True
                }
                Else {
                    $DHCPInUse = $false
                }
            }
            $Hosts = Get-ConfiguredHosts
            Return $DHCPNameServer, $NameServer, $DHCPServerPublished, $DHCPInUse, $Hosts
        }
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            DHCPNameServer = $Result[0]
            NameServer = $Result[1]
            DHCPServerPublished = $Result[2]
            DHCPInUse = $Result[3]
            Hosts = $Result[4]
            Result = 'Success'
        })
        Write-Host ($Server + ": Complete") -ForegroundColor Green
        ('Complete') | Out-File $OutFile -Encoding ascii -Append
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Server
            DHCPNameServer = $null
            NameServer = $null
            DHCPServerPublished = $null
            DHCPInUse = $null
            Hosts = $null
            Result = $_.Exception.Message
        })
        Write-Host ($Server + ": " + $_.Exception.Message) -ForegroundColor Red
        ('Failed. ' + $_.Exception.Message) | Out-File $OutFile -Encoding ascii -Append
    }
    $Params = @("Server", "DHCPNameServer", "NameServer", "DHCPServerPublished", "DHCPInUse", "Hosts", "Result")
    $Details | Select-Object $Params | Export-CSV $CSVOutFile -Delimiter ',' -NoTypeInformation
}
Function Get-DomainServers {
    $LogonDate = (Get-Date).AddMonths(-2)
    $Servers = Get-ADComputer -Filter {Enabled -eq $True -and LastLogonDate -gt $LogonDate -and OperatingSystem -like '*server*'} -Properties LastLogonDate, Enabled, OperatingSystem
    Return $Servers.Name
}
#$Servers = Get-DomainServers
#$Credential = Get-Credential


$SBArgs = @($Credential)
#Start-Jobs -ScriptBlock $DNSDHCPHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
#$Servers = RerunServers; Start-Jobs -ScriptBlock $DNSDHCPHostSettings -ScriptBlockArguments $SBArgs -Targets $Servers -PassTargetToScriptBlock Both -MaximumJobs 10
$Servers = @()
$Servers += ,('ASKYBFTCDC002')
$Servers += ,('CB0244')
$Servers += ,('CB0256')
$Servers += ,('CBAWNDVAPW100')
$Servers += ,('CBAWNDVAPW247')
$Servers += ,('CBAWNDVAPW248')
$Servers += ,('CBAWNDVAPW250')
$Servers += ,('CBAWNDVAPW251')
$Servers += ,('CBAWNDVAPW252')
$Servers += ,('CBAWNDVAPW258')
$Servers += ,('CBAWNDVAPW259')
$Servers += ,('CBAWNDVAPW262')
$Servers += ,('CBAWNDVAPW263')
$Servers += ,('CBAWNDVAPW264')
$Servers += ,('CBAWNDVAPW266')
$Servers += ,('CBAWNDVAPW296')
$Servers += ,('CBAWNDVAPW297')
$Servers += ,('CBAWNDVAPW298')
$Servers += ,('CBAWNDVAPW299')
$Servers += ,('CBAWNDVAPW372')
$Servers += ,('CBAWNDVAPW377')
$Servers += ,('CBAWNDVAPW378')
$Servers += ,('CBAWNDVAPW386')
$Servers += ,('CBAWNDVAPW387')
$Servers += ,('CBAWNDVAPW434')
$Servers += ,('CBAWNDVAPW443')
$Servers += ,('CBAWNDVAPW444')
$Servers += ,('CBAWNDVDBW005')
$Servers += ,('CBAWNITAPW004')
$Servers += ,('CBAWNITAPW010')
$Servers += ,('CBAWNITAPW018')
$Servers += ,('CBAWNITAPW019')
$Servers += ,('CBAWNITAPW020')
$Servers += ,('CBAWNITAPW043')
$Servers += ,('CBAWNITAPW044')
$Servers += ,('CBAWNITDBW001')
$Servers += ,('CBAWNITDBW002')
$Servers += ,('CBAWNQAAPW017')
$Servers += ,('CBAWNQAAPW018')
$Servers += ,('CBAWNQAAPW020')
$Servers += ,('CBAWNQAAPW022')
$Servers += ,('CBAWNQAAPW056')
$Servers += ,('CBAWNQAAPW057')
$Servers += ,('CBAWNQAAPW058')
$Servers += ,('CBAWNQAAPW059')
$Servers += ,('CBAWNQAAPW060')
$Servers += ,('CBAWNQAAPW089')
$Servers += ,('CBAWNQADBW004')
$Servers += ,('CBAWNQADBW008')
$Servers += ,('CBAWNQADBW010')
$Servers += ,('CBAWPPRAPW035')
$Servers += ,('CBAWPPRAPW038')
$Servers += ,('CBAWPPRAPW064')
$Servers += ,('CBAWPPRAPW110')
$Servers += ,('CBAWPPRAPW111')
$Servers += ,('CBAWPPRAPW112')
$Servers += ,('CBAWPPRAPW113')
$Servers += ,('CBAWPPRDBW044')
$Servers += ,('CBAWSDC001')
$Servers += ,('CBAWSDC002')
$Servers += ,('CBAWSDC003')
$Servers += ,('CBAWSDC004')
$Servers += ,('CBAWSDC005')
$Servers += ,('CBAWSDC006')
$Servers += ,('CBBFTCDC001')
$Servers += ,('CBBFTCDC002')
$Servers += ,('CBBFTCDC003')
$Servers += ,('CBBFTCDC004')
$Servers += ,('CBBLVCE01')
$Servers += ,('CBDC001')
$Servers += ,('CBDC002')
$Servers += ,('CBDC004')
$Servers += ,('CBDC005')
$Servers += ,('CBDC006')
$Servers += ,('CBDC007')
$Servers += ,('CBDLSDEV01')
$Servers += ,('CBDLSDEV02')
$Servers += ,('CBDLSINT01')
$Servers += ,('CBDLSINT02')
$Servers += ,('CBDLSQA01')
$Servers += ,('CBDLSQA02')
$Servers += ,('CBDRDBCL01')
$Servers += ,('CBEUNPRDDC0001')
$Servers += ,('cbeunprddc0002')
$Servers += ,('CBHV1001')
$Servers += ,('CBHV1002')
$Servers += ,('CBHV1003')
$Servers += ,('CBHV1004')
$Servers += ,('cblabsrv3')
$Servers += ,('CBPAYGATEDEV01')
$Servers += ,('CBQADBCL01')
$Servers += ,('CBSTBCA01')
$Servers += ,('CBSTBCE01')
$Servers += ,('CBSTBCLOGSDEV01')
$Servers += ,('CBSTBHVCL03')
$Servers += ,('CBSTBLC01')
$Servers += ,('CBSTBNET01')
$Servers += ,('CBUTLDEV01')
$Servers += ,('CBVMNDVAPW006')
$Servers += ,('CBVMNDVAPW030')
$Servers += ,('CBVMNDVAPW031')
$Servers += ,('CBVMNDVAPW058')
$Servers += ,('CBVMNDVAPW138')
$Servers += ,('CBVMNDVAPW139')
$Servers += ,('CBVMNDVAPW140')
$Servers += ,('CBVMNDVAPW144')
$Servers += ,('CBVMNDVDBW014')
$Servers += ,('CBVMNDVDBW015')
$Servers += ,('CBVMNDVDBW033')
$Servers += ,('CBVMNITAPW029')
$Servers += ,('CBVMNQAAPW002')
$Servers += ,('CBVMNQAAPW003')
$Servers += ,('CBVMNQAAPW016')
$Servers += ,('CBVMNQAAPW037')
$Servers += ,('CBVMNQADBW006')
$Servers += ,('CBVMNQADBW008')
$Servers += ,('CBVMNQADBW012')
$Servers += ,('CBVMPPRAPW010')
$Servers += ,('CBVMPPRAPW011')
$Servers += ,('CBVMPPRAPW025')
$Servers += ,('CBVMPPRAPW061')
$Servers += ,('CBVMPPRAPW162')
$Servers += ,('CBVMPPRDBW002')
$Servers += ,('CBVMPPRDBW003')
$Servers += ,('CBVMPPRDBW006')
$Servers += ,('CBVMPPRDBW007')
$Servers += ,('CBWLNDVAPW113')
$Servers += ,('CBWLNDVAPW654')
$Servers += ,('CBWLNDVAPW669')
$Servers += ,('CBWLNDVDBW122')
$Servers += ,('CBWLNDVDBW128')
$Servers += ,('CBWLNDVDBW258')
$Servers += ,('CBWLNDVDBW350')
$Servers += ,('CBWLNDVDBW402')
$Servers += ,('CBWLNDVWFW088')
$Servers += ,('CBWLNDVWFW089')
$Servers += ,('CBWLNDVWFW097')
$Servers += ,('CBWLNITAPW002')
$Servers += ,('CBWLNITDBW052')
$Servers += ,('CBWLNQAAPW001')
$Servers += ,('CBWLNQAAPW018')
$Servers += ,('CBWLNQAAPW019')
$Servers += ,('CBWLNQAAPW202')
$Servers += ,('CBWLNQAAPW250')
$Servers += ,('CBWLNQAAPW251')
$Servers += ,('CBWLNQADBW040')
$Servers += ,('CBWLNQADBW169')
$Servers += ,('CBWLNQAWFW049')
$Servers += ,('CBWLNQAWFW050')
$Servers += ,('CBWLNQAWFW051')
$Servers += ,('CBWLNQAWFW052')
$Servers += ,('CBWLPPRAPW024')
$Servers += ,('CBWLPPRAPW050')
$Servers += ,('CBWLPPRAPW057')
$Servers += ,('CBWLPPRAPW058')
$Servers += ,('CBWLPPRAPW060')
$Servers += ,('CBWLPPRAPW061')
$Servers += ,('CBWLPPRAPW166')
$Servers += ,('CBWLPPRAPW168')
$Servers += ,('CBWLPPRAPW178')
$Servers += ,('CBWLPPRAPW216')
$Servers += ,('CBWLPPRAPW643')
$Servers += ,('CBWLPPRAPW645')
$Servers += ,('CBWLPPRAPW646')
$Servers += ,('CBWLPPRAPW647')
$Servers += ,('CBWLPPRAPW648')
$Servers += ,('CBWLPPRAPW649')
$Servers += ,('CBWLPPRDBW168')
$Servers += ,('CBWLPPRDBW258')
$Servers += ,('CBWLPPRDBW285')
$Servers += ,('CBWLPPRDBW294')
$Servers += ,('CBWLPPRWFW064')
$Servers += ,('CBWLPPRWFW065')
$Servers += ,('CBWLPPRWFW066')
$Servers += ,('CBWLPPRWFW067')
$Servers += ,('CBWLPPRWFW110')
$Servers += ,('cbzanprddc0001')
$Servers += ,('cbzanprddc0002')
$Servers += ,('CCDEVAPP334')
$Servers += ,('CCDEVAPP336')
$Servers += ,('CCDEVDB219')
$Servers += ,('ccdevdbcl07')
$Servers += ,('CCDEVWF067')
$Servers += ,('CCDEVWF083')
$Servers += ,('CCPRDAPP086')
$Servers += ,('CCPRDAPP298')
$Servers += ,('CCPRDAPP317')
$Servers += ,('CCPRDDB123')
$Servers += ,('CCPRDDB130')
$Servers += ,('CCPRDDBCL07')
$Servers += ,('CCQAAPP188')
$Servers += ,('CLDCTMRTHAFSINT')
$Servers += ,('CLESIGDB04')
$Servers += ,('clesigdbdev04')
$Servers += ,('CLESIGDBDR04')
$Servers += ,('CLESIGDBDR05')
$Servers += ,('CLESIGDBQA06')
$Servers += ,('CLESIGDBQA07')
$Servers += ,('CLIDAPPRD01')
$Servers += ,('RVLDNSTEST01')
$Servers += ,('SKYDC003')
$Servers += ,('TECHSTLOTH')
$Servers += ,('WDCASHSUVV01')
$Servers += ,('WDCASHSUVV02')
$Servers += ,('WDCLDDPSDKERB')
$Servers += ,('WDCLDPLEMOI')
$Servers += ,('WDCLDPLES3SYNC')
$Servers += ,('WDCVCOOBSAS1')
$Servers += ,('WDISAENGACME05')
$Servers += ,('WDOPLNP1CNECT2')
$Servers += ,('WDPLBCORBBDB01')
$Servers += ,('WDPLBCORBCDB18')
$Servers += ,('WDPLDRINTANSPL1')
$Servers += ,('WDTSCBRBBCDB18')
$Servers += ,('WDTSCBRBSSW01')
$Servers += ,('WICASHSUVV01')
$Servers += ,('WICASHSUVV02')
$Servers += ,('WITSCBRBRNINT1')
$Servers += ,('WPCVCOOBPCCS1')
$Servers += ,('WPCVCOOBPCCS2')
$Servers += ,('WPCVCOOBPCCS3')
$Servers += ,('WPCVCOOBSAREP1')
$Servers += ,('WPCVCOOBSAREP2')
$Servers += ,('WPCVCOOBSAS10')
$Servers += ,('WPCVCOOBSAS11')
$Servers += ,('WPCVCOOBSAS12')
$Servers += ,('WPCVCOOBSAS1')
$Servers += ,('WPCVCOOBSAS2')
$Servers += ,('WPCVCOOBSAS3')
$Servers += ,('WPCVCOOBSAS4')
$Servers += ,('WPCVCOOBSAS5')
$Servers += ,('WPCVCOOBSAS6')
$Servers += ,('WPCVCOOBSAS7')
$Servers += ,('WPCVCOOBSAS8')
$Servers += ,('WPCVCOOBSAS9')
$Servers += ,('WPINSURAPRFPD2')
$Servers += ,('WPISAENGSCMNA1')
$Servers += ,('WPISAENGSECTNA')
$Servers += ,('WPPAYSVCWPEFT1')
$Servers += ,('WPPLRCLSBVSTP3')
$Servers += ,('WPPLRDOCWF1')
$Servers += ,('WPPLRDOCWF2')
$Servers += ,('WPPLRDOCWF3')
$Servers += ,('WPWSPENGIDES01')
$Servers += ,('WQAMRISKACT101')
$Servers += ,('WQAMRISKACT102')
$Servers += ,('WQAMRISKSAM')
$Servers += ,('WQAMRISKUDM1')
$Servers += ,('WQAMRISKWLXB01')
$Servers += ,('WQAMRISKWLXR01')
$Servers += ,('WQAMRISKWLXR02')
$Servers += ,('WQCASHSUVV01')
$Servers += ,('WQCASHSUVV02')
$Servers += ,('WQCVCOOBSAS10')
$Servers += ,('WQCVCOOBSAS2')
$Servers += ,('WQCVCOOBSAS3')
$Servers += ,('WQCVCOOBSAS4')
$Servers += ,('WQCVCOOBSAS5')
$Servers += ,('WQCVCOOBSAS6')
$Servers += ,('WQCVCOOBSAS7')
$Servers += ,('WQCVCOOBSAS8')
$Servers += ,('WQCVCOOBSAS9')
$Servers += ,('WQOWPBPMAPA1')

Start-Jobs -ScriptBlock $DNSDHCPHostSettings -Targets $Servers -PassTargetToScriptBlock TargetOnly -MaximumJobs 10