Function Get-DomainComputers {
    Import-Module ActiveDirectory
    $Servers = Get-ADComputer -Filter {Name -notlike "NRAZUREVMHC*" -and Name -notlike "NRAZUREDBSC*" -and Name -notLike "NRAZUREDBSQ*" -and Enabled -eq $true -and Name -like "NRAZURE*"}
    $Servers | Sort Name

    Return $Servers    
}
