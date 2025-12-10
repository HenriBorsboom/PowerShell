$ErrorActionPreference = 'Stop'
$Folders = Get-Content 'D:\Temp\CommVault\Inaccessible.txt'
$ErrorFile = 'D:\Temp\CommVault\Inaccessible_SetACL-Error.txt'
For ($i = 25; $i -lt $Folders.Count; $i ++) {
    Try {        
        Write-Host (($i + 1).ToString() + '/' + $Folders.Count.ToString() + ' - Processing ' + $Folders[$i] + ' - ') -NoNewline
        $NewAcl = Get-Acl -Path $Folders[$i]
        # Set properties
        $Newacl.SetOwner([System.Security.Principal.NTAccount]"BUILTIN\Administrators")
        $identity = "BUILTIN\Administrators"
        $fileSystemRights = "FullControl"
        $type = "Allow"
        $Inheritance = 'ContainerInherit,ObjectInherit'
        $Propagation = 'None'
        # Create new rule
        $fileSystemAccessRuleArgumentList = $identity, $fileSystemRights, $Inheritance, $Propagation, $type
        $fileSystemAccessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $fileSystemAccessRuleArgumentList
        # Apply new rule
        $NewAcl.AddAccessRule($fileSystemAccessRule)
        #$NewAcl.SetAccessRuleProtection($True, $False) #$True = isProtected (Disable Inheritance); $False = PreserveInheritance (Copy Existing Permissions)
        Set-Acl -Path $Folders[$i] -AclObject $NewAcl

        #$CurrentAccess = $NewAcl.Access

        # Grant modify permissions to each user
        #foreach ($Access in $NewAcl.Access) {
        $acl = Get-Acl $Folders[$i]
        For ($x = 0; $x -lt $NewAcl.Access.Count; $x ++) {
            $Access = $NewAcl.Access[$x]
            
            $Permission = $Access.IdentityReference, $Access.FileSystemRights, $Access.InheritanceFlags, $Access.PropagationFlags, $Access.AccessControlType
    
            $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
            #$acl.SetAccessRule($accessRule)
            $acl.AddAccessRule($accessRule)
            
        }
        Set-Acl -Path $Folders[$i] -ACLObject $acl
        Write-Host ("|- Granted modify permissions")
        Remove-Variable acl
        Remove-Variable Permission


        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host ("Unable to set ACL on " + $Folders[$i]) -ForegroundColor Red
        ($Folders[$i] + ',' + $_) | Out-File $ErrorFile -Encoding ascii -Append
    }
    Remove-Variable NewACL
    [GC]::Collect()
}