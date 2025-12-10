$ErrorActionPreference = 'Stop'
$StartDate = Get-Date -Format ("yyyy/MM/dd HH:mm:ss")
$StartTime = Get-Date
Clear-Host
$Source = 'C:\Temp2'
$OutFile = 'C:\temp1\Henri\'+ ($Source.Replace(':','_').Replace('\','_')) +'_Full_ACL.csv'
Try {
    $SplitPath = $OutFile -Split '\\'
    For ($Spliti = 0; $Spliti -lt ($SplitPath.Count - 1); $Spliti ++) {
            If (!(Test-Path ($SplitPath[0..$Spliti] -join '\'))) {
                    New-Item ($SplitPath[0..$Spliti] -join '\') -ItemType Directory | Out-Null
            }
    }
    If ((Test-Path $OutFile)) {
            $OutFile = (($SplitPath[0..($SplitPath.Count-2)] -join '\') + '\'+ (get-date -Format('yyyy-MM-dd HH-mm-ss')) + '__' + $SplitPath[-1])
    }
}
Catch {
    Write-Output $_
}
$Folders = Get-ChildItem -Force -LiteralPath $Source

'"Path","Owner","IdentityReference","AccessControlType","FileSystemRights","InheritanceFlags","PropagationFlags"' | Out-File $OutFile -Encoding ascii -Force
$Errors = @()
For ($Topi = 0; $Topi -lt $Folders.Count; $Topi ++) {
    Try {
        $currentTime = Get-Date
        $elapsedTime = $currentTime - $startTime

        If ($Topi -eq 0) { 
            $TopaverageTimePerFile = $elapsedTime / 1
        }
        Else {
            $TopaverageTimePerFile = $elapsedTime / $Topi
        }

        $TopremainingFiles = $Folders.Count - $Topi
        $estimatedTimeRemaining = $TopaverageTimePerFile * $TopremainingFiles

        $estimatedCompletionTime = $currentTime + $estimatedTimeRemaining
        Write-Progress -Activity 'Getting Top ACLs' -PercentComplete (($Topi + 1) / $Folders.Count * 100) -Status ((($Topi + 1) / $Folders.Count * 100).ToString() + ' % - ETC: ' + $estimatedCompletionTime) -ID 1
        
        $ACLS = $Folders[$Topi] | Get-Acl
        
        For ($ACLi = 0; $ACLi -lt $ACLs.Access.Count; $ACLi ++) {
            If ($ACLs.Access[$ACLi].FileSystemRights -eq '-536805376') {
                ('"' + $ACLs.Path.ToString().Replace('Microsoft.PowerShell.Core\FileSystem::', '') + '","' + $ACLs.Owner + '","' + $ACLs.Access[$ACLi].IdentityReference + '","' + $ACLs.Access[$ACLi].AccessControlType + '","' + 'Modify, Synchronize' + '","' + $ACLs.Access[$ACLi].InheritanceFlags + '","' + $ACLs.Access[$ACLi].PropagationFlags + '"') | Out-File $OutFile -Append -Encoding ascii
            }
            Else {
                ('"' + $ACLs.Path.ToString().Replace('Microsoft.PowerShell.Core\FileSystem::', '') + '","' + $ACLs.Owner + '","' + $ACLs.Access[$ACLi].IdentityReference + '","' + $ACLs.Access[$ACLi].AccessControlType + '","' + $ACLs.Access[$ACLi].FileSystemRights.ToString() + '","' + $ACLs.Access[$ACLi].InheritanceFlags + '","' + $ACLs.Access[$ACLi].PropagationFlags + '"') | Out-File $OutFile -Append -Encoding ascii
            }
        }
        $SubFolders = Get-ChildItem -LiteralPath $Folders[$Topi].FullName -Force -Recurse
        For ($Subi = 0; $Subi -lt $SubFolders.Count; $Subi ++) {
            If ($Subi -eq 0) { 
                $SubaverageTimePerFile = $elapsedTime / 1
            }
            Else {
                $SubaverageTimePerFile = $elapsedTime / $Subi
            }
    
            $SubremainingFiles = $SubFolders.Count - $Subi
            $estimatedTimeRemaining = $SubaverageTimePerFile * $SubremainingFiles
            $estimatedCompletionTime = $currentTime + $estimatedTimeRemaining
            Write-Progress -Activity 'Getting Sub ACLs' -PercentComplete (($Subi + 1) / $SubFolders.Count * 100) -Status ((($Subi + 1) / $SubFolders.Count * 100).ToString() + ' %') -ParentId 1
            
            $ACLS = $SubFolders[$Subi] | Get-Acl
            For ($ACLi = 0; $ACLi -lt $ACLs.Access.Count; $ACLi ++) {
                If ($ACLs.Access[$ACLi].FileSystemRights -eq '-536805376') {
                    ('"' + $ACLs.Path.ToString().Replace('Microsoft.PowerShell.Core\FileSystem::', '') + '","' + $ACLs.Owner + '","' + $ACLs.Access[$ACLi].IdentityReference + '","' + $ACLs.Access[$ACLi].AccessControlType + '","' + 'Modify, Synchronize' + '","' + $ACLs.Access[$ACLi].InheritanceFlags + '","' + $ACLs.Access[$ACLi].PropagationFlags + '"') | Out-File $OutFile -Append -Encoding ascii
                }
                Else {
                    ('"' + $ACLs.Path.ToString().Replace('Microsoft.PowerShell.Core\FileSystem::', '') + '","' + $ACLs.Owner + '","' + $ACLs.Access[$ACLi].IdentityReference + '","' + $ACLs.Access[$ACLi].AccessControlType + '","' + $ACLs.Access[$ACLi].FileSystemRights.ToString() + '","' + $ACLs.Access[$ACLi].InheritanceFlags + '","' + $ACLs.Access[$ACLi].PropagationFlags + '"') | Out-File $OutFile -Append -Encoding ascii
                }
            }
        }
    }
    Catch {
        Write-Output ('Top Index: ' + $Topi.ToString())
        If ($null -eq $Subi) {
            Write-Output ('Sub Index: $null')
            $Subi = $null
        }
        Else {
            Write-Output ('Sub Index: ' + $Subi.ToString())
        }
        Write-Output ('Error: ' + $_)
        $Errors += ,(New-Object -TypeName PSObject -Property @{
            TopIndex = $Topi
            SubIndex = $Subi
            TopFolder = $Folders[$Topi].FullName
            SubFolder = $SubFolders[$Subi].FullName
            Error = $_
        })
    }
}
$Errors

Write-Output ('OutFile: ' + $OutFile)
Write-Output ('Start Time: ' + $StartDate)
Write-Output ('End Time: ' + (Get-Date -Format ("yyyy/MM/dd HH:mm:ss")))