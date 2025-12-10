$ErrorActionPreference = 'Stop'
Function Get-Shares {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Server
    )
    Try {
        $Shares = Get-WmiObject Win32_Share -ComputerName $Server -Authentication PacketIntegrity | Select-Object Name | Sort-Object Name
        #Write-Output ('Shares Found: ' + $Shares.Count.ToString())
        $ShareDataArray =@()
        ForEach ($Share in $Shares) {
            If ($Share.Name.Contains("\\")) {
                $ShareDataArray += $Share.Name
            }
            Else {
                $ShareDataArray += "\\$Server\" + $Share.Name
            }
        }
            
        $FinalShareArray =@()
        ForEach ($Share in $ShareDataArray ) {
            If ($Share -notlike '*\IPC$') {
                Try {
                    #Write-Output ('Getting ACL of ' + $Share)
                    $ACL = Get-ACL $Share -ErrorAction Stop
                                    
                    $FileArray =@()

                    ForEach ($AccessRule in $ACL.Access) {
                        $FileArray += [String] $AccessRule.IdentityReference + '(' + $AccessRule.FileSystemRights + ')'
                    }
                }
                Catch {
                    #Write-Output ($_)
                        $FileArray =@()
                    }
                }
                $SMBArray =@()
                #Write-Output ('Getting Share Security')
                $ShareSecurity = Get-WmiObject -Query ("Select * from win32_LogicalShareSecuritySetting Where Name='" + $Share.Split("\")[3] + "'") -ComputerName $Server -Authentication PacketIntegrity 
                If ($null -ne $ShareSecurity) {
                    $ACLS = $ShareSecurity.GetSecurityDescriptor().Descriptor.DACL
                        ForEach ($ACL in $ACLS) {
                            Switch($ACL.AccessMask) {
                                2032127 {$Perm = "Full Control"}
                                1245631 {$Perm = "Change"}
                                1179817 {$Perm = "Read"}
                            }
                        $SMBArray += $ACL.Trustee.Domain + '\' + $ACL.Trustee.Name + ' ' + $Perm
                    }
                }
                $FinalShareArray += ,(New-Object -TypeName PSObject -Property @{
                    ShareName = $Share
                    SMB = [String] $SMBArray
                    NTFS = [string] $FileArray
                })
        }
    }
    Catch {
        #Write-Output ($_)
        $ReturnShare = $null | ConvertTo-Html -head $a
    }
    #Write-Output ('Shares found: ' + $FinalShareArray.Count.ToString())
    Return $FinalShareArray
 }


Clear-Host
$Servers = @()
$Servers += ,('CBPO')
$Servers += ,('CBAWPPRDBW027')
$Servers += ,('CBWLPPRDBW091')
$Servers += ,('CBPOST01')
$Servers += ,('CBPOST02')
$Servers += ,('CBTERM01')
$Servers += ,('CBPORT')
$Servers += ,('CBPORT02')
$Servers += ,('CBNXB01')
$Servers += ,('CBNXB02')

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Output (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i])
    $Shares = Get-Shares -Server $Servers[$i]
    ForEach ($Share in $Shares) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            ShareName = $Share.Sharename
            SMB = $Share.SMB
            NTFS = $Share.NTFS
        })
    }
}
$Details