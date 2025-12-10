Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $TargetServers, `
        [Parameter(Mandatory=$True,Position=3)]
        [Array] $Command, `
        [Parameter(Mandatory=$false,Position=4)]
        [String] $ReferenceFile)


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
        $VariableMembers = $Variable | Get-Member
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Variable Members" -ForegroundColor Yellow -NoNewline
    Write-Host "$VariableMembers" -ForegroundColor Red
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

Function Create-Credentials
{
    $User = "DOMAIN2\username"
    $Pass = ConvertTo-SecureString -String "YourPasswordHere" -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($user,$pass)
    Return $creds
}

Function Invoke-RemoteCommand
{
    Param(
        [String] $Server, `
        [Array] $Command)
    Try
    {
        $Credentials = Create-Credentials
        $Session = New-PSSession -ComputerName $Server -Credential $Credentials
        $Results = Invoke-Command -Session $Session -ArgumentList $Command -ScriptBlock {Param($PassedArguments) PowerShell.exe $PassedArguments} -ErrorAction Stop
        Return $Results
    }
    Catch
    {
        Return $null
    }
}

Function RunonDomain
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $TargetServers, `
        [Parameter(Mandatory=$True,Position=3)]
        [Array] $Command, `
        [Parameter(Mandatory=$false,Position=4)]
        [String] $ReferenceFile)

    If ($DomainWide -eq $True)
    {
        If ($ReferenceFile -ne $null -or $ReferenceFile -ne "")
        {
            $TargetServers = Get-Content "C:\temp\computers.txt"
        }
        Else
        {
            Try
            {
                $TargetServers = Get-Content $ReferenceFile -ErrorAction stop
            }
            Catch
            {
                Write-Host "Supplied Reference File - " -NoNewline
                Write-Host "$ReferenceFile" -ForegroundColor Yellow -NoNewline
                Write-Host " - Does not exist or is inaccessible"
                Write-Host "Reverting to default Reference file - " -NoNewline
                Write-Host "C:\Temp\Computers.TXT" -ForegroundColor Yellow
                $TargetServers = Get-Content "C:\temp\computers.txt"
            }
        }
    }
    Else
    {
        If ($TargetServers -eq "" -or $TargetServers -eq $null)
        {
            Write-Host "Domain Wide is set to False and no Target Servers are defined"
            exit 1
        }
    }    

    Write-Host " Total Targets: " -NoNewline
    Write-Host $TargetServers.Count -ForegroundColor Yellow

    [int] $x = 1

    $TargetServers = $TargetServers | Sort-Object        
    $FullResults
    ForEach ($Server in $TargetServers)
    {
        Write-Host "$x - Executing " -NoNewline
        Write-Host "$Command" -ForegroundColor Yellow -NoNewline
        Write-Host " on " -NoNewline
        Write-Host "$Server" -ForegroundColor Yellow -NoNewline 
        Write-Host " - " -NoNewline
        $Results = Invoke-RemoteCommand -Server $Server -Command $Command
        If ($Results -ne $null)
        {
            Write-Host "Complete" -ForegroundColor Green
            $FullResults += $Results
        }
        Else
        {
            Write-Host "Failed" -ForegroundColor Red
        }
        $x ++
    }
    
    $FullResults
}

Clear-Host
#RunonDomain -DomainWide $True -Command "C:\Windows\Get-IISSites.ps1"
RunonDomain -DomainWide $DomainWide -TargetServers $TargetServers -Command $Command -ReferenceFile $ReferenceFile