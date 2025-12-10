$Server = 'SCCMPRD02.mercantile.co.za'

$Ports = @()
$Ports += ,(80)
$Ports += ,(443)
$Ports += ,(445)
$Ports += ,(8530)
$Ports += ,(8531)
$Ports += ,(10123)

Clear-Host

ForEach ($Port in $Ports) {
    Try {
        Write-Host "Trying Connection to $Server on $Port - " -NoNewline
        $Result = Test-NetConnection -Computername $Server -Port $Port -ErrorAction Stop
        Write-Host $Result.TcpTestSucceeded -ForegroundColor Green
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
    }
}
restart-service ccmexec
control



Test-NetConnection sccmprd02.mercantile.co.za -port 80
Test-NetConnection sccmprd02.mercantile.co.za -port 443
Test-NetConnection sccmprd02.mercantile.co.za -port 445
Test-NetConnection sccmprd02.mercantile.co.za -port 8530
Test-NetConnection sccmprd02.mercantile.co.za -port 8531
Test-NetConnection sccmprd02.mercantile.co.za -port 10123
