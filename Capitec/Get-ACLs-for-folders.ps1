Function Get-ACLSubFolders {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Folder
    )

    $Folders = Get-ChildItem $Folder -Directory
    $Details = @()
    For ($i = 0; $i -lt $Folders.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Folders.Count.ToString() + ' Processing ' + $Folders[$i].FullName)
        $ACLs = Get-Acl $Folders[$i].FullName | select-object -ExpandProperty Access
    
        # Split the string into an array based on newlines
        #$lines = $ACLs -split "`n"

        # Process each line
        foreach ($ACL in $ACLs) {
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Path = $Folders[$i].FullName
                User = $ACL.IdentityReference.Value
                Access = $ACL.FileSystemRights
            })
        }
    }
    Return $Details
}
Function Get-ACLFolder {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Folder
    )

    $ACLs = Get-Acl $Folder | select-object -ExpandProperty Access
    
    # Split the string into an array based on newlines
    #$lines = $ACLs -split "`n"

    # Process each line
    foreach ($ACL in $ACLs) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Path = $Folder
            User = $ACL.IdentityReference.Value
            Access = $ACL.FileSystemRights
        })
    }
    Return $Details
}
$Folders = @()
$Folders += ,('E:\ABility Backup')
$Folders += ,('E:\BoardReports')
$Folders += ,('E:\CACheck')
$Folders += ,('E:\CreditPricing')
$Folders += ,('E:\FILESHARE TEST GROUP')
$Folders += ,('E:\FILESHARE TEST USERS')
$Folders += ,('E:\MercantileLMS')
$Folders += ,('E:\Neessus Backups')
$Folders += ,('E:\OpsCentralisation')
$Folders += ,('E:\Oracle')
$Folders += ,('E:\WSOShare')
$Folders += ,('G:\TRV-SCANNING')
$Folders += ,('J:\')
$Folders += ,('J:\spool_files\TEST\W-region')
$Folders += ,('J:\spool_files\TEST\XYZ-region')
$Folders += ,('R:\')


$Details = @()

ForEach ($Folder in $Folders) {
    $Values = Get-ACLFolder $Folder
    ForEach ($Value in $Values) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Path = $Value.Path
            User = $Value.User
            Access = $Value.Access
        })
    }    
}
$SharedDetails = Get-ACLSubFolders -Folder 'E:\Shared'
ForEach ($Value in $SharedDetails) {
    $Details += ,(New-Object -TypeName PSObject -Property @{
        Path = $Value.Path
        User = $Value.User
        Access = $Value.Access
    })
}
$Details | Out-GridView