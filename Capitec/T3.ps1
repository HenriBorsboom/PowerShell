$ErrorActionPreference = 'Stop'
$Server = 'MercJump01'
$DebugState = $true
$File = 'C:\temp\test.html'

        Function Get-Shares {
                Param (
                        [Parameter(Mandatory=$True, Position=1)]
                        [String] $Server
                )
                Try {
                        $Shares = Get-WmiObject Win32_Share -ComputerName $Server -Authentication PacketIntegrity | Select-Object Name | Sort-Object Name
                        #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares Found: ' + $Shares.Count.ToString())
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
                                        Try 
                                        {
                                                #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting ACL of ' + $Share)
                                                $ACL = Get-ACL $Share -ErrorAction Stop
                                                
                                                $FileArray =@()

                                                ForEach ($AccessRule in $ACL.Access)
                                                {
                                                        $FileArray += [String] $AccessRule.IdentityReference + '(' + $AccessRule.FileSystemRights + ')'
                                                }
                                        }
                                        Catch {
                                                #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($_)
                                                $FileArray =@()
                                        }
                                }
                                $SMBArray =@()
                                #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Getting Share Security')
                                $ShareSecurity = Get-WmiObject -Query ("Select * from win32_LogicalShareSecuritySetting Where Name='" + $Share.Split("\")[3] + "'") -ComputerName $Server -Authentication PacketIntegrity 
                                If ($null -ne $ShareSecurity) {
                                        $ACLS = $ShareSecurity.GetSecurityDescriptor().Descriptor.DACL
                                        ForEach ($ACL in $ACLS) {
                                                $User = $ACL.Trustee.Name
                                                #If ($null -ne $user) {
                                                #        $user = $ACL.Trustee.SID
                                                #}
                                                $Domain = $ACL.Trustee.Domain
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
                        #Write-Log -LogFile $ServerLogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($_)
                        $ReturnShare = $null | ConvertTo-Html -head $a
                }
                #Write-Log -LogFile $ServerLogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ('Shares found: ' + $FinalShareArray.Count.ToString())
                $ReturnShare = $FinalShareArray | ConvertTo-Html -Head $a
                
                Switch ($DebugState) {
	                $True {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="file:///' + $ReportFolder + '/index.html">Home</a></h2>' + "`n"))
	                }
	                $False {
                                Return ($ReturnShare.Replace('</table>', '</table>' + "`n" + '<h2><a href="javascript:history.back()">Back</a> <a href="http://' + $GlobalConfig.Settings.Hosting.HTTPServer + ':' + $GlobalConfig.Settings.Hosting.HTTPPort + '/index.html">Home</a></h2>' + "`n"))
	                }
                }
                
        }

        Get-Shares -Server $Server | out-file $file; & $File
        