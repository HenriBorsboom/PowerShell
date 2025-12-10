Function Return-Creds {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Username, `
        [Parameter(Mandatory=$true,Position=2)]
        [String] $Password)

    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Credentials = New-Object PSCredential($Username,$SecurePassword) 
    Return $Credentials
}

Function Process-Creds {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [PSCredential] $Credentials)

    #Try {
        $Process = Start-Process notepad -Credential $Credentials -LoadUserProfile -NoNewWindow -ErrorAction Stop
        #Stop-Process -Id $Process.Id
    #}
    #Catch {
    #    Write-Host $_
        #Break
    #}
}

Function Remove-Proxy {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $Server, `
        [Parameter(Mandatory=$true,Position=1)]
        [PSCredential] $Credentials)

    Invoke-Command -ComputerName $Server -Credential $Credentials -ScriptBlock {
        $RegistryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
        $Name = "ProxyEnable"
        $Value = "1"
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
        Write-Host $env:COMPUTERNAME "-" $env:USERNAME "-" $Name -ForegroundColor Green
        
        $Name = "ProxyOverride"
        $Value = ""
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType STRING -Force | Out-Null
        Write-Host $env:COMPUTERNAME "-" $env:USERNAME "-" $Name -ForegroundColor Green
        
        $Name = "ProxyServer"
        $Value = ""
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType STRING -Force | Out-Null
        Write-Host $env:COMPUTERNAME "-" $env:USERNAME "-" $Name -ForegroundColor Green
        
        $Name = "ProxyBypass"
        $Value = "0"
        New-ItemProperty -Path $RegistryPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null
        Write-Host $env:COMPUTERNAME "-" $env:USERNAME "-" $Name -ForegroundColor Green
    }
}

#$Creds = Return-Creds -Username "Domain2\" -Password ""; Process-Creds -Credentials $Creds

#$Username = "DOMAIN2\svc-web-admin"; $Password = "Hv!W@pw3bP@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
##$Username = "DOMAIN2\svc-web-fso; $Password = Hv!W@pw3bFS0P@ssword"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
$Username = "DOMAIN2\svc-web-fsu; $Password = Hv!W@pw3bFSuP@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
#$Username = "DOMAIN2\svc-web-csu; $Password = Hv!W@pw3bCs#P@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
#$Username = "DOMAIN2\svc-web-mn; $Password = Hv!W@pw3bMn@Password"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
#$Username = "DOMAIN2\svc-web-pb; $Password = Hv!W@pw3bPbP@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
#$Username = "DOMAIN2\svc-web-fe; $Password = Hv!W@pw3bF3P@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
#$Username = "DOMAIN2\svc-web-ww; $Password = Hv!W@pw3bWwP@ssw0rd"; $Creds = Return-Creds -Username $Username -Password $Password; Process-Creds -Credentials $Creds
