$ErrorActionPreference = 'Stop'
Function Write-log {
    [CmdletBinding()]
    Param(
            [parameter(Mandatory=$true, Position=1)][AllowEmptyString()]
            [String]$Logfile,
            [parameter(Mandatory=$true, Position=2)][AllowEmptyString()]
            [String]$Message,
            [parameter(Mandatory=$true, Position=3)][AllowEmptyString()]
            [String]$Component,
            [Parameter(Mandatory=$true,Position=4)][ValidateSet("Info", "Warning", "Error")]
            [String]$Level
    )
    
    If ($null -eq $Component) { $Level = "Error"}
    Try {    
        switch ($Level) {
            "Info" { [int]$Level = 1 }
            "Warning" { [int]$Level = 2 }
            "Error" { [int]$Level = 3 }
        }
        
        # Create a log entry
        $Content = "<![LOG[$Message]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Level`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"
        
        # Write the line to the log file
        Add-Content -Path $Logfile -Value $Content
        Start-Sleep -Milliseconds 50
    }
    Catch {
        switch ($Level) {
            "Info" { [int]$Level = 1 }
            "Warning" { [int]$Level = 2 }
            "Error" { [int]$Level = 3 }
        }
        $Component = 'Error'
        # Create a log entry
        $Content = "<![LOG[$Message]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"$Level`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"
        
        # Write the line to the log file
        
        Add-Content -Path ($Logfile + '_Loggingerror.log') -Value $Content
        $Content = "<![LOG[$_]LOG]!>" +`
            "<time=`"$(Get-Date -Format "HH:mm:ss.ffffff")`" " +`
            "date=`"$(Get-Date -Format "M-d-yyyy")`" " +`
            "component=`"$Component`" " +`
            "context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" " +`
            "type=`"3`" " +`
            "thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" " +`
            "file=`"`">"
        Add-Content -Path ($Logfile + '_Loggingerror.log') -Value $Content
    }
}

#$Path = 'E:\'
#Set-Location $Path
#$Files = Get-ChildItem -Path $Path -Recurse | Where Mode -like '*l*'
$LogFile = ('C:\Temp\Commvault_Restore_' + $env:COMPUTERNAME + '_' + (Get-Date -Format "HH_mm_ss") + '.log')
$ACLFile = 'E:\Temp\emptyacl.txt'
Write-log -Logfile $LogFile -Message "Getting ACL of $ACLFile" -Component 'Main' -Level Info
Write-Host "Getting ACL of $ACLFile"
$ACL = Get-Acl $ACLFile
$RestorePath = 'D:\Temp\CommVault\E\Users\LMaritz'
$TargetPath = 'E:\Users\LMaritz'
Write-log -Logfile $LogFile -Message "Getting Restore files from $RestorePath" -Component 'Main' -Level Info
Write-Host "Getting Restore files from $RestorePath"

$i = 0
Get-ChildItem -Path $TargetPath -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object {
    #Write-log -Logfile $LogFile -Message ("Files found under $RestorePath : " + $RestoreFiles.Count.ToString()) -Component 'Main' -Level Info
    #Write-Host ("Files found under $RestorePath : " + $RestoreFiles.Count.ToString())

    If ($_.FullName -like '*$RECYCLE.BIN*') {
        #Write-log -Logfile $LogFile -Message ("Skipping Recycle Bin file: " + $_.FullName) -Component 'ForLoop' -Level Info
        #Write-Host ("Skipping Recycle Bin file: " + $_.FullName)
       }
    Else {
        Try {
            If ($_.Mode.Contains('l')) {
                Write-Host (($i + 1).ToString() + ' - Processing ' + $_.FullName)
                $TargetFile = $_.FullName.Replace('E:', 'D:\Temp\CommVault\E')
                #Write-log -Logfile $LogFile -Message "Target File Path: $TargetFile" -Component 'ForLoop' -Level Info
                Write-Host "| Source File Path: $TargetFile"
                If (Test-Path -LiteralPath $TargetFile) {
                    #Write-log -Logfile $LogFile -Message "$TargetFile exists" -Component 'ForLoop' -Level Info
                    #Write-Host "| $TargetFile exists"
                    #Write-log -Logfile $LogFile -Message "$TargetFile is archived." -Component 'ForLoop' -Level Info
                    #Write-Host "| $TargetFile is archived."
                    Set-ACL $_.FullName -AclObject $ACL
                    #Write-log -Logfile $LogFile -Message ($_.FullName + " ACL changed to reference ACL file") -Component 'ForLoop' -Level Info
                    #Write-Host ("| " + $_.FullName + " ACL changed to reference ACL file") -ForegroundColor Green
                    Set-ACL $TargetFile -AclObject $ACL
                    Write-log -Logfile $LogFile -Message ($TargetFile + " ACL changed to reference ACL file") -Component 'ForLoop' -Level Info
                    Write-Host ("| " + $TargetFile + " ACL changed to reference ACL file") -ForegroundColor Green
                    Copy-Item -Path $TargetFile -Destination $_.FullName
                    Write-log -Logfile $LogFile -Message ($_.Fullame + " copied to " + $TargetFile) -Component 'ForLoop' -Level Info
                    Write-Host ("| " + $TargetFile + " copied to " + $_.Fullname) -ForegroundColor Green
                    $_.Attributes = 'Normal'
                    Write-log -Logfile $LogFile -Message ("Reset " + $_.BaseName + " attributes to normal") -Component 'ForLoop' -Level Info
                    Write-Host ("Reset " + $_.BaseName + " attributes to normal") -ForegroundColor Green
                    
                }
                Else {
                    Write-log -Logfile $LogFile -Message ($TargetFile + " does not exist in the restored folders") -Component 'ForLoop' -Level Warning
                    Write-Host ("| " + $TargetFile + " does not exist in the restored folders") -ForegroundColor Yellow
                }
            }
        }
        Catch {
            Write-log -Logfile $LogFile -Message ($_) -Component 'ForLoop' -Level Error
            Write-Host ("| " + $_) -ForegroundColor Red
        }
        $i ++
        $TargetFile = $null
    }
}