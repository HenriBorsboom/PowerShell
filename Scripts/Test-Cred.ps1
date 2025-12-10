Param(
    [Parameter(Mandatory=$True,Position=1)]
    [bool] $PowerShellCredentialType, `
    [Parameter(Mandatory=$False,Position=2)]
    [System.Management.Automation.PSCredential] $PowerShellCredentials, `
    [Parameter(Mandatory=$False,Position=3)]
    [String] $Username, `
    [Parameter(Mandatory=$False,Position=4)]
    [String] $Password)

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

Function Test
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [System.Management.Automation.PSCredential] $TestingCredentials)

    Write-Host "Testing " -NoNewline
    Write-Host $TestingCredentials.UserName -NoNewline -ForegroundColor Yellow
    Write-Host " - " -NoNewline
    
    Try
    {
        Start-Process -FilePath cmd.exe /c -Credential ($TestingCredentials) -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
    }
}
        
If ($PowerShellCredentialType -eq $True)
{
    Test -TestingCredentials $PowerShellCredentials
}
ElseIf ($PowerShellCredentialType -eq $False)
{
    
    If ($Username -ne $null -or $Username -ne "")
    {
        If ($Password -ne $null -or $Password -ne "")
        {
            $CreateUsername = $Username
            $CreatePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
            $CreateCredentials = New-Object System.Management.Automation.PSCredential($CreateUsername,$CreatePassword)
            Test -TestingCredentials $CreateCredentials
        }
        Else
        {
            Write-Host "Username supplied but password is blank" -ForegroundColor Red
        }
    }
    Else
    {
        Write-Host "Powershell credential was set to false and username is blank. Please try again"
    }
}