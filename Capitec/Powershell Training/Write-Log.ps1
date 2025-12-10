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