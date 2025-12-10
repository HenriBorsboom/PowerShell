Function Install-NewRelic {
    Write-Host "Checking if service already installed - " -NoNewline
    If (!($Null -eq (Get-Service newrelic-infra -ErrorAction SilentlyContinue))) {
        Write-Host "Service already installed" -ForegroundColor Yellow
        Return
    }
    Write-Host "Checking Operating System version - " -NoNewline
    $OS = (Get-WmiObject -Class Win32_OperatingSystem -Property Caption).Caption
    Write-Host $OS -ForegroundColor Yellow
    If ($OS -like '*2008 R2*') {
        Write-Host "Running Ping Test to Proxy - " -NoNewline
        Try {
            Test-Connection -ComputerName prxprd.mercantile.co.za -Count 2 -ErrorAction Stop -WarningAction Stop | Out-Null
            Write-Host "Proxy Online" -ForegroundColor Green
            Test-Connection -ComputerName fsprd01.mercantile.co.za -Count 2 -ErrorAction Stop -WarningAction Stop | Out-Null
            Write-Host "File Server Online" -ForegroundColor Green
        }
        Catch {
            Write-Host "Proxy unavailable" -ForegroundColor Red
            Write-Host "File Server unavailable" -ForegroundColor Red
            Return
        }
    } ElseIf ($OS -like '*201*') {
        Write-Host "Running Connection Test to Proxy - " -NoNewline
        Try {
            Test-NetConnection -ComputerName prxprd.mercantile.co.za -port 8080 -ErrorAction Stop -WarningAction Stop | Out-Null
            Write-Host "Proxy Online" -ForegroundColor Green
            Test-NetConnection -ComputerName fsprd01.mercantile.co.za -port 445 -ErrorAction Stop -WarningAction Stop | Out-Null
            Write-Host "File Server Online" -ForegroundColor Green
        }
        Catch {
            Write-Host "Proxy unavailable" -ForegroundColor Red
            Write-Host "File Server unavailable" -ForegroundColor Red
            Return
        }
    } Else {
        Write-Host "OS is unsupported" -ForegroundColor Red
        Return
    }
    Write-Host "Checking if local Temp folder exists - " -NoNewline
    If (!(Test-Path 'c:\temp')) {
        Write-Host "Creating Temp Folder and will be removed later" -ForegroundColor Yellow
        md 'C:\Temp' | Out-Null
        $TempCreated = $True
    } Else {
        Write-Host "Already exists" -ForegroundColor Green
    }

    Try {
        Write-Host "Copying files to local"
        Copy '\\FSPRD01\Server_Support\New Relic Install\*.*' 'C:\Temp' -Verbose -ErrorAction Stop
    }  Catch {
        Write-Host "Unable to copy files from FSPRD01. $_" -ForegroundColor Red
        Return
    }

    Try {
        Write-Host "Installing Agent"
        Start-Process 'MSIEXEC.exe' -ArgumentList ('/qn', '/i', 'C:\temp\newrelic-infra.msi', 'GENERATE_CONFIG=true', 'LICENSE_KEY="eu01xx4d5959973da62e9959bc04c3c30a8fNRAL"', 'PROXY=http://prxprd.mercantile.co.za:8080') -Wait
        While ($null -eq (Get-Service newrelic-infra -ErrorAction SilentlyContinue)) {
            Write-Host "Waiting for service to be installed" -ForegroundColor Cyan
            Sleep 1
        }
        Write-Host "Starting Service"
        Start-Service newrelic-infra
        Write-Host "Deleting Files"
        Del 'C:\temp\New Text Document.txt'
        del 'C:\temp\New+Relic+Deployment+Actions.docx'
        del 'C:\temp\newrelic-infra.msi'
        del 'C:\temp\newrelic-infra-386.msi'
        If ($TempCreated -eq $True) {
            Write-Host "Removing Temp folder created"
            Del c:\temp
        }
    } Catch {
        Write-Host $_ -ForegroundColor Red
        Return
    }
}

Install-NewRelic