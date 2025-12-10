Function Debug
{
    Param([Parameter(Mandatory=$false,Position=1)]
    $Variable)
    
    If ($Variable -eq $null)
    {
        $VariableDetails = "Empty Variable"
    }
    Else
    {
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c")
    {
        Return
    }
    Else
    {
        Exit 1
    }
}

Function QueryServers
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$false,Position=2)]
        [String] $Targets)

    If ($DomainWide -eq $True)
    {
        $WebServers = Get-Content "c:\temp\computers.txt"    
    }
    ElseIf ($Targets -ne "" -or $Targets -ne $null)
    {
        $WebServers = $Targets
    }
    
    $ProblemServers = @("")

    ForEach ($server in $WebServers)
    {
        
        $WMIValues1 = WMIQuery -Server $server -NameSpace "root\WebAdministration" -Class "ApplicationPool"
        If ($WMIValues1 -ne $null)
        {
            ForEach ($item in $WMIValues1)
            {
                $NewName = Strip-Name -Name $item
                
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\WebAdministration"
                $Output
            }
        }
        Else
        {
            $WMIValues2 = WMIQuery -Server $server -NameSpace "root\microsoftiisv2" -Class "IIsApplicationPoolSetting"
            If ($WMIValues2 -ne $null)
            {
                ForEach ($item in $WMIValues2)
                {
                    $NewName = Strip-Name -Name $item
                
                    $Output = New-Object PSObject
                    $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                    $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $NewName
                    $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                    $Output
                }
            }
            Else
            {
                $Output = New-Object PSObject
                $Output | Add-Member -MemberType NoteProperty -Name Server -Value $server
                $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value "No Value"
                $Output | Add-Member -MemberType NoteProperty -Name NameSpace -Value "root\microsoftiisv2"
                $Output
            }
        }
    }
}

Function Strip-Name
{
    Param([String] $Name)

    [String] $NewName = $item
    $NewName = $NewName.Remove(0, 7)
    $NewName = $NewName.Remove($NewName.Length - 1, 1)

    Return $NewName
}

Function WMIQuery
{
    Param(
        [String] $Server, `
        [String] $NameSpace, `
        [String] $Class)

   Try
    {
        $WMIValues = Get-WmiObject -ComputerName $Server -Namespace $NameSpace -Class $Class `
            -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | Select Name
    }
    Catch
    {
        $WMIValues = $null
        Return $WMIValues
    }
    Return $WMIValues
}

Clear-Host
QueryServers -DomainWide $true