$ErrorActionPreference = 'Stop'
Clear-Host

[DateTime] $NotAfterDate  = '2023/05/31 1:59:59 AM'

$Properties = @()
$Properties += ,('PSParentPath')
$Properties += ,('NotAfter')
$Properties += ,('NotBefore')
$Properties += ,('DnsNameList')
$Properties += ,('Subject')
$Properties += ,('Issuer')

$SelectProperties = @()
$SelectProperties += ,('Server')
$SelectProperties += ,('PSParentPath')
$SelectProperties += ,('NotAfter')
$SelectProperties += ,('NotBefore')
$SelectProperties += ,('DnsNameList')
$SelectProperties += ,('Subject')
$SelectProperties += ,('Issuer')
$SelectProperties += ,('Active')

$Servers = @()
$Servers += ,('AGPMPRD01')
$Servers += ,('APPFSDRS01')
$Servers += ,('APPFSPRD01')
$Servers += ,('APPFSTST01')
$Servers += ,('AWSTEST01')
$Servers += ,('BCKDRS02')
$Servers += ,('BLNBKG01')
$Servers += ,('BLNCMR01')
$Servers += ,('BLNCPT01')
$Servers += ,('BLNDBN01')
$Servers += ,('BLNDRS03')
$Servers += ,('BLNHRZ01')
$Servers += ,('BLNPRD03')
$Servers += ,('BLNPRD04')
$Servers += ,('BLNTST04')
$Servers += ,('BLNTYG01')
$Servers += ,('BLNVDB01')
$Servers += ,('BLNWEL01')
$Servers += ,('BMCFPACPRD01')
$Servers += ,('BMCFPPRD01')
$Servers += ,('BMCFPSDPRD01')
$Servers += ,('BPGAPTST02')
$Servers += ,('BPGDRS02')
$Servers += ,('BPGPRD02')
$Servers += ,('BRNBKG01')
$Servers += ,('BRNCMR01')
$Servers += ,('BRNCPT01')
$Servers += ,('BRNDBN01')
$Servers += ,('BRNHRZ01')
$Servers += ,('BRNPTH01')
$Servers += ,('BRNSND01')
$Servers += ,('BRNSTR01')
$Servers += ,('BRNTRV01')
$Servers += ,('BRNTYG01')
$Servers += ,('BRNVDB01')
$Servers += ,('CAASYSDRS01')
$Servers += ,('CAASYSDRS02')
$Servers += ,('CAASYSPRD01')
$Servers += ,('CAASYSPRD02')
$Servers += ,('CAEMPRD01')
$Servers += ,('CAEMPRD02')
$Servers += ,('CAWCCDRS01')
$Servers += ,('CAWCCPRD01')
$Servers += ,('CAWCCPRD02')
$Servers += ,('CBLMERCJUMP05')
$Servers += ,('CBLMERCJUMP06')
$Servers += ,('CBLMERCJUMP07')
$Servers += ,('CBMERCHAWSSBL01')
$Servers += ,('CBMTIBCOINT01')
$Servers += ,('CBMTIBCOPRD01')
$Servers += ,('CBWLPPRDBW228')
$Servers += ,('CVCSDRS01')
$Servers += ,('CVCSPRD01')
$Servers += ,('CVEXCHWPRX01')
$Servers += ,('CVPRXWDRS01')
$Servers += ,('CVPRXWPRD01')
$Servers += ,('CVPRXWPRD02')
$Servers += ,('DCDRS01')
$Servers += ,('DCPRD01')
$Servers += ,('DCPRD02')
$Servers += ,('DCPRD03')
$Servers += ,('DCPRD04')
$Servers += ,('DCPRDAWS01')
$Servers += ,('DCPRDAWS02')
$Servers += ,('DHCPPRD01')
$Servers += ,('EMLPRD01')
$Servers += ,('EXCHCASPRD01')
$Servers += ,('EXCHPRD01')
$Servers += ,('FRAXSESPRD01')
$Servers += ,('FSDRS01')
$Servers += ,('FSPRD01')
$Servers += ,('HONAPPRD02')
$Servers += ,('HONDRS01')
$Servers += ,('HONWEBAPTST01')
$Servers += ,('ILMTPRD01')
$Servers += ,('INLBPRD01')
$Servers += ,('INLBPRD02')
$Servers += ,('KMSPRD01')
$Servers += ,('KYCDOBPRD01')
$Servers += ,('KYCDOBTST01')
$Servers += ,('MEAPPRD01')
$Servers += ,('MEB2')
$Servers += ,('MEB3')
$Servers += ,('MEB4')
$Servers += ,('MEBBACK')
$Servers += ,('MEBPROD')
$Servers += ,('MERCJUMP01')
$Servers += ,('MERCJUMPDRS01')
$Servers += ,('MQMONPRD01')
$Servers += ,('OCSPRD01')
$Servers += ,('ODSRPTPRD01')
$Servers += ,('PRNPRD01')
$Servers += ,('REUTERSDTS')
$Servers += ,('SCCMPRD02')
$Servers += ,('SHRAPPRD01')
$Servers += ,('SHRDRS01')
$Servers += ,('SHRPNTPRD01')
$Servers += ,('FILESERVER01')
$Servers += ,('SIGNAPDRS01')
$Servers += ,('SIGNAPPRD01')
$Servers += ,('SIGNAPTST01')
$Servers += ,('SIGNAPTST02')
$Servers += ,('SIGNWEBDRS01')
$Servers += ,('SIGNWEBPRD01')
$Servers += ,('SIGNWEBTST01')
$Servers += ,('SMSPRD01')
$Servers += ,('SNDLNKTST01')
$Servers += ,('SQLCLDRS01')
$Servers += ,('SQLCLPRD')
$Servers += ,('SQLCLPRD01')
$Servers += ,('SQLCLPRD02')
$Servers += ,('SQLCLPRD03')
$Servers += ,('SQLCLPRDSHARE')
$Servers += ,('SQLCLTST01')
$Servers += ,('SQLCLWDRS01')
$Servers += ,('SQLDEVTST01')
$Servers += ,('SQLPRD02')
$Servers += ,('SVCSNDMC01')
$Servers += ,('TIBCODRS01')
$Servers += ,('TIBCOPRD01')
$Servers += ,('TIBCOPRD02')
$Servers += ,('TIBCOTST01')
$Servers += ,('TRVPRIMEBACKUP')
$Servers += ,('WASDRS03')
$Servers += ,('WASPRD03')
$Servers += ,('WASPRD04')
$Servers += ,('WASTST02')

