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
Function Watch-URL {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $LogFile, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $URL, `
        [Parameter(Mandatory=$True, Position=3)]
        [String] $Name)
        
    Try {
        $URLCode = Invoke-WebRequest -Uri $URL -ErrorAction Stop
        If ($URLCode.StatusCode -eq 200 -or $URLCode.StatusCode -eq 404) { 
            Write-Log -LogFile $LogFile -Level Info -Component $MyInvocation.MyCommand.Name -Message ($Name + ' Status Code: ' + $URLCode.StatusCode.ToString() + "`n" + "URL: " + $URL + "`n" + "Source: " + $env:COMPUTERNAME) 
            Write-Host ((Get-Date).ToString('yyyy/MM/dd HH:mm:ss')+ ' ' + $Name + ' Status Code: ' + $URLCode.StatusCode + " - " + "URL: " + $URL + " - " + "Source: " + $env:COMPUTERNAME)
            }
        Else { 
            Write-Log -LogFile $LogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($Name + ' Status Code: ' + $URLCode.StatusCode.ToString() + "`n" + "URL: " + $URL + "`n" + "Source: " + $env:COMPUTERNAME)  }
    }
    Catch {
        Write-Host ((Get-Date).ToString('yyyy/MM/dd HH:mm:ss')+ ' ' + $Name + ' Error Code: ' + $_ + " - " + "URL: " + $URL + " - " + "Source: " + $env:COMPUTERNAME) -ForegroundColor Red
        Write-Log -LogFile $LogFile -Level Error -Component $MyInvocation.MyCommand.Name -Message ($Name + ' Error: ' + $_ + "`n" + "URL: " + $URL + "`n" + "Source: " + $env:COMPUTERNAME)
    }
}

#SigniFlow
$SigniFlowSignFile = 'C:\Temp\SignFlow_EasiSign.log'
$SigniFlowURL = 'https://easisign.mercantile.co.za/home'

$SIGNAPPRD01 = 'C:\Temp\SignFlow_SIGNAPPRD01.log'
$SIGNAPPRD01URL = 'https://signwebprd01.mercantile.co.za/home'

#OnBase
$OnBaseLBFile = 'C:\Temp\OnBase_OnbaseLB.log'
$OnBaseLBURL = 'https://onbaselb.mercantile.co.za/AppServer/service.asmx'

$HONAPPRD04File = 'C:\Temp\OnBase_HONAPPRD04.log'
$HONAPPRD04URL = 'https://honapprd04.mercantile.co.za/AppServer/service.asmx'

$HONAPPRD05File = 'C:\Temp\OnBase_HONAPPRD05.log'
$HONAPPRD05URL = 'https://honapprd05.mercantile.co.za/AppServer/service.asmx'

While ($True) {
    Write-Host "--------------------------------------------------------------------"
    Watch-URL -LogFile $SigniFlowSignFile -URL $SigniFlowURL -Name "Easysign"
    Watch-URL -LogFile $SIGNAPPRD01 -URL $SIGNAPPRD01URL -Name "EasySign - SIGNWEBPRD01"

    Watch-URL -LogFile $OnBaseLBFile -URL $OnBaseLBURL -Name "OnBaseLB"
    Watch-URL -LogFile $HONAPPRD04File -URL $HONAPPRD04URL -Name "OnBaseLB - HONAPPRD04"
    Watch-URL -LogFile $HONAPPRD05File -URL $HONAPPRD05URL -Name "OnBaseLB - HONAPPRD05"
    Write-Host "Sleeping for 5 seconds"
    Write-Host "--------------------------------------------------------------------"
    Write-Host ""
    Start-Sleep -Seconds 5
}