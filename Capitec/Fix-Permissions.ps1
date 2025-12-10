Clear-Host
$Folders = Get-ChildItem 'E:\Shared\BPMAD' -Directory
For ($i = 0; $i -lt $Folders.Count; $i ++) {
    Write-Host ($folderPath) -ForegroundColor Green
    $folderPath = $Folders[$i].FullName
    # Take ownership of the folder and subfolders
    $acl = Get-Acl $folderPath
    $administrators = New-Object System.Security.Principal.NTAccount("BUILTIN\Administrators")
    $acl.SetOwner($administrators)
    Set-Acl -Path $folderPath -AclObject $acl -Verbose

    # Recursively set ownership for subfolders
    Get-ChildItem -Path $folderPath -Recurse -Directory | ForEach-Object {
        $subFolderPath = $_.FullName
        $subAcl = Get-Acl -Path $subFolderPath
        $subAcl.SetOwner($administrators)
        Set-Acl -Path $subFolderPath -AclObject $subAcl -Verbose
    }

    Write-Host "Ownership has been granted to the Administrators group for $folderPath and its subfolders."

    # List of users to grant modify permissions
    $users = @(
        "CAPITECBANK\BPMAD_RO",
        "CAPITECBANK\BPMAD_RW Allow",
        "CAPITECBANK\Domain Admins",
        "CAPITECBANK\CP352172"
    )

    # Grant modify permissions to each user
    foreach ($user in $users) {
        $acl = Get-Acl $folderPath
        if ($user -eq "capitecbank\domain admins") {
            $permission = $user, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        }
        Else {
            $permission = $user, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow"
        }
    
        $accessRule = New-Object -TypeName System.Security.AccessControl.FileSystemAccessRule -ArgumentList $permission
        $acl.SetAccessRule($accessRule)
        Set-Acl $folderPath $acl
        Write-Host "Granted modify permission to $user"
    }
}