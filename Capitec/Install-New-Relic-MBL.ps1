# Create Local Temp Directory
Write-Host "Checking for Temp Folder"
If (!(Test-Path 'c:\temp')) {
    Write-Host "Creating Temp Folder"
    md 'C:\Temp'
}
Else {
    Write-Host "Exists"
}

# Copy files to local temp directory
Write-Host "Copying files to local"
Copy '\\PRMADPRD01\c$\Temp\New Relic Install\*.*' 'C:\Temp' -Verbose
# Test connection to Proxy

Try {
    Write-Host "Testing Connection to Proxy"
    Test-NetConnection -ComputerName prxprd.mercantile.co.za -port 8080 -ErrorAction Stop
    # Install Agent
    Write-Host "Installing Agent"
    Start-Process 'msiexec.exe' -ArgumentList ('/qn', '/i', "c:\temp\newrelic-infra.msi", 'GENERATE_CONFIG=true', 'LICENSE_KEY="eu01xx4d5959973da62e9959bc04c3c30a8fNRAL"', 'PROXY=http://prxprd.mercantile.co.za:8080')
    # Start Service
    While ($null -eq (get-service newrelic-infra -ErrorAction SilentlyContinue)) {
        Write-host "waiting for service"
        Sleep 1
    }
    Write-host "Starting Service"
    Start-Service newrelic-infra
    Write-host "Deleting files"
    del 'c:\temp\New Text Document.txt'
    del 'c:\temp\New+Relic+Deployment+Actions.docx'
    del 'c:\temp\newrelic-infra.msi'
    del 'c:\temp\newrelic-infra-386.msi'
}
Catch {
    Write-host $_ -ForegroundColor Red
}
