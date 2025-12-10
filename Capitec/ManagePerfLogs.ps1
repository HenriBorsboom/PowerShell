#Script used to manage the EBF- perflogs on the servers
#
#Usage from PowerShell:
#  FullPath\ManagePerfLogs.ps1 -site sitename
#Example:
#  FullPath\ManagePerfLogs.ps1 -site STB
#  
#Scheduling:
#  To schedule this scripts, use the standard Windows Task Scheduler or any other scheduling program
#Command to schedule:
#  FullPath\powershell.exe FullPath\ManagePerfLogs.ps1 -site sitename
#Example:
#  C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe x\ManagePerfLogs.ps1 -site BLV
#
#Return codes:
#  1  : Could not start Task Scheduler or Performance Counter DLL Host service
#  2  : Could not query the performance log status
#  3  : Could not query the performance log details
#  4  : Could not query the performance log status
#  5  : Not all configured EBF traces could be stopped
#  6  : Could not start Task Scheduler service
#  7  : Could not query the performance log status
#  8  : Could not query the performance log status
#  9  : Not all configured EBF traces could be started
# 10  : An exception was trapped during the execution of the script
# 11  : An exception was caught during the execution of the script
# 12  : Incorrect SITE specified
#
#Scherrit Knoesen
#2015-05-05
#version 1.02

#
#change history:
# 2013-07-15 	1.01	added support for 32 bit counters
# 2015-05-05 	1.02	changes: 
#							compression now optional
#							can request only a specific log (and not all EBF traces)
#							collected files with the same names won't overwrite each other 
# 2023-04-19    1.03    Changed 'EBF' filter string for 'SAS':section #initial variable instatiation start
#							
#							
#							

#--------------------------------------------------------------------------------------------------------------------------
#input parameters
#--------------------------------------------------------------------------------------------------------------------------
#
param
(
	$site
	,$bit
    ,[switch]$compression
    ,$perflog
)
cls

#--------------------------------------------------------------------------------------------------------------------------
#Functions
#--------------------------------------------------------------------------------------------------------------------------
#Function used to get date and time stamp in a yyyy/MM/dd-HH:mm:ss format
function datetimestampFull 
{    
    get-date -format "yyyy/MM/dd-HH:mm:ss"
} 

