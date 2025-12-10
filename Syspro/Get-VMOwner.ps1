Param (
    [Parameter(Mandatory=$True, Position=0)]
    [String] $Device)

Function Write-Color {
    Param(
        [Parameter(Mandatory = $True  , Position = 1)]
        [String[]]       $Text, `
        [Parameter(Mandatory = $True  , Position = 2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory = $False , Position = 3)]
        [Switch]           $NoNewLine)

    $ErrorActionPreference = "Stop"
    Try {
        If ($Text.Count -ne $Color.Count) {
            Write-Host ("Text Count, " + $Text.Count.ToString() + ", does not match Color Count, " + $Color.Count.ToString()) -ForegroundColor Red
            Throw
        }
        For ($Index = 0; $Index -lt $Text.Length; $Index ++) {
            Write-Host $Text[$Index] -Foreground $Color[$Index] -NoNewLine
        }
        Switch ($NoNewLine){
            $True  { Write-Host -NoNewline }
            $False { Write-Host }
        }
    }
    Catch { }
}
Function SCVMM {
    Param
        ($ComputerName)

    #Write-Color -Text "------------------------------------ ", "VMM Details", " ------------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "------------------------------------ " -ForegroundColor Cyan -NoNewline
    #Write-Host "VMM Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " ------------------------------------" -ForegroundColor Cyan
    
    Try {
    Import-Module VirtualMachineManager

    $SelectDetails = @("Name", "ComputerName", "Owner", "UserRole", "Description", "Cloud", "VirtualMachineState", "VMHost", "MostRecentTaskIfLocal")
    $VMDetails = Get-SCVirtualMachine | Where-Object {$_.ComputerName -like "*$ComputerName*"}
    $VMMDetails = $VMDetails | Select $SelectDetails | Format-Table -AutoSize
    Return $VMMDetails
    }
    Catch {
        Write-Color "Failed - ", $_ -Color Red, Red
    }
}
Function Users {
    Param
        ($Server)

    #Write-Color -Text "----------------------------------- ", "User Details", " ------------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "------------------------------------ " -ForegroundColor Cyan -NoNewline
    #Write-Host "User Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " -----------------------------------" -ForegroundColor Cyan
    Try {
    $Users = Get-ChildItem -Path ("\\" + $Server + "\C$\Users") # | Select BaseName, LastAccessTime, CreationTime, FullName
    $UsersDetails = $Users | Sort LastAccessTime  -Descending | Select BaseName, LastAccessTime, CreationTime, FullName -First 10
    
    Return $UsersDetails
    }
    Catch {
        Write-Color "Failed" -Color Red
        Return $False
    }
}
Function InstallDate {
    Param 
        ($Computer)

    #Write-Color -Text "---------------------------------- ", "Install Details", " -----------------------------------" -Color Cyan, Yellow, Cyan
    #Write-Host "----------------------------------- " -ForegroundColor Cyan -NoNewline
    #Write-Host "Install Details" -ForegroundColor Yellow -NoNewline
    #Write-Host " ----------------------------------" -ForegroundColor Cyan
    
    Try {
    $Installed = Get-WmiObject -class Win32_OperatingSystem -ComputerName $Computer -Property InstallDate | Select-Object @{label='InstallDate';expression={$_.ConvertToDateTime($_.InstallDate)}}
 
    Return $Installed
    }
    Catch {
        Write-Color "Failed" -Color Red
        Return $False
    }
}

Clear-Host
If (Test-Path C:\Temp\VMInfo\$Device.txt) {
    Write-Color "Retrieved ", $Device, " from ", "C:\Temp\VMInfo\$Device.txt" -Color White, Yellow, White, Yellow
    Get-Content C:\Temp\VMInfo\$Device.txt
}
Else {
    $SCVMM = $Device
    $Users = $Device
    $Install = $Device

    $Info = @()
    $UsersInfo = Users -Server $Users
    $SCVMMInfo = SCVMM -ComputerName $SCVMM
    $InstallDateInfo = InstallDate -Computer $Install
    $Info = $Info + $UsersInfo
    $Info = $Info + $SCVMMInfo
    $Info = $Info + $InstallDateInfo

    $Info
    $Info | Out-File C:\Temp\VMInfo\$Device.txt
}