# asynchronous IP range scanner   
   
Function Start-IPScan {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $First3Octects, `
        [Parameter(Mandatory=$true,Position=2)]
        [Int32] $StartIP, `
        [Parameter(Mandatory=$true,Position=3)]
        [Int32] $EndIP)

    #region define the range   
        [string] $firstThree = $First3Octects
        [int]    $startRange = $StartIP   
        [int]    $endRange = $EndIP  
    #endregion
    
    #region defines how many IPs to scan at a time. Used to limit the amount of resources used by the scan.   
    $groupMax = 50   
    #endregion

    #region start the range scan as jobs   
    $count = 1   
    $startRange..$endRange | %{   
        # start a test-connection job for each IP in the range, return the IP and boolean result from test-connection   
        start-job -ArgumentList “$firstThree`.$_” -scriptblock { $test = test-connection $args[0] -count 2 -quiet; return $args[0],$test } | out-null   

        # sleep for 3 seconds once groupMax is reached. This code helps prevent security filters from flagging port traffic as malicious for large IP ranges.   
        if ($count -gt $groupMax) {   
            sleep 3   
            $count = 1   
        } 
        else {   
            $count++   
        }   
    }
    #endregion   

    #region wait for all the jobs to finish   
    get-job | wait-job   
    #endregion

    #region store the jobs into an array   
    $jobs = get-job   
    #endregion

    #region holds the results of the jobs   
    $results = @()   

    foreach ($job in $jobs) {   
        # grab the job output   
        $temp = receive-job -id $job.id -keep   
        $results += ,($temp[0],$temp[1])   
    }   
    #endregion

    #region stop and remove all jobs   
    get-job | stop-job   
    get-job | remove-job   
    #endregion

    #region sort the results   
    $results = $results | sort @{Expression={$_[0]}; Ascending=$false}   
    #endregion

    #region report the results   
    foreach ($result in $results) {   
        if ($result[1]) {   
            write-host -f Green “$($result[0]) is responding”   
        } 
        else {   
            write-host -f Red “$($result[0]) is not responding”   
        }   
    }
    #endregion
}

$Octects = "10.10.145"
$Start   = 65
$End     = 127
Start-IPScan -First3Octects $Octects -StartIP $Start -EndIP $End