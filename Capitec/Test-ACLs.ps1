$Source = ('C:\temp1\Henri\2023-07-28 13-37-59__C__Temp2_Full_ACL.csv')
$NewACLs = Get-Content $Source | ConvertFrom-Csv
$FolderPath = 'C:\Temp2'
    $Acl = Get-Acl -Path $FolderPath
    # Remove non-inherited permissions
    ForEach ($Ace In $Acl.Access) {
        If ($Ace.IsInherited -eq $false) {
            $Acl.RemoveAccessRuleSpecific($Ace)
        }
    }
    # Enable inheritance
    $Acl.SetAccessRuleProtection($True, $false)
    # Assign Modify to new group
    Foreach ($NewACL in $NewACLs) {
        $Ace = New-Object System.Security.AccessControl.FileSystemAccessRule($NewACL.IdentityReference, $NewACL.FileSystemRights, $NewACL.InheritanceFlags, $NewACL.PropagationFlags, $NewACL.AccessControlType)
        $Acl.AddAccessRule($Ace)
    }

    Set-Acl -Path $FolderPath -ACLObject $Acl
