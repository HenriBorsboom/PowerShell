Function Start-Server {
    For ($i = 1; $i -lt 10; $i ++) {
        $Port = "520" + $i.ToString()
        Start-Process 'D:\Apps\Captools\iperf-3.1.3-win64\iperf3.exe' -ArgumentList "-s", "-p", $Port
    }
}
Function Start-Client {
    Param (
        [Parameter(Mandatory=$False, Position=0)]
        [Switch] $Reverse)

    If (!$Reverse) {
        For ($i = 1; $i -lt 10; $i ++) {
            $Port = "520" + $i.ToString()
            Start-Process '.\iperf3.exe' -ArgumentList "-c",$TargetIP,"-t","90","-P","8","-p", $Port, "--logfile", ($ENV:COMPUTERNAME + '_' + $TargetIP + '.txt')
        }
    }
    Else {
        For ($i = 1; $i -lt 10; $i ++) {
            $Port = "520" + $i.ToString()
            Start-Process 'D:\Apps\Captools\iperf-3.1.3-win64\iperf3.exe' -ArgumentList "-s", "-p", $Port
        }
    }
}
Function Stop-Server {
    Get-Process Iperf3 | Stop-Process
}
Set-Location 'D:\Apps\Captools\iperf-3.1.3-win64'
$TargetIP = '10.225.46.2'
Start-Client