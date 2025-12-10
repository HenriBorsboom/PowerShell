$ErrorActionPreference = 'Stop'
Function Get-Servers {
    $OUs = @()
    $OUs += ,('OU=Infrastructure-PRD,OU=Custom,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Custom,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Servers,DC=capitecbank,DC=fin,DC=sky')
    $OUs += ,('OU=PROD,OU=Standard,OU=Servers,DC=capitecbank,DC=fin,DC=sky')

    $Servers = @()
    For ($OUi = 0; $OUi -lt $OUs.Count; $OUi ++) {
        $LogonDateAllowed = (Get-Date).AddMonths(-1)
        Write-Host (($OUi + 1).ToString() + '/' + $OUs.Count.ToString() + ' Processing ' + $OUs[$OUi] + ' - ') -NoNewline
        $OUServers = (Get-ADComputer -SearchBase $OUs[$OUi] -Filter {Name -like '*' -and OperatingSystem -like '*server*' -and Enabled -eq $True -and LastLogonDate -gt $LogonDateAllowed } -Properties Description, OperatingSystem).Name
        ForEach ($Server in $OUServers) {
            $Servers += ,($Server)
        }
        Write-Host " Complete" -ForegroundColor Green
    }
    Return $Servers
}
Function Set-ParseOutput {
    Param (
        $Output
    )
    # Parse the output
    $lines = $output -split "`n"

    # Define sections
    $appliedGPOs = @()
    $filteredGPOs = @()
    $securityGroups = @()

    # Flag to determine current section
    $currentSection = ""

    foreach ($line in $lines) {
        if ($line -match "Applied Group Policy Objects") {
            $currentSection = "Applied"
            continue
        }
        elseif ($line -match "The following GPOs were not applied because they were filtered out") {
            $currentSection = "Filtered"
            continue
        }
        elseif ($line -match "The computer is a part of the following security groups") {
            $currentSection = "SecurityGroups"
            continue
        }

        # Process lines based on the current section
        switch ($currentSection) {
            "Applied" {
                if ($line.Trim() -ne "") {
                    $appliedGPOs += $line.Trim()
                }
            }
            "Filtered" {
                if ($line.Trim() -match "Filtering:") {
                    $filteredGPOs += $line.Trim()
                }
                elseif ($line.Trim() -ne "") {
                    $filteredGPOs += $line.Trim() + " (Filtered)"
                }
            }
            "SecurityGroups" {
                if ($line.Trim() -ne "") {
                    $securityGroups += $line.Trim()
                }
            }
        }
    }

    # Create a table for applied GPOs
    $AppliedGPOs = $appliedGPOs | ForEach-Object { [PSCustomObject]@{ AppliedGPO = $_ } }
    $ReturnAppliedGPOs = $appliedGPOs | Where-Object AppliedGPO -like '*wsus*'
    # Create a table for filtered GPOs
    $FilteredGPOs = $filteredGPOs | ForEach-Object { [PSCustomObject]@{ FilteredGPO = $_ } }
    $ReturnFilteredGPOs = $filteredGPOs | Where-Object FilteredGPO -like '*wsus*'
    # Create a table for security groups
    #$securityGroups | ForEach-Object { [PSCustomObject]@{ Group = $_ } }
    Return $ReturnAppliedGPOs, $ReturnFilteredGPOs
}
#$Servers = Get-Servers

$Details = @()
For ($i = 0; $i -lt $Servers.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Servers.Count.ToString() + ' - Processing ' + $Servers[$i])
    Try {
        If (Test-Connection $Servers[$i] -Count 1 -Quiet) {
            Try {
                Write-Host "|- Running GPUpdate"
                $GPUpdate = Invoke-Command -ComputerName $Servers[$i] -ScriptBlock {GPUpdate /Force}
                Write-Host "|- Getting GPResults"
                $Output = gpresult /s $Servers[$i] /scope computer /r
                $ParsedReturn = Set-ParseOutput $Output
                Write-Host ("|- Applied Updates: " + ($ParsedReturn.AppliedGPO) -join "; ")
                Write-host ("|- Filtered Updates: " + ($ParsedReturn.FilteredGPO) -join "; ")
            }
            Catch {
                Write-Host "|- GPUpdate Failed" -ForegroundColor Yellow
                $GPUpdate = $_
                Write-Host "|- Getting GPResults"
                Try {
                    #$Output = gpresult /s $Servers[$i] /scope computer /r
                    Invoke-Command -Computer $Servers[$i] -ScriptBlock {gpresult /scope computer /r} | Out-Null
                    $Output = gpresult /s $Servers[$i] /scope computer /r
                    $ParsedReturn = Set-ParseOutput $Output
                }
                Catch {
                    $ParsedReturn = New-Object -TypeName PSObject -Property @{
                        AppliedGPO = "Could not enumerate"
                        FilteredGPO = "Could not enumerate"
                    }
                }
                Write-Host ("|-- Applied Updates: " + ($ParsedReturn.AppliedGPO) -join "; ")
                Write-host ("|-- Filtered Updates: " + ($ParsedReturn.FilteredGPO) -join "; ")
            }
            Finally {
                $Details += ,(New-Object -TypeName PSObject -Property @{
                    Server = $Servers[$i]
                    GPUpdate = $GPUpdate
                    AppliedGPOs = $ParsedReturn.AppliedGPO
                    FilteredGPOs = $ParsedReturn.FilteredGPO
                })
            }
        }
        Else {
            Write-Host "|- Offline" -ForegroundColor Cyan
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Server = $Servers[$i]
                GPUpdate = 'Offline'
                AppliedGPOs = 'Offline'
                FilteredGPOs = 'Offline'
            })
        }
        
        #Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Servers[$i]
            GPUpdate = $_
            AppliedGPOs = $_
            FilteredGPOs = $_
        })
        Write-Host $_ -ForegroundColor Red
    }
}
$Details | Select-Object Server, AppliedGPOs, FilteredGPos, GPUpdate | Out-GridView