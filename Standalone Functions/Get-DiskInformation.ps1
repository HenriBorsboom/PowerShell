Function Get-Disks {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $Server)
    $WMIQuery = "Select Caption,Size,VolumeName from Win32_LogicalDisk Where DriveType = 3"
    Try { 
        If ($Server -eq $env:COMPUTERNAME) { $WMIResults = Get-WmiObject -Query $WMIQuery }
        Else                               { $WMIResults = Get-WmiObject -Query $WMIQuery -ComputerName $Server }
        
        Return $WMIResults
    }
    Catch { Return $false }
}
Function New-HTML {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $InputObject, `
        [Parameter(Mandatory=$true, Position=2)]
        [Object] $OutputFile, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $Launch, `
        [Parameter(Mandatory=$false, Position=4)]
        [Switch] $Overwrite)
    
    $HTMLHeader="<html>                                                               
                <style>                                               
                BODY{font-family: Arial; font-size: 8pt;}
                H1{font-size: 16px;}
                H2{font-size: 14px;}
                H3{font-size: 12px;}
                TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
                TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
                TD{border: 1px solid black; padding: 5px; }
                td.pass{background: #7FFF00;}
                td.warn{background: #FFE600;}
                td.fail{background: #FF0000; color: #ffffff;}
                </style>
                <body>
                <h1 align=""center"">Network Details</h1>
                <h2 align=""center""></h2>"
    $HTMLBody = "<H2>Network Details</H2>"

    $HTMLOutput = $InputObject | ConvertTo-HTML -Head $HTMLHeader -Body $HTMLBody
    Switch ($Overwrite) {
        $true  { If ((Get-ChildItem $OutputFile) -eq $true) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue } $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
        $False { $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
    }
    Switch ($Launch) {
        $true { Invoke-Expression $OutputFile }
    }
}
Clear-Host
$ErrorActionPreference = "SilentlyContinue"
$NICDetails = @()
$OutputFile = "C:\temp\test.htm"

$DisksDetails = @()
$Server = $env:COMPUTERNAME
$Disks = Get-Disks -Server $Server

ForEach ($Disk in $Disks) {
    $DiskDetails = New-Object PSObject -Property @{
        Server      = $Server
        DriveLetter = $Disk.Caption
        Size        = [Math]::Round($Disk.Size/1024/1024/1024)
        VolumeName  = $Disk.VolumeName
    }
    $DisksDetails += $DiskDetails
}
New-HTML -InputObject $DisksDetails -OutputFile $OutputFile -Launch -Overwrite
$DisksDetails