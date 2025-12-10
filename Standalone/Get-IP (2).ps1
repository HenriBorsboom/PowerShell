
Function Get-IP {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Destination)

    Try {
        $Result = Test-Connection -ComputerName $Destination -Count 1 -ErrorAction Stop
        Write-Host $Destination "-" $Result.IPV4Address
    }
    Catch {
        Write-Host $Destination "- Failed" -ForegroundColor Red
    }
}

$ADServers = Get-ADComputer `
    -Filter {Name -like 'NRAZURE*'}
    #-Filter {`
    #Name -notlike 'NRAZUREVMHC*' -and `
    #Name -notlike 'NRAZUREAPPC*' -and `
    #Name -notlike 'NRAZUREDBSC*' -and `
    #Name -notlike 'NRAZUREDBSQ*' -and `
    #Name -like 'NRAZURE*'}

Write-Host "Total Servers:" $ADServers.Count
$x = 1
ForEach ($Server in $ADServers.Name) {
    Try {
        Write-Host "$x - " -NoNewline
            Get-IP -Destination $Server
    }
    Catch {
        Write-Host "$x - Cannot obtain IP" -ForegroundColor Red
    }
    $x ++
}