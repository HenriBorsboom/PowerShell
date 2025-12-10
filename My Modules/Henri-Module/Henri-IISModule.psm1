# IIS Functions

Function Get-IISSites {
    [Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

    $sm = New-Object Microsoft.Web.Administration.ServerManager

    ForEach ($site in $sm.Sites) {
        $root = $site.Applications | where { $_.Path -eq "/" }
    
        $Output = New-Object PSObject
        $Output | Add-Member -MemberType NoteProperty -Name SiteName -Value $Site.Name
        $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $root.ApplicationPoolName
        $Output | Add-Member -MemberType NoteProperty -Name ServerName -Value $env:COMPUTERNAME
        $Output
    }
}

Function List-InetPubWebServers {
    $Web = @(
            "NRAZUREWEB101", `
            "NRAZUREWEB102", `
            "NRAZUREWEB103", `
            "NRAZUREWEB104", `
            "NRAZUREWEB105", `
            "NRAZUREWEB106", `
            "NRAZUREWEB107", `
            "NRAZUREWEB108")

    ForEach ($Server in $Web) {
        Write-Host "Processing $Server - " -NoNewline
        $Path = "\\" + $Server + "\C$\InetPub"
        $Results = Ls $Path -Recurse | Where-Object {$_.Mode -match "d"} | Select Name
        ForEach ($Item in $Results) {
            [String] $OutputItem = $Item
            $OutputItem = $OutputItem.Remove(0, 7)
            $OutputItem = $OutputItem.Remove($OutputItem.Length -1, 1)

            $Output = New-Object PSObject
            $Output | Add-Member -MemberType NoteProperty -Name Server -Value $Server
            $Output | Add-Member -MemberType NoteProperty -Name Item -Value $OutputItem
            $Output | Export-Csv Folders.csv -NoClobber -NoTypeInformation -Append -Force
        }
        
        Write-Host "Complete" -ForegroundColor Green
    }
}

Function QueryFor-WebServers {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$false,Position=2)]
        [String] $Targets)

    If ($DomainWide -eq $True) {
        $WebServers = Get-Content "c:\temp\computers.txt"
    }
    ElseIf ($Targets -ne "" -or $Targets -ne $null) {
        $WebServers = $Targets
    }
    
    $ProblemServers = @("")

    ForEach ($server in $WebServers) {
        $WMIValues1 = WMIQuery -Server $server -NameSpace "root\WebAdministration" -Class "ApplicationPool"
        If ($WMIValues1 -ne $null) {
            ForEach ($item in $WMIValues1) {
                $NewName = Strip-Name -Name $item
                
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\WebAdministration"
                $Output
            }
        }
        Else {
            $WMIValues2 = WMIQuery -Server $server -NameSpace "root\microsoftiisv2" -Class "IIsApplicationPoolSetting"
            If ($WMIValues2 -ne $null) {
                ForEach ($item in $WMIValues2) {
                    $NewName = Strip-Name -Name $item
                
                    $Output = New-Object PSObject
                    $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                    $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                    $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                    $Output
                }
            }
            Else {
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value "No Value"
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                $Output
            }
        }
    }
}
