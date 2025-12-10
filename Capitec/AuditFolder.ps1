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
    Return $Owners, $LockedToGroup
}
Function Get-User {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $User
    )
    $Details = @()
    Try {
        Write-Host ('Attempt 1: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            $Details += ,(Get-ADUser $User -Properties Name, Enabled, Manager -ErrorAction Stop | Select-Object Name, Enabled, Manager)
        }
    }
    Catch {
        Write-Host ('Attempt 2: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            $Details += ,(Get-ADUser $User -Properties Name, Enabled, Manager -ErrorAction Stop | Select-Object Name, Enabled, Manager)
        }
    }
    Return $Details
}
Function Test-User {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $User
    )
    $Details = @()
    Try {
        Write-Host ('Attempt 1: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            $Details += ,(Get-ADUser -Filter {Name -like $User} -Properties Name, Enabled, Manager -ErrorAction Stop | Select-Object Name, Enabled, Manager)
        }
    }
    Catch {
        Write-Host ('Attempt 2: Getting details for ' + $User)
        If ($User -eq 'BUILTIN\Administrators') {
            Write-Host ('Skipping BUILTIN\Administrators')
        }
        Else {
            $Details += ,(Get-ADUser -Filter {Name -like $User} -Properties Name, Enabled, Manager -ErrorAction Stop | Select-Object Name, Enabled, Manager)
        }
    }
    Return $Details
}
Write-Host ('Checking if path name is active')
$UserStatus = Test-User $Path
$ActiveOwners = @()
If ($UserStatus.Enabled -eq $True) {
    Write-Host ('Path Name is active account')
    $ActiveOwners = $UserStatus.Name
}
Else {
    Write-Host ('Getting Users for ' + $Path)
    $ACLs = Get-ACLUsers -Path $Path
    [String[]] $Users = $ACLs[0]
    Write-Host ('Locked to group for ' + $Path + ' - ' + $ACLs[1])
    Write-Host ($Users.Count.ToString() + ' found')
    For ($i = 0; $i -lt $Users.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + $Users.Count.ToString() + ' - Processing User ' + $Users[$i])
        $UserDetails = Get-User $Users[$i]
        If ($UserDetails.Enabled -eq $False) {
            Write-Host ('User Account disabled (' + $UserDetails.Name + '). Getting status of manager account')
            If ($Null -ne $UserDetails.Manager) {
                $ManagerDetails = Get-User $UserDetails.Manager
                If ($ManagerDetails.Enabled -eq $False) {
                    Write-Host ('Manager Account disabled (' + $ManagerDetails.Name + '). Getting status of senior manager account')
                    If ($Null -ne $ManagerDetails.Manager) {
                        $SeniorManagerDetails = Get-User $ManagerDetails.Manager
                        If ($SeniorManagerDetails.Enabled -eq $False) {
                            Write-Host ('Senior Manager Account disabled (' + $SeniorManagerDetails.Name + ')')
                        }
                        Else {
                            $ActiveOwners += ,($SeniorManagerDetails.Name)
                        }
                    }
                    Else {
                        Write-Host ('No Manager details returned')
                    }
                }
                Else {
                    $ActiveOwners += ,($ManagerDetails.Name)
                }
            }
            Else {
                Write-Host ('No Manager details returned')
            }
        }
        Else {
            $ActiveOwners += ,($UserDetails.Name)
        }
    }
    
}
$ActiveOwners | Select-Object -Unique
