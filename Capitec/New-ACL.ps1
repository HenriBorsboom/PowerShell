Param (
    [Parameter(Mandatory=$true)]
    # Validate that the path specified actually exists
    [ValidateScript({Test-Path $_ -PathType Container})]
    [string]$FolderPath,

    [Parameter(Mandatory=$true)]
    # The security group that needs to be added
    [string]$SecurityGroup,

    [Parameter(Mandatory=$true)]
    # The permissions that should be added. For simplicity, the only options are Read or Write which are adjusted to the correct underlying permissions
    [ValidateSet("Read", "Write")]
    [string]$Permissions
)
# Exit the script on any error
$ErrorActionPreference = 'Stop'

# Clear the screen
Clear-Host
Try {
    # Get the current assigned permissions and save it as an ACL variable
    $Acl = Get-Acl -Path $FolderPath
    # Evaluate the assigned permissions and adjust accordingly
    Switch ($Permissions) {
        "Read" {
            # Adjust the Read permissions to Read, Read And Execute, and List Folder Contents permissions
            $NewPermissions = "ReadAndExecute"
        }
        "Write" {
            # Adjust the Write permissions to Modify, Read, Read And Execute, List Contents, and Write permissions
            $NewPermissions = "Modify"
        }
    }
    # Create the new permission with inheritance enabled
    $AccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($SecurityGroup, $NewPermissions, "ContainerInherit, ObjectInherit", "None", "Allow") 
    # Add the new permission to the currently assigned permissions
    $Acl.AddAccessRule($AccessRule)
    # Apply the new permissions to the folder
    Set-Acl -Path $FolderPath -AclObject $Acl
    # Confirm the permissions have been applied
    (Get-ACL -Path $FolderPath).Access | Format-Table IdentityReference,FileSystemRights,AccessControlType,IsInherited,InheritanceFlags -AutoSize
}
Catch {
    Write-Error -Message "An error occurred: $($_.Exception.Message)"
}