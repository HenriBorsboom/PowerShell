$Source = ('C:\temp1\Henri\C__Temp2_Full_ACL.csv')
$NewACLs = Get-Content $Source | ConvertFrom-Csv

$Errors = @()
$Success = @()
For ($ACLi = 0; $ACLi -lt $NewACLs.Count; $ACLi ++) {
    Write-Output (($ACLi + 1).ToString() + '/' + $NewACLs.Count.ToString() + ' - Processing ' + $NewACLs[$ACLi].Path + ' Account: ' + $NewACLs[$ACLi].IdentityReference)
    $EmptyAcl = New-Object System.Security.AccessControl.DirectorySecurity
    Try {
        $Doi = $ACLi
        Do {
            $ACLArguments = New-Object System.Security.AccessControl.FileSystemAccessRule($NewACLs[$Doi].IdentityReference, $NewACLs[$Doi].FileSystemRights, $NewACLs[$Doi].InheritanceFlags, $NewACLs[$Doi].PropagationFlags, $NewACLs[$Doi].AccessControlType)
            $EmptyAcl.AddAccessRule($ACLArguments)
            $Doi ++
            $Success +=, (New-Object -TypeName PSObject -Property @{
                ACLIndex = $ACLi
                DoIndex = $Doi
                Path = $NewACLs[$ACLi].Path
                Owner = $NewACLs[$ACLi].Owner
                IdentityReference = $NewACLs[$ACLi].IdentityReference
                AccessControlType = $NewACLs[$ACLi].AccessControlType
                FileSystemRights = $NewACLs[$ACLi].FileSystemRights
                InheritanceFlags = $NewACLs[$ACLi].InheritanceFlags
                PropagationFlags = $NewACLs[$ACLi].PropagationFlags
            })
        } 
        Until (
            $NewACLs[$ACLi].Path -ne $NewACLs[$Doi].Path
        )

        $RemoveACL = Get-ACL -LiteralPath $NewACLs[$ACLi].Path
        $RemoveACL.SetAccessRuleProtection($True, $False) #$True = isProtected (Disable Inheritance); $False = PreserveInheritance (Copy Existing Permissions)
        Set-Acl -Path $NewACLs[$ACLi].Path -ACLObject $RemoveACL
        $EmptyAcl.SetAccessRuleProtection($True, $False) #$True = isProtected (Disable Inheritance); $False = PreserveInheritance (Copy Existing Permissions)
        Set-Acl -path $NewACLs[$ACLi].Path -AclObject $EmptyAcl
        $ACLi = $Doi - 1
        
        $SuccessProperties = @('ACLIndex', 'DoIndex', 'Path', 'Owner', 'IdentityReference', 'AccessControlType', 'FileSystemRights', 'InheritanceFlags', 'PropagationFlags')
    }
    Catch {
        $null = $ACLArguments
        $Errors +=, (New-Object -TypeName PSObject -property @{
            Index = $ACLi
            Path = $NewACLs[$ACLi].Path
            Owner = $NewACLs[$ACLi].Owner
            IdentityReference = $NewACLs[$ACLi].IdentityReference
            AccessControlType = $NewACLs[$ACLi].AccessControlType
            FileSystemRights = $NewACLs[$ACLi].FileSystemRights
            InheritanceFlags = $NewACLs[$ACLi].InheritanceFlags
            PropagationFlags = $NewACLs[$ACLi].PropagationFlags
            Error = $_
        })
        $ErrorProperties = @('Index', 'Path', 'Owner', 'IdentityReference', 'AccessControlType', 'FileSystemRights', 'InheritanceFlags', 'PropagationFlags', 'Error')
    }
}
$Errors | Select-Object $ErrorProperties | Out-GridView
$Success | Select-Object $SuccessProperties | Out-GridView