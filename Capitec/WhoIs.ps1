Param (
    [Parameter(Mandatory=$True, Position=1)]
    [String] $User, `
    [Parameter(Mandatory=$False, Position=2)]
    [Switch] $Search = $False
)

$Server = 'CBDC004.capitecbank.fin.sky'

Switch ($Search) {
    $True {
        $SearchUser = ('*' + $User + '*')
        Get-ADUser -Filter {Name -like $SearchUser} -Server $Server
    }
    $False {
        Get-ADUser $User -Server $Server
    }
}