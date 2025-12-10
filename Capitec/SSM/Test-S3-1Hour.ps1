$SleepSeconds = 2
$TestAmount = 360
$StartDate = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
$CSVOutFile = ('C:\Temp\' + $Env:COMPUTERNAME + '_' + (Get-Date).ToString('yyyy-MM-dd HH_mm_ss') + '.csv')

$Success = 0
$Failure = 0
"Server,ComputerName,RemoteAddress,TCPTestSucceeded,Timestamp" | Out-File $CSVOutFile -Encoding ascii -Force
For ($i = 0; $i -lt $TestAmount; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $TestAmount.ToString() + ' - Testing Connectivity for 1 hour. Start time: ' + $StartDate + ": ") -NoNewline
    $TimeStamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $Result = test-netconnection s3.af-south-1.amazonaws.com -port 443 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    
    If ($Result.TcpTestSucceeded -eq $True) {
        $Success ++
        Write-Host ("S3 :" + $Result.TcpTestSucceeded.ToString() + " - ") -ForegroundColor Green -NoNewline
    }
    Else {
        $Failure ++
        Write-Host ("S3 :" + $Result.TcpTestSucceeded.ToString() + " - ") -ForegroundColor Red -NoNewline
    }
    $env:Computername.ToString() + ',' + $Result.ComputerName.ToString() + ',' + $Result.RemoteAddress.ToString() + ',' + $Result.TcpTestSucceeded.ToString() + ',' + $TimeStamp | Out-File $CSVOutFile -Encoding ascii -Append
    $Result = test-netconnection s3.dualstack.af-south-1.amazonaws.com -port 443 -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    If ($Result.TcpTestSucceeded -eq $True) {
        $Success ++
        Write-Host ("Dualstack :" + $Result.TcpTestSucceeded.ToString() + " - ") -ForegroundColor Green -NoNewline
    }
    Else {
        $Failure ++
        Write-Host ("Dualstack :" + $Result.TcpTestSucceeded.ToString() + " - ") -ForegroundColor Red -NoNewline
    }
    $env:Computername.ToString() + ',' + $Result.ComputerName.ToString() + ',' + $Result.RemoteAddress.ToString() + ',' + $Result.TcpTestSucceeded.ToString() + ',' + $TimeStamp | Out-File $CSVOutFile -Encoding ascii -Append
    Write-Host ("Sleeping for " + $SleepSeconds.ToString() + " seconds")
    Write-Host ("Success: " + [Math]::Round((($Success / 2 / ($i + 1)) * 100), 2).ToString()) -ForegroundColor Green
    Write-Host ("Failure: " + [Math]::Round((($Failure /2 / ($i + 1)) * 100), 2).ToString()) -ForegroundColor Red
    Start-Sleep -Seconds $SleepSeconds
}