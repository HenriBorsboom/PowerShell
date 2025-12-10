Param (
    [Parameter (Mandatory=$True, Position = 1)]
    [String] $Path
)
Function Get-ACLUsers { 
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Path,
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $Grid = $False
    )
        
    $ACLOwners = Get-Acl (Get-ChildItem -Recurse -force $Path).FullName | Select-Object -Unique Owner
    $GroupMembers = (Get-ACL (Get-ChildItem $Path)).Access.IdentityReference
    $FolderOwner = (Get-ACL $Path).Owner.ToString().Replace('CAPITECBANK\','')
    If (($GroupMembers -like '*icapitec*').Count -gt 0) {
        $LockedToGroup = ($GroupMembers -like '*icapitec*') | Select-Object -Unique
    }
    Else {
        $LockedToGroup = $False
    }
    $Owners = @()
    ForEach ($ACLOwner in $ACLOwners) {
        $Owners += ,($ACLOwner.Owner.ToString().Replace('CAPITECBANK\',''))
    }
    Return $Owners, $LockedToGroup, $FolderOwner
}
Function Get-User {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $User, 
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $Manager
    )
    $Details = @()
    Try {
        #Write-Host ('Attempt 1: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            #Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            If ($Manager -eq $False) {
                    $ADUser = Get-ADUser $User -Properties SamAccountName, Name, Enabled, Manager -ErrorAction Stop | Select-Object SamAccountName, Name, Enabled, Manager
            }
            Else {
                $ADUser = Get-ADUser -Filter {Name -like $User} -Properties SamAccountName, Name, Enabled, Manager -ErrorAction Stop | Select-Object SamAccountName, Name, Enabled, Manager
            }

            $ADManager = (($ADUser.Manager -split '=')[1] -split ',')[0]
            $Details += ,(New-Object -Type PSObject -Property @{
                SamAccountName = $ADuser.SamAccountName
                Name = $ADUser.Name
                Enabled = $ADUser.Enabled
                Manager = $ADManager
            }) | Select-Object SamAccountName, Name, Enabled, Manager
        }
    }
    Catch {
        #Write-Host ('Attempt 2: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            #Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            $ADUser = Get-ADUser $User -Properties SamAccountName, Name, Enabled, Manager -ErrorAction Stop | Select-Object SamAccountName, Name, Enabled, Manager
            $ADManager = (($ADUser.Manager -split '=')[1] -split ',')[0]
            $Details += ,(New-Object -Type PSObject -Property @{
                SamAccountName = $ADuser.SamAccountName
                Name = $ADUser.Name
                Enabled = $ADUser.Enabled
                Manager = $ADManager
            }) | Select-Object SamAccountName, Name, Enabled, Manager
        }
    }
    Return $Details
}
$ActiveOwners = @()

Write-Host ('|- Getting Users for ' + $Path + ' - ') -NoNewline
$ACLs = Get-ACLUsers -Path $Path
Write-Host ($Users.Count.ToString() + ' found')
[String[]] $Users = $ACLs[0]
Write-Host ('Locked to group for ' + $Path + ' - ' + $ACLs[1])
For ($i = 0; $i -lt $Users.Count; $i ++) {
    If (!($Users[$i] -eq 'BUILTIN\Administrators')) {
        #Write-Host (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing User ' + $Users[$i])
        $UserDetails = Get-User $Users[$i]
        $ActiveOwners += ,(New-Object -TypeName PSObject -Property @{
            SAMAccountName = $Userdetails.SamAccountName
            Name = $Userdetails.Name
            Enabled = $Userdetails.Enabled
            Manager = $UserDetails.Manager
            SeniorManager = ''
            Index = $i
            Folder = ('M:\Company Shared Files\ICapitec\' + $Path)
            LockDownGroup = $ACLs[1]
            FolderOwnerSamAccount = $ACLs[2]
            FolderOwnerName = ''
            FolderOwnerEnabled = ''
            FolderOwnerManager = ''
            FolderOwnerSeniorManager = ''
        })
        $FolderUserDetails = Get-User $ACLs[2]
        $ActiveOwners[[array]::IndexOf($ActiveOwners.Index,$i)].FolderOwnerName = $FolderUserDetails.Name
        $ActiveOwners[[array]::IndexOf($ActiveOwners.Index,$i)].FolderOwnerEnabled = $FolderUserDetails.Enabled
        $ActiveOwners[[array]::IndexOf($ActiveOwners.Index,$i)].FolderOwnerManager = $FolderUserDetails.Manager
        If ($FolderUserDetails.Manager -ne '') {
            $FolderManagerDetails = Get-User $FolderUserDetails.Manager -Manager:$True
            $ActiveOwners[[array]::IndexOf($ActiveOwners.Index,$i)].SeniorManager = $FolderManagerDetails.Manager
        }

        If ($UserDetails.Manager -ne '') {
            $ManagerDetails = Get-User $UserDetails.Manager -Manager:$True
            $ActiveOwners[[array]::IndexOf($ActiveOwners.Index,$i)].SeniorManager = $ManagerDetails.Manager
        }
        $FolderUserDetails = $null
        $ManagerDetails = $null
        $UserDetails = $null
    }
}

$Properties = @()
$Properties += ,('Folder')
$Properties += ,('LockDownGroup')
$Properties += ,('FolderOwnerSamAccount')
$Properties += ,('FolderOwnerName')
$Properties += ,('FolderOwnerEnabled')
$Properties += ,('FolderOwnerManager')
$Properties += ,('FolderOwnerSeniorManager')
$Properties += ,('SAMAccountName')
$Properties += ,('Name')
$Properties += ,('Enabled')
$Properties += ,('Manager')
$Properties += ,('SeniorManager')
$Properties += ,('Index')

Return $ActiveOwners
