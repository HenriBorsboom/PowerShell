# Script used to perfomr the BANCS SNAP Process for BANCS running on Pure Storage
#
# Usage from Powershell
# Fullpath\PURE_SNAP.ps1 [-startAtStep stepNumber] [-stopAtStartOfStep stepNumber] [-ReportRun] [-Scheduler]
# Example:
# FullPath\PURE_SNAP.ps1 -startAtStep 0 -stopAtStartOfStep 11
#
# Schduling:
# To schedule this scripts, use the standard Windows Task Scheduler or any other scheduling program
#Command to schedule:
#  FullPath\powershell.exe FullPath\PURE_SNAP.ps1 [-startAtStep stepNumber] [-stopAtStartOfStep stepNumber] [-ReportRun] -Scheduler
#Example:
#  C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe FullPath\PURE_SNAP.ps1 -startAtStep 0 -stopAtStartOfStep 11 -Scheduler
#
#Return codes:
#             0                                                             : Success
#             10                                                           : No conifugration file provided
#             11                                                           : Invalid value used for stopAtStartOfStep parameter - review log file
#             500                                                        : Exception trapped in execution - review log file
#             501                                                        : Exception caught in execution - review log file
#   601             : Disk not online
#
#             1-99 indicates parameter validation errors
#             100-199 indicates external input availability errors
#             200-299 indicates external input validation errors
#             500 and above indicates processing issues. Examples: Input corrupt, Database connection issues, Output destination drive full
#
#             STEP 1 - Clean up previous snapshots
#             STEP 2 - Create *014BANR snapshots
#             STEP 3 - Detach DB
#             STEP 4 - Remove disk mapping
#             STEP 5 - Offline disks
#             STEP 6 - Copy snapshots
#             STEP 7 - Online disks, relabel and mount drives
#             STEP 8 - Rename DB files
#             STEP 9 - Attach DB
#             STEP 10 - Change DB owner
#             STEP 11 - Change recovery model
#
# Eugene Engelbrecht
# 2019-03-27
#
# change history
#   1.0 Script creation
#---------------------------------------------------------------------------------------------------------------------------------------
# input parameters
#---------------------------------------------------------------------------------------------------------------------------------------
param(
    $startAtStep,
    $stopAtStartOfStep,
    [switch]$ReportRun,
    [switch]$Scheduler
)
##############################################################################################################################################################################
# Functions
##############################################################################################################################################################################
function datetimestampFull {    
    Get-Date -format "yyyy/MM/dd HH:mm:ss"
} 
function stop-Or-Continue-Execution {   
    param (
        $stopAtStartOfStep
        , $startAtStep
        , $start
        , $currentStep
        , $logFile
        , $Scheduler
        , $exitCodeFile
    )
                
    #check whether to conitnue or not
    if ($stopAtStartOfStep -le $startAtStep) {
        ((datetimestampFull) + ' - INFO      - Process NOT continuing due to stopAtStartOfStep parameter value supplied') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        $end = (Get-Date)
        ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        (0) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
        exit 0
    }
}
function get-Cluster-Role-Owner {    
    param (
        $clusterNetworkName
        , $clusterRoleName
    )

    #obtain the cluster role owner node
    $ClusterOwnerNode = (Get-WMIObject -Class MSCluster_ResourceGroup -Namespace root\mscluster -filter "name='$clusterRoleName'").ownernode

    return $ClusterOwnerNode
}
function exit-Execution {    
    param (
        $returnCode
        ,$startAtStep
        ,$logFile
        ,$exitCodeFile
    )           
                
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - ERROR     - An error occurred (error code: ' + $returnCode + ')') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - ERROR     - Inspect the log file for more detail and ONLY once the problem has been resolved, continue from STEP ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    $end = (Get-Date)
    ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ($returnCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    exit $returnCode
}               
##############################################################################################################################################################################
# Params
##############################################################################################################################################################################
$paramsProvided = $null
$configFile = "F:\BANCS_SNAP\Scripts\QA_E\PURESNAPVSS.XML"
$start = (Get-Date)
$maximumSteps = 11
$successCode = 0
if ($null -eq $startAtStep) {
    $startAtStep = 0
}
$startAtStep = [int]$startAtStep
if ($null -eq $stopAtStartOfStep) {
    $stopAtStartOfStep = ($maximumSteps + 1)
}
$stopAtStartOfStep = [int]$stopAtStartOfStep
<#
if (!(Test-Path $configFile))
{
                (10) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    exit 10
}
else
{
    $paramsProvided = "-configFile $configFile "
}
#>
[xml]$xmlConfiguration = [xml](Get-Content -Path $configFile)
[System.Xml.XmlElement]$PURE_SNAP_CONFIG = $xmlConfiguration.get_DocumentElement()
$successCode = $PURE_SNAP_CONFIG.Other.SuccessCode
$currentUser = whoami
$userAccount = $currentUser.Substring($currentUser.IndexOf('\') + 1)
if (!$ReportRun) {
    $Run = $PURE_SNAP_CONFIG.BATCH.Run
    $MetaLogFile = $PURE_SNAP_CONFIG.BATCH.Path + "Logs\" + $PURE_SNAP_CONFIG.BATCH.DshLogFile
    $cabFile = $PURE_SNAP_CONFIG.BATCH.Path + $PURE_SNAP_CONFIG.BATCH.MetaDataCabFile
    $shellScript = $PURE_SNAP_CONFIG.BATCH.Path + $PURE_SNAP_CONFIG.BATCH.shellScript
    $SNAPString = $PURE_SNAP_CONFIG.BATCH.SNAPString
    $logFile = ($PURE_SNAP_CONFIG.Other.LogPath + '\' + $PURE_SNAP_CONFIG.Other.SnapshotLogFile + '_' + $Run + '_' + $userAccount.ToUpper() + '_' + (Get-Date -format "yyyy-MM-dd") + '.log')
    
}
else {
    $Run = $PURE_SNAP_CONFIG.REPORT.Run
    $MetaLogFile = $PURE_SNAP_CONFIG.REPORT.Path + "Logs\" + $PURE_SNAP_CONFIG.REPORT.DshLogFile
    $cabFile = $PURE_SNAP_CONFIG.REPORT.Path + $PURE_SNAP_CONFIG.REPORT.MetaDataCabFile
    $shellScript = $PURE_SNAP_CONFIG.REPORT.Path + $PURE_SNAP_CONFIG.REPORT.shellScript
    $SNAPString = $PURE_SNAP_CONFIG.REPORT.SNAPString
    $logFile = ($PURE_SNAP_CONFIG.Other.LogPath + '\' + $PURE_SNAP_CONFIG.Other.SnapshotLogFile + '_' + $Run + '_' + $userAccount.ToUpper() + '_' + (Get-Date -format "yyyy-MM-dd") + '.log')
    $paramsProvided += "-ReportRun "

}
#$stdOutputFile = ($PURE_SNAP_CONFIG.Other.LogPath + '\' + $PURE_SNAP_CONFIG.Other.SnapshotLogFile + '.tmp')
$stdOutputData = ''
$exitCodeFile = ($PURE_SNAP_CONFIG.Other.LogPath + '\' + $PURE_SNAP_CONFIG.Other.ExitCodeFile)
$paramsProvided += "-startAtStep $startAtStep "
$paramsProvided += "-stopAtStartOfStep $stopAtStartOfStep "

if ($Scheduler) {
    $paramsProvided += "-Scheduler "
}

Clear-Host


#trap any exceptions that occurred in the script
trap {
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - An exception was trapped during the execution of the script') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Script failed during the execution of step ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ToString()) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ScriptStackTrace) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    $end = (Get-Date)
    ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    if ($Scheduler) {
        #(500) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
        ('ERROR CODE RETURNED: 500') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    }
    (500) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    exit 500
}
try {
    ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - START SCRIPT EXECUTION') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - SELECTED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    if (($startAtStep -eq 0) -or ($startAtStep -eq $null)) {
        ((datetimestampFull) + ' - START - Starting the BANCS SNAP process for database ' + $PURE_SNAP_CONFIG.SourceHost.DDBName + ' on ' + $PURE_SNAP_CONFIG.SourceHost.RoleName + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
    }
    else {
        ((datetimestampFull) + ' - CONTINUE  - Continuing the BANCS SNAP process from step ' + $startAtStep + ' for database ' + $PURE_SNAP_CONFIG.SourceHost.DDBName + ' on ' + $PURE_SNAP_CONFIG.SourceHost.RoleName + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    }

    ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - PARAMETERS USED FOR SCRIPT EXECUTION = ' + $paramsProvided) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                
    #Validate stop at
    if (!(($stopAtStartOfStep -ge 0) -and ($stopAtStartOfStep -le ($maximumSteps + 1)))) {
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '   - ERROR     - The stopAtStartOfStep value has not been correctly defined') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '   - ERROR     - Valid values = 0 - ' + $maximumSteps) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '   - ERROR     - Rerun using a valid value') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        $end = (get-date)
        ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if ($Scheduler) {
            #(11) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
            ('ERROR CODE RETURNED: 11') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        (11) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
        exit 11
    }

    $nextStart = Get-Date
    ##############################################################################################################################################################################
    # STEP 1 - Clean up previous snapshots
    ##############################################################################################################################################################################
    $currentStep = 1
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Clean up previous snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Clean up\Expire previous snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            
        #Get the host where the cluster role is running
        $ClusterRoleOwner = get-Cluster-Role-Owner -clusterRoleName $PURE_SNAP_CONFIG.SourceHost.RoleName
        if ($ClusterRoleOwner -eq $env:COMPUTERNAME) {
            ((datetimestampFull) + '         - Removal of snaps is running from ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force           
            ((datetimestampFull) + '         - Connecting to the Pure Storage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force   
            $FlashArray = New-PfaArray -EndPoint $PURE_SNAP_CONFIG.PSArray.HostName -ApiToken $PURE_SNAP_CONFIG.PSArray.APItoken -IgnoreCertificateError
            $SNAPS = Get-PfaAllVolumeSnapshots -Array $FlashArray | Where-Object { $_.name -like $SNAPString }
            if ($null -eq $SNAPS) {
                ((datetimestampFull) + '         - Could not find any snapshotset matching : ' + $SNAPString) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('################################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            else {
                $EradicateSuffix = Get-Date -Format yyyyMMddhhmmss
                foreach ($SNAP in $SNAPS) {
                    ((datetimestampFull) + '         - Renaming snapshot set ' + $SNAP.name + ' to ' + $SNAP.name + "-" + $EradicateSuffix) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                    Rename-PfaVolumeOrSnapshot -Array $FlashArray -Name $SNAP.name -NewName ($SNAP.name + "-" + $EradicateSuffix)
                    ((datetimestampFull) + '         - Deleting snapshot set ' + ($SNAP.name + "-" + $EradicateSuffix)) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                    Remove-PfaVolumeOrSnapshot -Array $FlashArray -Name ($SNAP.name + "-" + $EradicateSuffix)                
                }
            }
        }
        else {
            ((datetimestampFull) + '         - Removal of snaps is running from ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + '         - Check the logs on ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED Cleaning previous snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # STEP 2 - Create *014BANR snapshots
    ##############################################################################################################################################################################
    $currentStep = 2
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Create *014BANR snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Create *014BANR snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        #Get the host where the cluster role is running
        $ClusterRoleOwner = get-Cluster-Role-Owner -clusterRoleName $PURE_SNAP_CONFIG.SourceHost.RoleName
        if ($ClusterRoleOwner -eq $env:COMPUTERNAME) {
            ((datetimestampFull) + '         - The creations of snaps is running on ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force           
            # Remove previous metadata log file
            if (Test-Path -Path $MetaLogFile) {
                ((datetimestampFull) + '         - Deleting previous metadata file ' + $MetaLogFile ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                Remove-Item -Path $MetaLogFile
            }
            # Remove previous metadata cab file
            if (Test-Path -Path $cabFile) {
                ((datetimestampFull) + '         - Deleting previous cab file ' + $cabFile ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                Remove-Item -Path $cabFile
            }
            # Remove previous snapshot script file
            if (Test-Path -Path $shellScript) {
                ((datetimestampFull) + '         - Deleting previous shellscript ' + $shellScript ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                Remove-Item -Path $shellScript
            }
            
            # Getting Pure Storage VSS Provider
            ((datetimestampFull) + '         - Getting the Pure Storage VSS ProviderID') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $vssarray = @()
            $list = vssadmin list Providers
            $listnew = $list -replace "\s", "" | Select-String "Providername:", "ProviderId:"
            foreach ($vss in $listnew) {
                $obj = New-Object -TypeName psobject -Property @{
                    'ProviderName' = (((((($vss | select-string "Providername:") -replace "Providername:", "")) -replace "'", "")))
                    'ProviderId'   = (((((($vss | select-string "ProviderId:") -replace "ProviderId:", "")))) -replace '\{,\}')
                }
                $vssarray += $obj
            }
            $Providername = $vssarray | Where-Object {$_.Providername -ne $null } | Select-Object Providername | Select-Object -ExpandProperty Providername
            $ProviderId = $vssarray | Where-Object {$_.Providerid -ne $null } | Select-Object ProviderId | Select-Object -ExpandProperty Providerid
            $vssoutput = 0..($Providername.Length - 1) | Select-Object @{n = "ProviderName"; e = {$ProviderName[$_]}}, @{n = "ProviderId"; e = {($ProviderId[$_])}}
            $vsspos = $vssoutput.ProviderName.IndexOf("PureStorageVSSHardwareProvider(64-bit)")
            $vssproviderid = $vssoutput.Item($vsspos).ProviderID
            ((datetimestampFull) + '         - Pure Storage VSS ProviderID is ' + $vssproviderid ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            
            # Creating Shellscript
            ((datetimestampFull) + '         - Creating the snap script located at ' + $shellScript ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-Content $shellScript "RESET"
            Add-Content $shellScript "SET CONTEXT PERSISTENT"
            Add-Content $shellScript "SET OPTION TRANSPORTABLE"
            Add-Content $shellScript "SET VERBOSE ON"
            ((datetimestampFull) + '         - Creating the Shellscript metadata file located at ' + $cabFile ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-Content $shellScript "SET METADATA $cabFile"
            Add-Content $shellScript "BEGIN BACKUP"
            ((datetimestampFull) + '         - Adding the ' + $PURE_SNAP_CONFIG.DBData.SourceDriveLetter + ' drive to the script') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-Content $shellScript "ADD VOLUME $($PURE_SNAP_CONFIG.DBData.SourceDriveLetter) ALIAS $($PURE_SNAP_CONFIG.DBData.SourceLabel) PROVIDER $vssproviderid"
            ((datetimestampFull) + '         - Adding the ' + $PURE_SNAP_CONFIG.DBLog.SourceDriveLetter + ' drive to the script') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-Content $shellScript "ADD VOLUME $($PURE_SNAP_CONFIG.DBLog.SourceDriveLetter) ALIAS $($PURE_SNAP_CONFIG.DBLog.SourceLabel) PROVIDER $vssproviderid"
            Add-Content $shellScript "CREATE"
            Add-Content $shellScript "END BACKUP" 
            
            # Make SNAP
            ((datetimestampFull) + '         - Running the snap script located at ' + $shellScript) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $process = (Start-Process diskshadow.exe -ArgumentList ('/s ' + $shellScript) -Wait -PassThru -RedirectStandardOutput $MetaLogFile -WindowStyle Hidden)
            if ($process.ExitCode -eq '0') {
                ((datetimestampFull) + '         - Creation of snap was successful ') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $output = Get-Content -Path $MetaLogFile
                foreach ($line in $output) {
                    if ($line.ToUpper().contains("VSS_SHADOW_SET")) {
                        $GUID = $line.substring($line.IndexOf('{') + 1, $line.IndexOf('}') - $line.IndexOf('{') - 1).trim().toUpper().Replace('-', '')
                            
                    }
                }
                $SnapshotSuffix = "*.VSS-" + $GUID
                ((datetimestampFull) + '         - Snap shot suffix is ending in ' + $SnapshotSuffix) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + '         - Connecting to the Pure Storage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $FlashArray = New-PfaArray -EndPoint $PURE_SNAP_CONFIG.PSArray.HostName -ApiToken $PURE_SNAP_CONFIG.PSArray.APItoken -IgnoreCertificateError
                ((datetimestampFull) + '         - Getting all snap shots ending in ' + $SnapshotSuffix) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $Snapshots = Get-PfaAllVolumeSnapshots -Array $FlashArray | Where-Object { $_.name -like $SnapshotSuffix }
        
                # Rename SNAPS
                if ($null -ne $Snapshots) {
                    foreach ($Snapshot in $Snapshots) {
                        $Newname = $Snapshot.name.Split('.')[0] + "." + $Run
                        ((datetimestampFull) + '         - Renaming ' + $Snapshot.name + ' to ' + $Newname) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                        try {
                            Rename-PfaVolumeOrSnapshot -Array $FlashArray -Name $Snapshot.name -NewName $Newname -ErrorAction Stop 
                        }
                        catch {
                            ((datetimestampFull) + '         -Unable to rename ' + $Snapshot.name) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                            ((datetimestampFull) + '         - EXCEPTION - ' + $error[0].ToString()) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                            #((datetimestampFull) + '         - EXCEPTION - ' + $error[0].ScriptStackTrace) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                            exit-Execution -returnCode 514 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
                        }
                        
                    }
                    ('################################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                }
            }
            else {
                ((datetimestampFull) + '         - Running the shellscript failed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('################################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                exit-Execution -returnCode 515 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile    
            }
        }
        else {
            ((datetimestampFull) + '         - Creation of *014BANR snap is running on ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + '         - Check the logs on ' + $ClusterRoleOwner) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The creation of the snapshot') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # Step 3 - Detach DB
    ##############################################################################################################################################################################
    $currentStep = 3
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Set SINGLE USER Mode and then detach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Set SINGLE USER MODE and then detach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        #temporary file 
        $tmpFile = ([System.IO.Path]::GetRandomFileName())
        $outputFile = ('C:\Temp\' + $tmpFile)

        ((datetimestampFull) + '         - Attempting to set AUTO_UPDATE_STATISTICS_ASYNC OFF and SET SINGLE USER MODE and then detach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force                
        #cleanup previous output
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }

        ((datetimestampFull) + '         - sqlcmd.exe parameters:') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('-b', ('-S ' + $PURE_SNAP_CONFIG.SourceHost.HostName), '-E', '-d master', ('-Q "ALTER DATABASE ' + $PURE_SNAP_CONFIG.SourceHost.DDBName + ' SET AUTO_UPDATE_STATISTICS_ASYNC OFF; ALTER DATABASE ' + $PURE_SNAP_CONFIG.SourceHost.DDBName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = ' + "'" + $PURE_SNAP_CONFIG.SourceHost.DDBName + "')) exec sp_detach_db @dbname = [" + $PURE_SNAP_CONFIG.SourceHost.DDBName + ']"')) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        #start the process
        $SQLServer = $PURE_SNAP_CONFIG.SourceHost.HostName
        $sqlDatabaseCopyName = $PURE_SNAP_CONFIG.SourceHost.DDBName
        $process = (Start-Process sqlcmd.exe -ArgumentList ('-b', ('-S ' + $SQLServer), '-E', '-d master', ('-Q "ALTER DATABASE ' + $sqlDatabaseCopyName + ' SET AUTO_UPDATE_STATISTICS_ASYNC OFF; ALTER DATABASE ' + $sqlDatabaseCopyName + ' SET SINGLE_USER WITH ROLLBACK IMMEDIATE;IF (EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = ' + "'" + $sqlDatabaseCopyName + "')) exec sp_detach_db @dbname = [" + $sqlDatabaseCopyName + ']"')) -Wait -PassThru -RedirectStandardOutput $outputFile -WindowStyle Hidden)
        
        #obtain process output
        $stdOutputData = get-content -path $outputFile
        #cleanup
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        $returnCode = $process.ExitCode

        #display process output
        ($stdOutputData) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (($returnCode -gt $successCode) -or ($returnCode -lt $successCode)) {
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - ERROR     - An error occurred (error code: ' + $returnCode + ') while attempting to set AUTO_UPDATE_STATISTICS_ASYNC OFF and SET SINGLE USER MODE and then detach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - ERROR     - Investigate and ONLY once the problem has been resolved, continue ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $end = (get-date)
            ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            if ($Scheduler) {
                ('ERROR CODE RETURNED: ' + $returnCode) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            exit-Execution -returnCode $returnCode -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
        else {
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED Setting AUTO_UPDATE_STATISTICS_ASYNC OFF and SET SINGLE USER MODE and then detach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # Step 4 - Remove Disk Mapping
    ##############################################################################################################################################################################
    $currentStep = 4
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Unmount *014BANR disks from cluster') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Unmount *014BANR disks from cluster') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            
        foreach ($volume in (get-volume | Where-Object {$_.FileSystemLabel -like $PURE_SNAP_CONFIG.SourceHost.FileSystemLabel})) {
            $diskNumber = ($volume | Get-Partition).DiskNumber
            if ($null -ne $diskNumber) {
                $partitionNumber = ($volume | Get-Partition).PartitionNumber
                $mountPoint = ((Get-Partition -DiskNumber $diskNumber -PartitionNumber $partitionNumber).AccessPaths | Where-Object {$_.contains(':')})
                if ($null -ne $mountPoint) {
                    
                    ((datetimestampFull) + "         - Removing the NTFS mount point ($mountPoint) for partition $partitionNumber on disk $diskNumber") | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                    Remove-PartitionAccessPath -DiskNumber $diskNumber -PartitionNumber $partitionNumber -AccessPath $mountPoint
                }
            }
        }
        ((datetimestampFull) + '         - Rescaning VDS') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        Update-HostStorageCache  | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - VDS rescan completed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED Unmounted the *014BANR disks from clusternode') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # Step 5 - Offline Disks
    ##############################################################################################################################################################################
    $currentStep = 5
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Offline *014BANR disks from server') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Offline *014BANR disks from server') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        # Connect to Array
        try {
            ((datetimestampFull) + '         - Connecting to the Pure Storage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $FlashArray = New-PfaArray -EndPoint $PURE_SNAP_CONFIG.PSArray.HostName -ApiToken $PURE_SNAP_CONFIG.PSArray.APItoken -IgnoreCertificateError
        }
        catch {
            ((datetimestampFull) + '         - Could not connect to the Pure Storage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        try {
            # Get Serial number of Data disk from the Array
            ((datetimestampFull) + '         - Getting information for ' + $PURE_SNAP_CONFIG.DBData.TargetPurevolName + ' from the Pure Storrage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $DATA = Get-PfaVolume -Array $FlashArray -Name $PURE_SNAP_CONFIG.DBData.TargetPurevolName
        
            # Get Serial number of Log disk from the Array
            ((datetimestampFull) + '         - Getting information for ' + $PURE_SNAP_CONFIG.DBLog.TargetPurevolName + ' from the Pure Storrage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $LOGS = Get-PfaVolume -Array $FlashArray -Name $PURE_SNAP_CONFIG.DBLog.TargetPurevolName
        }
        catch {
            ((datetimestampFull) + '         - Could not retrieve information from the Pure Storrage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }

        If ($null -ne $DATA) {
            # Get Data disk number
            $DATADisk = Get-Disk -SerialNumber $DATA.serial
            ((datetimestampFull) + '         - ' + $PURE_SNAP_CONFIG.DBData.TargetPurevolName + ' matches to disk number ' + $DATADisk.DiskNumber + ' on ' + $env:COMPUTERNAME ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        If ($null -ne $LOGS) {
            # Get Log disk number
            $LOGSDisk = Get-Disk -SerialNumber $LOGS.serial
            ((datetimestampFull) + '         - ' + $PURE_SNAP_CONFIG.DBLog.TargetPurevolName + ' matches to disk number ' + $LOGSDisk.DiskNumber + ' on ' + $env:COMPUTERNAME ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        try {
            # Set Data disk offline
            $DATADisk | Set-Disk -IsOffline $true
            ((datetimestampFull) + '         - Offline disk ' + $PURE_SNAP_CONFIG.DBData.TargetPurevolName + ' on disk number ' + $DATADisk.DiskNumber ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            # Set Log disk offline
            $LOGSDisk | Set-Disk -IsOffline $true
            ((datetimestampFull) + '         - Offline disk ' + $PURE_SNAP_CONFIG.DBLog.TargetPurevolName + ' on disk number ' + $LOGSDisk.DiskNumber ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Update-HostStorageCache
            Start-Sleep -Seconds 5
        }
        catch {
            ((datetimestampFull) + '         - Unable to Offline disk ') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        if ((Get-Disk -SerialNumber $DATA.serial).OperationalStatus -ne "Offline") {
            ((datetimestampFull) + '         - ' + $PURE_SNAP_CONFIG.DBData.TargetPurevolName + ' on disk number ' + $DATADisk.DiskNumber + ' is not offline' ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            exit-Execution -returnCode 517 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
        if ((Get-Disk -SerialNumber $LOGSDisk.SerialNumber).OperationalStatus -ne "Offline") {
            ((datetimestampFull) + '         - ' + $PURE_SNAP_CONFIG.DBLog.TargetPurevolName + ' on disk number ' + $LOGSDisk.DiskNumber + ' is not offline' ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            exit-Execution -returnCode 517 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
            
        ((datetimestampFull) + '         - Rescaning VDS') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        Update-HostStorageCache  | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - VDS rescan completed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The Offline of *014BANR disks from clusternode') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # Step 6 - Copy SNAPShot
    ##############################################################################################################################################################################
    $currentStep = 6
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Copy of snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Copy of snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            
        $FlashArray = New-PfaArray -EndPoint $PURE_SNAP_CONFIG.PSArray.HostName -ApiToken $PURE_SNAP_CONFIG.PSArray.APItoken -IgnoreCertificateError
        $Batches = Get-PfaAllVolumeSnapshots -Array $FlashArray | Where-Object { $_.name -like $SNAPString }
        if ($null -ne $Batches) {
            foreach ($Batch in $Batches) {
                if ($Batch.Name -like "*DATA*") {
                    ((datetimestampFull) + '         - Copying ' + $Batch.Name + ' to ' + $PURE_SNAP_CONFIG.DBData.TargetPurevolName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                    New-PfaVolume -Array $FlashArray -Source $Batch.Name -VolumeName $PURE_SNAP_CONFIG.DBData.TargetPurevolName -Overwrite
                }
                if ($Batch.Name -like "*LOGS*") {
                    ((datetimestampFull) + '         - Copying ' + $Batch.Name + ' to ' + $PURE_SNAP_CONFIG.DBLog.TargetPurevolName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                    New-PfaVolume -Array $FlashArray -Source $Batch.Name -VolumeName $PURE_SNAP_CONFIG.DBLog.TargetPurevolName -Overwrite
                }
            }
        }
        else {
            ((datetimestampFull) + '         - Could not find any snapshots') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            "### STEP $currentStep Failed#############################################################################################################################################" | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            exit-Execution -returnCode 518 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile   
        }
        ((datetimestampFull) + '         - Rescaning VDS') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        Update-HostStorageCache  | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - VDS rescan completed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The Copying of the *014BANR disks on clusternode') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force

    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # Step 7 - Online Disks, Relabel NTFS Labels and Mount drives 
    ##############################################################################################################################################################################
    $currentStep = 7
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Rename disk labels and mount disks') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Rename disk labels and mount disks') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        try {
            ((datetimestampFull) + '         - Connecting to the Pure Storage Array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            # Coneect to the Array
            $FlashArray = New-PfaArray -EndPoint $PURE_SNAP_CONFIG.PSArray.HostName -ApiToken $PURE_SNAP_CONFIG.PSArray.APItoken -IgnoreCertificateError
                
            ((datetimestampFull) + '         - Getting necessary variables') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $SourceDBName = $PURE_SNAP_CONFIG.SourceHost.SDBName
            ((datetimestampFull) + '         - Getting Source Database named ' + $SourceDBName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $DestDBName = $PURE_SNAP_CONFIG.SourceHost.DDBName
            ((datetimestampFull) + '         - Getting Destination Database named ' + $DestDBName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                
            # Configuring Data Disk
            $DATA = Get-PfaVolume -Array $FlashArray -Name $PURE_SNAP_CONFIG.DBData.TargetPurevolName
            ((datetimestampFull) + '         - Getting Data disk named ' + $DATA.name + ' from array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $DATADisk = Get-Disk -SerialNumber $DATA.serial
            ((datetimestampFull) + '         - Matching Data disk Serial Number ' + $DATA.serial + ' to disk number ' + $DATADisk.Number) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            # Online Data disk
            if ($DATADisk.OperationalStatus -eq "Offline") {
                ((datetimestampFull) + '         - Online disk ' + $DATA.name ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $DATADisk | Set-Disk -IsOffline $false
                Start-Sleep -Seconds 5
            }
            # Set Disk Read-Only and Shadow Copy to false
            if ($DATADisk.IsReadOnly -eq "true") {
                ((datetimestampFull) + '         - Remove Read-Only from disk ' + $DATA.name ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $DATADisk | Set-Disk -IsReadOnly $false
                Start-Sleep -Seconds 5
                Update-HostStorageCache
                ((datetimestampFull) + '         - VDS rescan completed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
                
            $Partition = Get-Partition -DiskNumber $DATADisk.Number -PartitionNumber 2
            if ( {$Partition.IsReadOnly -eq "True"} -or {$Partition.IsShadowCopy -eq "True"}) {
                $Partition | Set-Partition -IsHidden $false -IsReadOnly $false -IsShadowCopy $false
                ((datetimestampFull) + '         - Setting Data Disk Partition to Read Only and Shadow Copy to False') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }                
            $DataDiskResource = (Get-CimAssociatedInstance -InputObject $DATADisk -ResultClassName MSFT_Partition | Get-Volume)
            $DataDiskResource | Set-Volume -NewFileSystemLabel $DataDiskResource.FileSystemLabel.Replace($SourceDBName, $DestDBName)
            ((datetimestampFull) + '         - Renaming NTFS Label to ' + $DataDiskResource.FileSystemLabel.Replace($SourceDBName, $DestDBName)) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-PartitionAccessPath -DiskNumber $DATADisk.DiskNumber -PartitionNumber 2 -AccessPath $PURE_SNAP_CONFIG.DBData.TargetDriveLetter -ErrorAction Stop
            ((datetimestampFull) + '         - Mapping Data Disk number ' + $DATADisk.DiskNumber + ' to ' + $PURE_SNAP_CONFIG.DBData.TargetDriveLetter ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                
                
            # Configuring Logs Disk
            $LOGS = Get-PfaVolume -Array $FlashArray -Name $PURE_SNAP_CONFIG.DBLog.TargetPurevolName
            ((datetimestampFull) + '         - Getting Logs disk named ' + $LOGS.name + ' from array') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            $LOGSDisk = Get-Disk -SerialNumber $LOGS.serial
            ((datetimestampFull) + '         - Getting Serial Number ' + $LOGS.serial + ' from ' + $LOGS.name + ' disk') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

            # Online Logs disk
            if ($LOGSDisk.OperationalStatus -eq "Offline") {
                ((datetimestampFull) + '         - Online disk ' + $LOGS.name ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $LOGSDisk | Set-Disk -IsOffline $false
                Start-Sleep -Seconds 5
            }
                
            if ($LOGSDisk.IsReadOnly -eq "true") {
                ((datetimestampFull) + '         - Remove Read-Only from disk ' + $LOGS.name ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $LOGSDisk | Set-Disk -IsReadOnly $false
                Start-Sleep -Seconds 5
                Update-HostStorageCache
                ((datetimestampFull) + '         - VDS rescan completed') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            $Partition = Get-Partition -DiskNumber $LOGSDisk.Number -PartitionNumber 2
            if ( {$Partition.IsReadOnly -eq "True"} -or {$Partition.IsShadowCopy -eq "True"}) {
                $Partition | Set-Partition -IsHidden $false -IsReadOnly $false -IsShadowCopy $false
                ((datetimestampFull) + '         - Setting Logs Disk Partition to Read Only and Shadow Copy to False') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }           
            $LogDiskResource = (Get-CimAssociatedInstance -InputObject $LOGSDisk -ResultClassName MSFT_Partition | Get-Volume)
            $LogDiskResource | Set-Volume -NewFileSystemLabel $LogDiskResource.FileSystemLabel.Replace($SourceDBName, $DestDBName)
            ((datetimestampFull) + '         - Renaming NTFS Label to ' + $LogDiskResource.FileSystemLabel.Replace($SourceDBName, $DestDBName)) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            Add-PartitionAccessPath -DiskNumber $LOGSDisk.DiskNumber -PartitionNumber 2 -AccessPath $PURE_SNAP_CONFIG.DBLog.TargetDriveLetter -ErrorAction Stop
            ((datetimestampFull) + '         - Mapping Logs Disk number ' + $LOGSDisk.DiskNumber + ' to ' + $PURE_SNAP_CONFIG.DBLog.TargetDriveLetter ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        }
        catch {
            ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ToString()) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ScriptStackTrace) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].Exception) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            exit-Execution -returnCode 600 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
            
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The renaming of disk labels and mounting *014BANR disks on clusternode') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # STEP 8 - Rename DB Files
    ##############################################################################################################################################################################
    $currentStep = 8
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Renaming *014BANR database files') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Renaming *014BANR database files') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            
            
        $DFiles = $null
        $DFiles = Get-ChildItem -Path $PURE_SNAP_CONFIG.DBData.TargetDriveLetter -Filter "*df" -Recurse
        $DFiles += Get-ChildItem -Path $PURE_SNAP_CONFIG.DBLog.TargetDriveLetter -Filter "*df" -Recurse
        $SourceDBName = $PURE_SNAP_CONFIG.SourceHost.SDBName
        $DestDBName = $PURE_SNAP_CONFIG.SourceHost.DDBName

        if ($DFiles.Count -eq '10') {
            foreach ($file in $DFiles) {
                $newDBName = $file.Fullname.Replace($SourceDBName, $DestDBName)
                Rename-Item -Path $file.Fullname -NewName $newDBName 
                ((datetimestampFull) + '         - Renaming ' + $file.Name + ' to ' + $newDBName ) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
        }
        else {
            ((datetimestampFull) + '         - Could not find 10 DB files to rename') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            exit-Execution -returnCode 602 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile     
        }

        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The rename DB file names on clusternode') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        if (!($Scheduler)) {
            $startAtStep++
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # STEP 9 - Attach DB
    ##############################################################################################################################################################################
    $currentStep = 9
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Attach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Attach *014BANR database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        #get the copy paths
        $copyDataPath = $PURE_SNAP_CONFIG.DBData.TargetDriveLetter
        $copyLogsPath = $PURE_SNAP_CONFIG.DBLog.TargetDriveLetter
        
        #temporary file 
        $tmpFile = ([System.IO.Path]::GetRandomFileName())
        $outputFile = ('C:\Temp\' + $tmpFile)
        
        #attach the database
        $SQLServer = $PURE_SNAP_CONFIG.SourceHost.HostName
        $sqlDatabaseCopyName = $PURE_SNAP_CONFIG.SourceHost.DDBName

        #get all the database files
        ((datetimestampFull) + '         - Obtaining database files') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        $DBFiles = Get-ChildItem -Path $copyDataPath -Filter "*df" -Recurse
        $DBFiles += Get-ChildItem -Path $copyLogsPath -Filter "*df" -Recurse
        
        ((datetimestampFull) + '         - Building command used to attached the database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        $filesToAttach = ''
        $i = 1
        #build the attach string for all the database files
        foreach ($file in $DBFiles) {
            $sqlQueryFileName = ('FileName' + $i)
            $i++
            $filesToAttach += (", @" + $sqlQueryFileName + " = N'" + $file.Fullname + "'")
        }
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        #sqlcmd Parameters
        ((datetimestampFull) + '         - Starting the attach') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - sqlcmd.exe parameters:') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('-b', ('-S ' + $SQLServer), '-E', '-d master', ('-Q "IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = ' + "'$sqlDatabaseCopyName') exec sp_attach_db @dbname = [$sqlDatabaseCopyName] $filesToAttach" + '"')) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        #start the process
        $process = (Start-Process sqlcmd.exe -ArgumentList ('-b', ('-S ' + $SQLServer), '-E', '-d master', ('-Q "IF NOT EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = ' + "'$sqlDatabaseCopyName') exec sp_attach_db @dbname = [$sqlDatabaseCopyName] $filesToAttach" + '"')) -Wait -PassThru -RedirectStandardOutput $outputFile -WindowStyle Hidden)

        #obtain process output
        $stdOutputData = get-content -path $outputFile
        ((datetimestampFull) + $stdOutputData) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                
        #cleanup
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        $returnCode = $process.ExitCode

        if (($returnCode -gt $successCode) -or ($returnCode -lt $successCode)) {
            if ($Scheduler) {
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - An error occurred (error code: ' + $returnCode + ') while attempting to attach the database') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - Investigate and ONLY once the problem has been resolved, continue ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $end = (get-date)
                ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            exit-Execution -returnCode $returnCode -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
        else {
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED Attaching Database "' + $PURE_SNAP_CONFIG.SourceHost.DDBName + '"  to ' + $PURE_SNAP_CONFIG.SourceHost.HostName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            if (!($Scheduler)) {
                $startAtStep++
            }
            $end = (get-date)
            ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force  
        }
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # STEP 10 - Change Db owner
    ##############################################################################################################################################################################
    $currentStep = 10
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Change *014BANR database owner') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Change *014BANR database owner') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        $SQLServer = $PURE_SNAP_CONFIG.SourceHost.HostName
        $sqlDatabaseCopyName = $PURE_SNAP_CONFIG.SourceHost.DDBName
        $sqlDatabaseOwner = $PURE_SNAP_CONFIG.SourceHost.DBOwner
        
        #temporary file 
        $tmpFile = ([System.IO.Path]::GetRandomFileName())
        $outputFile = ('C:\Temp\' + $tmpFile)
        
        #cleanup previous output
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        
        #sqlcmd Parameters
        ((datetimestampFull) + '         - sqlcmd.exe parameters:') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('-b', ('-S ' + $SQLServer), '-E', ('-d ' + $sqlDatabaseCopyName), ('-Q "exec sp_changedbowner @loginame = ' + "'" + $sqlDatabaseOwner + "'" + '"')) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        #start the process
        ((datetimestampFull) + '         - Changing the database owner') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        $process = (Start-Process sqlcmd.exe -ArgumentList ('-b', ('-S ' + $SQLServer), '-E', ('-d ' + $sqlDatabaseCopyName), ('-Q "exec sp_changedbowner @loginame = ' + "'" + $sqlDatabaseOwner + "'" + '"')) -Wait -PassThru -RedirectStandardOutput $outputFile -WindowStyle Hidden)
        
        #obtain process output
        $stdOutputData = get-content -path $outputFile
        ($stdOutputData) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        #cleanup
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        $returnCode = $process.ExitCode
        if (($returnCode -gt $successCode) -or ($returnCode -lt $successCode)) {
            if ($Scheduler) {
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - An error occurred (error code: ' + $returnCode + ') while attempting to change the database owner') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - Investigate and ONLY once the problem has been resolved, continue ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $end = (get-date)
                ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            exit-Execution -returnCode $returnCode -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
        else {
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED Changing the owner of Database "' + $PURE_SNAP_CONFIG.SourceHost.DDBName + '"  to ' + $PURE_SNAP_CONFIG.SourceHost.HostName) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            if (!($Scheduler)) {
                $startAtStep++
            }
        }
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force  
    }
    $nextStart = Get-Date

    ##############################################################################################################################################################################
    # STEP 11 - Change Recovery model
    ##############################################################################################################################################################################
    $currentStep = 11
    stop-Or-Continue-Execution -stopAtStartOfStep $stopAtStartOfStep -startAtStep $startAtStep -start $start -currentStep $currentStep -logFile $logFile -Scheduler $Scheduler -exitCodeFile $exitCodeFile
    if ($startAtStep -eq $currentStep) {
        ((datetimestampFull) + ' - STEP      - ' + $startAtStep + ' - Set Simple Recovery Model') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - INFO      - Account used for execution of script: ' + $userAccount.ToUpper() + ' from ' + $env:COMPUTERNAME) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + ' - CONTINUEING WITH STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - Changing *014BANR database recovery model') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force

        $SQLServer = $PURE_SNAP_CONFIG.SourceHost.HostName
        $sqlDatabaseCopyName = $PURE_SNAP_CONFIG.SourceHost.DDBName

        #temporary file 
        $tmpFile = ([System.IO.Path]::GetRandomFileName())
        $outputFile = ('C:\Temp\' + $tmpFile)
        
        #cleanup previous output
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        
        #sqlcmd Parameters
        ((datetimestampFull) + '         - Set Simple Recovery Model') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ((datetimestampFull) + '         - sqlcmd.exe parameters:') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ('-b', ('-S ' + $SQLServer), '-E', ('-d master'), ('-Q "ALTER DATABASE ' + $sqlDatabaseCopyName + ' SET RECOVERY SIMPLE ;"')) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        
        #start the process   
        $process = (Start-Process sqlcmd.exe -ArgumentList ('-b', ('-S ' + $SQLServer), '-E', ('-d master'), ('-Q "ALTER DATABASE ' + $sqlDatabaseCopyName + ' SET RECOVERY SIMPLE ;"')) -Wait -PassThru -RedirectStandardOutput $outputFile -WindowStyle Hidden)
        
        #obtain process output
        $stdOutputData = get-content -path $outputFile
        ($stdOutputData) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        #cleanup
        if (test-path $outputFile) {
            remove-item -path $outputFile -force
        }
        $returnCode = $process.ExitCode
        if (($returnCode -gt $successCode) -or ($returnCode -lt $successCode)) {
            if ($Scheduler) {
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - An error occurred (error code: ' + $returnCode + ') while attempting to set Simple Recovery Model') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ((datetimestampFull) + ' - ERROR     - Investigate and ONLY once the problem has been resolved, continue ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                $end = (get-date)
                ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
                ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            }
            exit-Execution -returnCode $returnCode -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
        }
        else {
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED The change of the Recovery Model for database ' + $PURE_SNAP_CONFIG.SourceHost.DDBName + ' on ' + $PURE_SNAP_CONFIG.SourceHost.HostName + ' successfully changed to SIMPLE MODE') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ((datetimestampFull) + ' - SUCCESSFULLY COMPLETED STEP - ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
            if (!($Scheduler)) {
                $startAtStep++
            }
        }
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force
        $end = (get-date)
        ('************ Process duration (seconds): ' + ($end - $nextStart).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
        ($successCode) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Force  
    }
    $end = (get-date)
    ('************ TOTAL duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
}
catch {
    #catch any exceptions that occurred in the script
    $end = (get-date)
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - An exception was caught during the execution of the script') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - Script failed during the execution of step ' + $startAtStep) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ToString()) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - EXCEPTION - ' + $error[0].ScriptStackTrace) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ((datetimestampFull) + ' - END       - Process duration (seconds): ' + ($end - $start).TotalSeconds) | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('************************************************************************************************') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    ('######################################################################################################################################################') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    if ($Scheduler) {
        (501) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Append -Force
        ('ERROR CODE RETURNED: 501') | Out-File -FilePath $logFile -Encoding ASCII -Append -Force
    }
    #(501) | Out-File -FilePath $exitCodeFile -Encoding ASCII -Append -Force
    exit-Execution -returnCode 501 -startAtStep $startAtStep -logFile $logFile -exitCodeFile $exitCodeFile
}
###########################################################