$AllDetails = @()
$Errors = @()
For ($ServerI = 0; $ServerI -lt $Servers.Count; $ServerI ++) {
    Write-Output (($ServerI + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$ServerI])
    Try {
        If (Test-Connection $Servers[$Serveri] -Count 2 -Quiet) {
            $Certs = Invoke-Command -ComputerName $Servers[$ServerI] -Scriptblock {Get-ChildItem Cert:\LocalMachine\ -Recurse }
            $WildCerts = $Certs | Where-Object {$_.Subject -like 'CN=*.mercantile.co.za*'}
            Write-Output ("|- " + $WildCerts.Count.ToString() + " found")
            ForEach ($WildCert in $WildCerts) {
                If ($WildCert.NotAfter -ge $NotAfterDate) {
                    $AllDetails += ,(New-Object -TypeName PSObject -Property @{
                        Server = $Servers[$ServerI]
                        Subject = $WildCert.Subject
                        DNSNameList = $WildCert.DnsNameList
                        NotBefore = $WildCert.NotBefore
                        NotAfter = $WildCert.NotAfter
                        Issues = $WildCert.Issuer
                        Path = $WildCert.PSParentPath
                        Active = $True
                    })
                }
                Else {
                    $AllDetails += ,(New-Object -TypeName PSObject -Property @{
                        Server = $Servers[$ServerI]
                        Subject = $WildCert.Subject
                        DNSNameList = $WildCert.DnsNameList
                        NotBefore = $WildCert.NotBefore
                        NotAfter = $WildCert.NotAfter
                        Issues = $WildCert.Issuer
                        Path = $WildCert.PSParentPath
                        Active = $False
                    })
                }
            }
        }
    }
    Catch {
        Write-Output ("Offline - " + $_)
        $Errors += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$ServerI]
            Error = $_
        })
    }
}
$AllDetails | Select $SelectProperties | Out-GridView
$Errors