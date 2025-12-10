# AD Functions

Function ADUser-MemberOf {
    Import-Module ActiveDirectory
    $ServiceAccounts = Get-ADUser -Filter 'Name -like "hvi-*"' | select name

    ForEach ($ADUser in $ServiceAccounts) {
        [String] $NewUser = $ADUser
        $NewUser = $NewUser.Remove(0, 7)
        $NewUser = $NewUser.Remove(($NewUser.Length) -1, 1)

        Write-Host $NewUser
        Get-ADUser $NewUser -Properties * | select -ExpandProperty MemberOf
        Write-host ""
    }
}

Function Get-ADUsers {
    Param([Parameter(Mandatory=$true,Position=1)]
        [String] $UserProfilePath)

    Import-Module ActiveDirectory
    $UserList = Get-ChildItem -Path $UserProfilePath | Where-Object {$_.Mode -match "d"} | Select Name

    ForEach ($User in $UserList) {
        $UserName = Strip-Name -Name $User

        Try {
            Get-ADUser $UserName -Properties * | Select SamAccountName,Name,Enabled,AccountExpirationDate,LastLogonDate
        }
        Catch {
            Write-Host "Could not get details for $UserName" -ForegroundColor Red
        }
    }
}

Function Test-ADCredentials {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $PowerShellCredentialType, `
        [Parameter(Mandatory=$False,Position=2)]
        [System.Management.Automation.PSCredential] $PowerShellCredentials, `
        [Parameter(Mandatory=$False,Position=3)]
        [String] $Username, `
        [Parameter(Mandatory=$False,Position=4)]
        [String] $Password)
    
    Write-Host "Testing " -NoNewline
    Write-Host $TestingCredentials.UserName -NoNewline -ForegroundColor Yellow
    Write-Host " - " -NoNewline
    
    If ($PowerShellCredentialType -eq $False) {
        If ($Username -ne $null -or $Username -ne "") {
            If ($Password -ne $null -or $Password -ne "") {
                $CreateUsername = $Username
                $CreatePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
                $PowerShellCredentials = New-Object System.Management.Automation.PSCredential($CreateUsername,$CreatePassword)
            }
            Else {
                Write-Host "Username supplied but password is blank" -ForegroundColor Red
            }
        }
        Else {
            Write-Host "Powershell credential was set to false and username is blank. Please try again"
        }
    }

    Try {
        Start-Process -FilePath cmd.exe /c -Credential ($PowerShellCredentials) -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}