#Function used to compress a file and delete the original file
function relocateFile
{
	param (
		$inFile,
		$outFile,
		[switch]$delete
        ,[switch]$compression
	)
	
	#trap any error that can occur in the function
	trap
	{
		((datetimestampFull) + ' - EXCEPTION - An exception occured during compression of file: ' + $inFile) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		((datetimestampFull) + ' - EXCEPTION: ' + $error[0].ToString()) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - CategoryInfo: ' + $error[0].CategoryInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - Exception: ' + $error[0].Exception) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - FullyQualifiedErrorId: ' + $error[0].FullyQualifiedErrorId) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - PipelineIterationInfo: ' + $error[0].PipelineIterationInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - ScriptStackTrace: ' + $error[0].ScriptStackTrace) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - TargetObject: ' + $error[0].TargetObject) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - EXCEPTION - Additional Info - PSMessageDetails: ' + $error[0].PSMessageDetails) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        #close the streams if they were opened
		if ($input)
		{
			$input.Close()
		}
		if ($output)
		{
			$output.Close()
		}
		if ($gzipStream)
		{
			$gzipStream.Close()
		}
		return 2
	}
	
	#does the input file exist
	if (!(Test-Path $inFile))
	{
		((datetimestampFull) + ' - ERROR - File ' + $inFile + ' does not exist') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		return 1
	}
    
    $increment = 1
    
    $extension = $outFile.substring($outFile.LastIndexOf('.'))
        
    if ($compression)
    {
        #does the output file already exist
        while (Test-Path ($outfile + '.gz'))
    	{
            $outfile = ($outFile.replace($extension,'').replace(('_' + ($increment-1).ToString()),'') + '_' + ($increment++).ToString() + $extension)
    	}
        $outfile = ($outfile + '.gz')
        #create the stream objects
    	$input = New-Object System.IO.FileStream $inFile, ([IO.FileMode]::Open), ([IO.FileAccess]::Read), ([IO.FileShare]::Read)
    	$output = New-Object System.IO.FileStream $outFile, ([IO.FileMode]::Create), ([IO.FileAccess]::Write), ([IO.FileShare]::None)
    	$gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)

    	#start the compression
    	((datetimestampFull) + ' - INFO - Compressing ' + $inFile + ' to ' + $outfile) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    	try
    	{
    		#buffer used for writing
    		$buffer = New-Object byte[](1024);

    		while($true)
    		{
    			#read the input into the buffer
    			$read = $input.Read($buffer, 0, 1024)
    			#has all the data been read ?
    			if ($read -le 0)
    			{
    				break;
    			}
    			#write the buffer to the compressed stream
    			$gzipStream.Write($buffer, 0, $read)
    		}
    	}
    	finally
    	{
    		#close the streams
    		$gzipStream.Close();
    		$output.Close();
    		$input.Close();
    		(Get-Item -Path $outFile).LastAccessTime = (Get-Item -Path $inFile).LastAccessTime
    		(Get-Item -Path $outFile).LastWriteTime = (Get-Item -Path $inFile).LastWriteTime
    	}
	}
    else
    {
        #does the output file already exist
        while (Test-Path $outFile)
    	{
            $outfile = ($outFile.replace($extension,'').replace(('_' + ($increment-1).ToString()),'') + '_' + ($increment++).ToString() + $extension)
    	}
        
        ((datetimestampFull) + ' - INFO - Copying ' + $inFile + ' to ' + $outfile) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
        #Copy the performance trace to the temp folder
		Copy-Item -Path $inFile -Destination $outFile
    }
    
	#delete the file if specified
	if ($delete)
    {
        ((datetimestampFull) + ' - INFO - Deleting original file: ' + $inFile) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		Remove-Item $inFile
    }
	
    $outFileName = $outFile.substring($outFile.LastIndexOf('\') + 1)
	return 0, $outFileName
}

#Function used to start a process (takes PowerShell version 1 and version 2 into account)
function Start-EBFProcess {
    param (
        $processName
        ,[Array]$params
        ,[switch]$stdOutput
    )
    
    if ($stdOutput)
    {
        if (test-path ($env:TEMP + '\managePerfLogsStdOutput.txt'))
        {
            remove-item -path ($env:TEMP + '\managePerfLogsStdOutput.txt') -force
        }
        $process = (Start-Process $processName -ArgumentList $params -Wait -PassThru -RedirectStandardOutput ($env:TEMP + '\managePerfLogsStdOutput.txt'))
        $stdOutputData = get-content -path ($env:TEMP + '\managePerfLogsStdOutput.txt')
    }
    else
    {
        $process = (Start-Process $processName -ArgumentList $params -Wait -PassThru)
    }
    if (test-path ($env:TEMP + '\managePerfLogsStdOutput.txt'))
    {
        remove-item -path ($env:TEMP + '\managePerfLogsStdOutput.txt') -force
    }
		$returnValue = $process.ExitCode

	#if the standard output stream data is used
	if ($stdOutput)
    {
		#return the exit code for the process and the standard output stream data
		return [int]$process.ExitCode, $stdOutputData
	}
	else
	{
		#return the exit code for the process
		return [int]$returnValue
	}        
}

#Function used to query the status of the performance traces
function queryPerfLogStatus {
    param (
        $logMan,
        [switch]$outputStream
    )
	[Array]$params = 'query'
    #initialize the standard output stream data
    $outputStreamData = ''
	$returnValue, $outputStreamData = (Start-EBFProcess -processName $logMan -params $params -stdOutput)
    start-sleep -Seconds 5
    if ($returnValue -eq -2147024893)
	{
		((datetimestampFull) + ' - ERROR(' + $returnValue + ') - The Task Scheduler service is not started') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		((datetimestampFull) + ' - Please start the Task Scheduler service before continuing') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	elseif ($returnValue -ne $successCode)
	{
		((datetimestampFull) + ' - ERROR(' + $returnValue + ') - An error occured when attempting to query the configured Performance Counter Log traces') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		((datetimestampFull) + ' - Please investigate before continuing') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	#return the exit code for the process and the standard output stream data
	return [int]$returnValue, $outputStreamData
}

#Function used to query the status of a particular performance trace
function queryPerfLogDetails {
	param (
        $logMan,
        $traceName,
        [switch]$outputStream
    )
    
    [Array]$params = 'query', $traceName
    #initialize the standard output stream data
    $outputStreamData = ''
    $returnValue, $outputStreamData = (Start-EBFProcess -processName $logMan -params $params -stdOutput)
    start-sleep -Seconds 5
	if ($returnValue -eq -2147024893)
	{
		((datetimestampFull) + ' - ERROR(' + $returnValue + ') - The Task Scheduler service is not started') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		((datetimestampFull) + ' - Please start the Task Scheduler service before continuing') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	elseif ($returnValue -ne $successCode)
	{
		((datetimestampFull) + ' - ERROR(' + $returnValue + ') - An error occured when attempting to query the Performance Counter Log trace: ' + $traceName) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		((datetimestampFull) + ' - Please investigate before continuing') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	#return the exit code for the process and the standard output stream data
	return [int]$returnValue, $outputStreamData
}

#Function used to determine all the running traces of interest
function runningTraces {
    param (
        $inputString
    )
    
    #build a list of all the configured EBF Traces
    $searchStr = ' Counter   '
    $running = 'RUNNING'
    $EBFRunningTraces = @()
    foreach ($line in $inputString)
    {
        if ($line.ToUpper().contains($EBFTraceNameStr))
        {
            if ($line.ToUpper().contains($running))
            {
                $EBFRunningTraces += $line.substring(0,$line.indexof($searchStr))
            }
        }
    }
    return $EBFRunningTraces
}

#Function used to determine the log file used for a trace
function traceLogFile {
    param (
        $inputString,
		$OS
    )
    
    #build a list of all the configured EBF Traces
	if ($OS -ge $Win_2008)
	{
		$searchStr = 'OUTPUT LOCATION:'
	}
	else
	{
		$searchStr = 'FILE:'
	}
	
    foreach ($line in $inputString)
    {
        if ($line.ToUpper().contains($searchStr))
        {
            $traceLogFileName = $line.ToUpper().Replace($searchStr, '').Trim()
        }
    }
    return $traceLogFileName
}

#Function used to determine all the running traces of interest
function stoppedTraces {
    param (
        $inputString
    )
    
    #build a list of all the configured EBF Traces
    $searchStr = ' Counter   '
    $stopped = 'STOPPED'
    $EBFStoppedTraces = @()
    foreach ($line in $inputString)
    {
        if ($line.ToUpper().contains($EBFTraceNameStr))
        {
            if ($line.ToUpper().contains($stopped))
            {
                $EBFStoppedTraces += $line.substring(0,$line.indexof($searchStr))
            }
        }
    }
    return $EBFStoppedTraces
}
#Function used to stop or start the performance traces
function managePerfLogTrace
{
    param (
        $action,
        $trace
    )
    
    if ($action.ToUpper() -eq 'STOP')
    {
        [Array]$params = ($action.ToUpper(), '-n ' + $trace)
        $returnValue = (Start-EBFProcess -processName $logMan -params $params)
        start-sleep -Seconds 10
    }
    elseif ($action.ToUpper() -eq 'START')
    {
        [Array]$params = ($action.ToUpper(), $trace)
        $returnValue = (Start-EBFProcess -processName $logMan -params $params)
        start-sleep -Seconds 10
    }
    else
    {
        ((datetimestampFull) + ' - ERROR - An invalid action was specified ... nothing will be performed') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    }
    return [int]$returnValue
}

#--------------------------------------------------------------------------------------------------------------------------
#initial variable instatiation start
#--------------------------------------------------------------------------------------------------------------------------
$successCode = 0
$Win_2008 = 6
if ($perflog)
{
    $EBFTraceNameStr = $perflog.ToString().ToUpper()
}
else
{
#1.03
    $EBFTraceNameStr = 'SAS-'
}


if ($bit -ne '32')
{
	$logMan = 'C:\Windows\System32\logman.exe'
}
else
{
	$logMan = 'C:\Windows\SysWOW64\logman.exe'
}
if ($site.ToUpper() -eq 'STB')
{
    $destinationPath = ('\\capitecbank.fin.sky\nas\Perflogs\' + $env:COMPUTERNAME)
#	$destinationPath = ('\\CBSTBTS01\PerfLogs\' + $env:COMPUTERNAME)
}
elseif ($site.ToUpper() -eq 'BLV')
{
    $destinationPath = ('\\capitecbank.fin.sky\nas\Perflogs\' + $env:COMPUTERNAME)
#	$destinationPath = ('\\CBBLVTS01\PerfLogs\' + $env:COMPUTERNAME)
}
else
{
	Write-Host 'Incorrect Site paramater provided:'
	Write-Host 'Usage from PowerShell:	FullPath\ManagePerfLogs.ps1 -site sitename[STB|BLV]'
	Write-Host 'Example:				FullPath\ManagePerfLogs.ps1 -site STB'
	exit 12
}
$logFile = ($destinationPath + '\ManagePerfLogs_' + (get-date -format "yyyy-MM-dd_HH-mm-ss") + '.log')
$stdOutputData = ''

#--------------------------------------------------------------------------------------------------------------------------
#Script body
#--------------------------------------------------------------------------------------------------------------------------
cls

if (!(Test-Path $destinationPath))
{
	New-Item -Path $destinationPath -Force -ItemType Directory
}

#trap any error that can occur in the script
trap
{
	((datetimestampFull) + ' - EXCEPTION - An exception was trapped during the execution of the script') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	((datetimestampFull) + ' - EXCEPTION: ' + $error[0].ToString()) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - CategoryInfo: ' + $error[0].CategoryInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - Exception: ' + $error[0].Exception) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - FullyQualifiedErrorId: ' + $error[0].FullyQualifiedErrorId) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - PipelineIterationInfo: ' + $error[0].PipelineIterationInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - ScriptStackTrace: ' + $error[0].ScriptStackTrace) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - TargetObject: ' + $error[0].TargetObject) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - PSMessageDetails: ' + $error[0].PSMessageDetails) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	exit 10
}

try
{
	((datetimestampFull) + ' - START - Starting the EBF Performance log management process on ' + $env:COMPUTERNAME) | out-file -FilePath $logFile -Encoding ASCII -Append -Force

	#get the OS version
	$OS = [int]((Get-WmiObject Win32_OperatingSystem).version.split(".")[0])

	#Create the log file
	if (!(Test-Path $logFile))
	{
		New-Item -Path $logFile -ItemType File -Force
	}
	
	#STOP Performance traces
	#check if task scheduler service is running on Windows Server 2008 and later
	if ($OS -ge $Win_2008)
	{
		if ((Get-Service -DisplayName "Task Scheduler").status.ToString().ToUpper() -eq 'STOPPED')
		{
			((datetimestampFull) + ' - INFO - The Task Scheduler service is stopped ... attempting to start the service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        Start-Service -DisplayName "Task Scheduler"
			if (!$?)
			{
				((datetimestampFull) + ' - ERROR - An error occured when attempting to start the Task Scheduler service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
				((datetimestampFull) + ' - Windows Server 2008 and later requires the Task Scheduler server for Performance Log collections') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
				exit 1
			}
		}
		
		if ($bit -eq '32')
		{
			Stop-Service -DisplayName "Performance Counter DLL Host"
			if ((Get-Service -DisplayName "Performance Counter DLL Host").status.ToString().ToUpper() -eq 'STOPPED')
			{
				((datetimestampFull) + ' - INFO - The Performance Counter DLL Host service is stopped ... attempting to start the service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		        Start-Service -DisplayName "Performance Counter DLL Host"
				if (!$?)
				{
					((datetimestampFull) + ' - ERROR - An error occured when attempting to start the Performance Counter DLL Host service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
					((datetimestampFull) + ' - Windows Server 2008 and later requires the Performance Counter DLL Host service for Performance Log collections of 32 bit counters') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
		            ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs_v2.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
					exit 1
				}
			}
		}
	}
	#initialize the output stream data
	$stdOutputData = ''
	#query the configured Performance Counter Log traces
	$returnValue, $stdOutputData = queryPerfLogStatus -logman $logMan -outputStream
	#check if the query succeeded
	if ($returnValue -ne $successCode)
	{
	    ((datetimestampFull) + ' - ERROR - Could not successfully query the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Process cannot continue without successfully quering the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    exit 2
	}
	#determine the running traces
	$EBFRunningTraces = runningTraces -inputString $stdOutputData
	#intialize the list of all the trace files
	$traceLogFiles = @()
    #stop all EBF-* traces on the server (using logman)
	if ( !(($EBFRunningTraces.count -eq 0) -or ($EBFRunningTraces -eq $null)) )
	{
	    foreach ($trace in $EBFRunningTraces)
	    {
	        #reinitialize the standard output stream
	        $stdOutputData = ''
	        #get the log files for running traces
			$returnValue, $stdOutputData = queryPerfLogDetails -logMan $logMan -traceName $trace -outputStreamData
	        #check if the query succeeded
	        if ($returnValue -ne $successCode)
	        {
	            ((datetimestampFull) + ' - ERROR - Could not successfully query the performance log details for ' + $trace) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            ((datetimestampFull) + ' - Process cannot continue without successfully quering the performance log details') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            exit 3
	        }
			$traceLogFiles += traceLogFile -inputString $stdOutputData -OS $OS
	        #reinitialize the standard output stream
	        $stdOutputData = ''
			#stop the trace	
	        $returnValue = managePerfLogTrace -action 'STOP' -trace $trace
	        if ($returnValue -ne $successCode)
	        {
	            ((datetimestampFull) + ' - ERROR - Trace: ' + $trace.trim() + ' could not be stopped') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            ((datetimestampFull) + ' - Countinuing with remaining tracesPlease investigate before continuing') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        }
	        else
	        {
	            ((datetimestampFull) + ' - INFO - Trace: ' + $trace.trim() + ' stopped successfully') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        }
	    }
	}
	#verify that all EBF-* traces have been stopped (using logman)
	$retry = 3
	$allTracesStopped = $false
	for ($attempt = 0; $attempt -lt $retry; $attempt++)
	{
	    #reinitialize the standard output stream
	    $stdOutputData = ''
	    $returnValue, $stdOutputData = queryPerfLogStatus -logman $logMan  -outputStream
	    #check if the query succeeded
	    if ($returnValue -ne $successCode)
	    {
	        ((datetimestampFull) + ' - ERROR - Could not successfully query the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - Process cannot continue without successfully quering the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        exit 4
	    }
	    $EBFRunningTraces = runningTraces -inputString $stdOutputData
	    if ( ($EBFRunningTraces.count -eq 0) -or ($EBFRunningTraces -eq $null) )
	    {
	        $allTracesStopped = $true
	        break
	    }
	    else
	    {
	        $allTracesStopped = $false
	        start-sleep -seconds 15
	    }
	}
	if ($allTracesStopped)
	{
	    ((datetimestampFull) + ' - INFO - All requested EBF traces have been stopped successfully or was stopped') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	else
	{
	    ((datetimestampFull) + ' - ERROR - Not all requested EBF traces have been stopped') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    exit 5
	}

	#MOVE the performance traces
	foreach ($file in $traceLogFiles)
	{
	    #get the file name
		$fileName = $file.substring($file.LastIndexOf('\') + 1)
		#create the destination path if it does not already exist
	    if ( !(test-path $destinationPath) )
	    {
	        new-item -path $destinationPath -itemtype Directory -force
	    }
	    #compress and move the trace files on the server and delete the uncompressed file
	    if ($compression)
        {
            $returnValue, $fileName = relocateFile -inFile $file -outFile ($destinationPath + '\' + $fileName) -delete -compression
        }
        else
        {
            $returnValue, $fileName = relocateFile -inFile $file -outFile ($destinationPath + '\' + $fileName) -delete
        }
	    if ($returnValue -ne $successCode)
	    {
	        ((datetimestampFull) + ' - ERROR - An error occured when relocating the file: ' + $inFile) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - You will have to manually relocate the file (' + $file + ') and copy it to ' + $destinationPath) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    }
	    if (test-path $file)
	    {
	        ((datetimestampFull) + ' - ERROR - An error occured, the file: ' + $file + ' has not been relocated') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - Please investigate') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    }
	    if (test-path ($destinationPath + '\' + $fileName))
	    {
	        ((datetimestampFull) + ' - INFO - The file: ' + $file + ' has been successfully compressed or moved to ' + ($destinationPath + '\' + $fileName)) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    }
	}

	#START the performance traces
	#check if task scheduler service is running on Windows Server 2008 and later
	if ($OS -ge $Win_2008)
	{
		if ((Get-Service -DisplayName "Task Scheduler").status.ToString().ToUpper() -eq 'STOPPED')
		{
			((datetimestampFull) + ' - INFO - The Task Scheduler service is stopped ... attempting to start the service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        Start-Service -DisplayName "Task Scheduler"
			if (!$?)
			{
				((datetimestampFull) + ' - ERROR - An error occured when attempting to start the Task Scheduler service') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
				((datetimestampFull) + ' - Windows Server 2008 and later requires the Task Scheduler server for Performance Log collections') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	            ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
				exit 6
			}
		}
	}
	#reinitialize the standard output stream
	$stdOutputData = ''
	#query the configured Performance Counter Log traces
	$returnValue, $stdOutputData = queryPerfLogStatus -logman $logMan  -outputStream
	#check if the query succeeded
	if ($returnValue -ne $successCode)
	{
	    ((datetimestampFull) + ' - ERROR - Could not successfully query the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Process cannot continue without successfully quering the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    exit 7
	    
	}

    #determine the running traces
	$EBFStoppedTraces = stoppedTraces -inputString $stdOutputData
	#start all EBF-* traces on the server (using logman)
	if ( !(($EBFStoppedTraces.count -eq 0) -or ($EBFStoppedTraces -eq $null)) )
	{
	    foreach ($trace in $EBFStoppedTraces)
	    {
			#reinitialize the standard output stream
	        $stdOutputData = ''
	        #start the trace		
			$returnValue = managePerfLogTrace -action 'START' -trace $trace
	        if ($returnValue -ne $successCode)
	        {
	            ((datetimestampFull) + ' - ERROR - Trace: ' + $trace.trim() + ' could not be started') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        }
	        else
	        {
	            ((datetimestampFull) + ' - INFO - Trace: ' + $trace.trim() + ' started successfully') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        }
	    }
	}
	#verify that all EBF-* traces have been started (using logman)
	$retry = 3
	$allTracesStarted = $false
	for ($attempt = 1; $attempt -le $retry; $attempt++)
	{
        ((datetimestampFull) + ' - INFO - Verify if the requested EBF traces have been started - Attempt ' + $attempt) | out-file -FilePath $logFile -Encoding ASCII -Append -Force	    
        #reinitialize the standard output stream
	    $stdOutputData = ''
	    $returnValue, $stdOutputData = queryPerfLogStatus -logman $logMan  -outputStream
	    #check if the query succeeded
	    if ($returnValue -ne $successCode)
	    {
	        ((datetimestampFull) + ' - ERROR - Could not successfully query the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - Process cannot continue without successfully quering the performance log status') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script after the problem has been corrected') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	        exit 8
	    }
	    $EBFStoppedTraces = stoppedTraces -inputString $stdOutputData
	    if ( ($EBFStoppedTraces.count -eq 0) -or ($EBFStoppedTraces -eq $null) )
	    {
	        $allTracesStarted = $true
	        break
	    }
	    else
	    {
	        $allTracesStarted = $false
	        start-sleep -seconds 15
	    }
	}
	if ($allTracesStarted)
	{
	    ((datetimestampFull) + ' - INFO - All requested EBF traces have been started successfully or was started') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	}
	else
	{
	    ((datetimestampFull) + ' - ERROR - Not all requested EBF traces have been started') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    ((datetimestampFull) + ' - Please investigate and restart the ManagePerfLogs.ps1 script') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	    exit 9
	}
    
	#END
	((datetimestampFull) + ' - END - Completed the EBF Performance log management process on ' + $env:COMPUTERNAME) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	exit 0
}
catch
{
	((datetimestampFull) + ' - EXCEPTION - An exception was caught during the execution of the script') | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION: ' + $error[0].ToString()) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - CategoryInfo: ' + $error[0].CategoryInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - Exception: ' + $error[0].Exception) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - FullyQualifiedErrorId: ' + $error[0].FullyQualifiedErrorId) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - PipelineIterationInfo: ' + $error[0].PipelineIterationInfo) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - ScriptStackTrace: ' + $error[0].ScriptStackTrace) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - TargetObject: ' + $error[0].TargetObject) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Additional Info - PSMessageDetails: ' + $error[0].PSMessageDetails) | out-file -FilePath $logFile -Encoding ASCII -Append -Force
	exit 11
}
#--------------------------------------------------------------------------------------------------------------------------
