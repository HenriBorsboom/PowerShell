Function Write-Color {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param(
        [Parameter(Mandatory=$True, Position=1,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$True, Position=1,ParameterSetName='Tab')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Tab')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position=3,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Tab')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Complete')]
        [Switch] $Complete, `
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=4,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=2,ParameterSetName='Complete')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Normal')]
	    [Parameter(Mandatory=$False, Position=8,ParameterSetName='Tab')]
	    [Parameter(Mandatory=$False, Position=3,ParameterSetName='Complete')]
        [String] $LogFile = "", `
	    [Parameter(Mandatory=$False, Position=5,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=4,ParameterSetName='Complete')]
        [Int16] $StartTab = 0, `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=5,ParameterSetName='Complete')]
        [Int16] $LinesBefore = 0, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Complete')]
        [Int16] $LinesAfter = 0, `
        [Parameter(Mandatory=$False, Position=9,ParameterSetName='Tab')]
        [String] $TimeFormat = "yyyy-MM-dd HH:mm:ss", `
        [Parameter(Mandatory=$False, Position=6,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=10,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=1,ParameterSetName='Counter')]
        [Int64] $IndexCounter, `
        [Parameter(Mandatory=$False, Position=7,ParameterSetName='Normal')]
        [Parameter(Mandatory=$False, Position=11,ParameterSetName='Tab')]
        [Parameter(Mandatory=$False, Position=2,ParameterSetName='Counter')]
        [Int64] $TotalCounter)

    Begin {
        $CurrentActionPreference = $ErrorActionPreference;
        $ErrorActionPreference = 'Stop'

        If ($Text.Count -gt 0) {
            If ($BackgroundColor.Count -eq 0 -and $ForegroundColor.Count -eq 0) { $OperationMode = 'WriteHost' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -eq 0) { $OperationMode = 'SingleBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -eq 0) { $OperationMode = 'SingleForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count -and $ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleForegroundBackground' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count -and $BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -lt $Text.Count) { $OperationMode = 'SingleBackgroundForeground' }
            ElseIf ($BackgroundColor.Count -gt 0 -and $BackgroundColor.Count -ge $Text.Count -or $ForegroundColor.Count -eq 0) { $OperationMode = 'Background' }
            ElseIf ($ForegroundColor.Count -gt 0 -and $ForegroundColor.Count -ge $Text.Count -or $BackgroundColor.Count -eq 0) { $OperationMode = 'Foreground' }
            ElseIf ($BackgroundColor.Count -eq $Text.Count -and $ForegroundColor.Count -eq $Text.Count) { $OperationMode = 'Normal' }
            Else { Throw }
        }
        If ($Complete -eq $True) { $OperationMode = 'Complete' }
    }
    Process {
        If ($LinesBefore -ne 0) { For ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
        If ($StartTab -ne 0) { For ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine } }
        If ($TotalCounter -gt 0 -and $IndexCounter -ge 0) {
            $CounterLength = $TotalCounter.ToString().Length
            Write-Host ("[" + ("{0:D$CounterLength}" -f ($IndexCounter + 1) + "/" + $TotalCounter) + "] ") -ForegroundColor DarkCyan -NoNewline
        }
        If ($OperationMode -eq 'WriteHost') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Foreground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Background') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'SingleForegroundBackground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[0] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'SingleBackgroundForeground') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[0] -NoNewLine } }
        If ($OperationMode -eq 'Normal') { For ($Index = 0; $Index -lt $Text.Length; $Index ++) { Write-Host $Text[$Index] -ForegroundColor $ForegroundColor[$Index] -BackgroundColor $BackgroundColor[$Index] -NoNewLine } }
        If ($OperationMode -eq 'Complete') { Write-Host 'Complete' -ForegroundColor Green -NoNewLine }
        If ($LinesAfter -ne 0) { For ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    }
    End {
        If ($NoNewLine -eq $False) { Write-Host } Else { }
        If ($LogFile -ne "") {
            $TextToFile = ""
            For ($i = 0; $i -lt $Text.Length; $i++) {
                $TextToFile += $Text[$i]
            }
            Write-Output "[$([datetime]::Now.ToString($TimeFormat))] $TextToFile" | Out-File $LogFile -Encoding unicode -Append
        }
        $ErrorActionPreference = $CurrentActionPreference
    }
}
Function Export-RVTools {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Object] $vCenter, `
        [Parameter(Mandatory=$False, Position=2)]
        [Switch] $BuildMasterList)
    Write-Color -IndexCounter $i -TotalCounter $vCenters.Count -Text "Initiating RV Tools for ", $vCenters[$i].Name, " - " -ForegroundColor White, Yellow, White -NoNewLine
    If ($BuildMasterList -eq $False) {
        $AttachmentFile = ($vCenters[$i].Name + '{0:yyyy-MM-dd}' -f (Get-Date))
        Start-Process -FilePath 'C:\Temp\VMWare\RVTools\RVTools.exe' -ArgumentList "-u", $vCenters[$i].Username, "-p", $vCenters[$i].Password, "-s", $vCenters[$i].Name, "-c", "ExportAll2xls", "-d", "$AttachmentDir", "-f", """$AttachmentFile""" -Wait
    }
    ElseIf ($BuildMasterList -eq $True) {
        $AttachmentFile = ($vCenters[$i].Name + ' (vInfo) - ' + '{0:yyyy-MM-dd}' -f (Get-Date))
        Start-Process -FilePath 'C:\Temp\VMWare\RVTools\RVTools.exe' -ArgumentList "-u", $vCenters[$i].Username, "-p", $vCenters[$i].Password, "-s", $vCenters[$i].Name, "-c", "ExportvInfo2csv", "-d", "$AttachmentDir", "-f", """$AttachmentFile""" -Wait
        $VMInfo = Import-CSV ($AttachmentDir + '\' + $AttachmentFile + '.csv')
        Write-Color -Text "Adding ", $VMInfo.Count, " VMs to Master List - " -ForegroundColor White, Yellow, White -NoNewLine
        ForEach ($VM in $VMInfo) {
            $VM | Add-Member -NotePropertyName 'vCenter Name' -NotePropertyValue $vCenters[$i].Name
            $Global:MasterList += ,($VM | Select $Properties)
        }
    }
    Write-Color -Complete
}
$Password = 'P@ssw0rd$1234'
$vCenters = @()
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.1.238.11' #'Alpine'
    Username = 'root'
    Password = 'Fro0ple.'
}) # Alpine
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.10.180.35' #'Amethyst1'
    Username = 'eohcorp\hboadm'
    Password = $Password
}) # Amethyst1
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.1.207.11' #'AutoSpec'
    Username = 'root'
    Password = 'Fro0ple'
}) # AutoSpec
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.10.4.100' #'Gilloolys'
    Username = 'eohcorp\hboadm'
    Password = $Password
}) # Gilloolys
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.12.5.230' #'Terraco'
    Username = 'eohcorp\hboadm'
    Password = $Password
}) # Terraco
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.1.169.5'
    Username = 'root'
    Password = 'Passw00rd'
}) # 10.1.169.5 eohhealthesxi2
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.1.172.11'
    Username = 'root'
    Password = 'Passw00rd'
}) # 10.1.172.11
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.2.20.11'
    Username = 'root'
    Password = 'Fro0ple'
}) # 10.2.20.11
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.3.4.15'
    Username = 'root'
    Password = 'Passw00rd'
}) # 10.3.4.15
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = '10.2.9.2'
    Username = 'root'
    Password = 'Passw00rd'
}) # 10.2.9.2 # eohkznhost1
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = 'IMSSD-VC01V'
    Username = 'eohcorp\hboadm'
    Password = $Password
}) # IMSSD-VC01V
<# Empty
$vCenters += (New-Object -TypeName PSObject -Property @{
    Name     = ''
    Username = ''
    Password = ''
}) # 
#>

$Properties = @(
    'VM'
    'PowerState'
    'Config status'
    'DNS Name'
    'Guest state'
    'vCenter UUID'
    'vCenter Name'
)

$AttachmentDir = 'C:\Temp\VMWare'
#$MasterListFile = 'C:\Temp\VMWare\MasterList.csv'
Clear-Host
#$Global:MasterList = @()
For ($i = 0; $i -lt $vCenters.Count; $i++) {
    Export-RVTools -vCenter $vCenters[$i].Name
}
#$Global:MasterList | Select $Properties | Format-Table -AutoSize
#$Global:MasterList | Select $Properties | Export-Csv $MasterListFile -NoTypeInformation -Encoding ASCII -Force
