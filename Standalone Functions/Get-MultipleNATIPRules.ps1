Function New-HTML {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $InputObject, `
        [Parameter(Mandatory=$true, Position=1)]
        [String] $NATRule, `
        [Parameter(Mandatory=$true, Position=2)]
        [Object] $OutputFile, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $Launch, `
        [Parameter(Mandatory=$false, Position=4)]
        [Switch] $Overwrite)
        $ReportTime = (Get-Date).ToLongTimeString() + " - " + (Get-Date).ToShortDateString()
        $HTMLOutput ="<html>                                                               
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
                    <h1 align=""center"">Windows Gateway Server: $env:COMPUTERNAME</h1>
                    <h1 align=""center"">NAT Rule: $NATRule</h1>"
        $HTMLOutput += "<h2 align=""center"">Rules</h2>"
        $HTMLOutput += "<h1 align=""center"">Report Time: $ReportTime</h1>"
        $HTMLOutput += $InputObject | ConvertTo-HTML -Fragment
    Switch ($Overwrite) {
        $true  { If ((Get-ChildItem $OutputFile -ErrorAction SilentlyContinue) -eq $true) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue } $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
        $False { $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
    }
    Switch ($Launch) {
        $true { Start-Process $OutputFile }
    }
}
Function Write-Color {
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true, Position=2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "The amount of Text variables and the amount of color variables does not match" -ForegroundColor Red
        Write-Host "Text Variables:  " -NoNewline
        Write-Host $Text.Count -ForegroundColor Yellow -NoNewline
        Write-Host " - Color Variables: " -NoNewline
        Write-Host $Color.Length -ForegroundColor Yellow
        Break
    }
    Else {
        For ($TextArrayIndex = 0; $TextArrayIndex -lt $Text.Length; $TextArrayIndex ++) {
            Write-Host $Text[$TextArrayIndex] -Foreground $Color[$TextArrayIndex] -NoNewLine
        }
        Switch ($EndLine) {
            $true  { Write-Host }
            $false { Write-Host -NoNewline}
        }
    }
}
Function Get-TimeStampOutputFile {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $TargetLocation, `
        [Parameter(Mandatory=$true, Position=2)]
        [String] $Extension, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $VariableName, `
        [Parameter(Mandatory=$false, Position=4)]
        [String] $Name)

    Switch ($VariableName) {
        $True  { $OutputFile = $TargetLocation + "\" + $Name + " - " + $([DateTime]::Now.ToString('HH.mm.ss-dd-MM-yyyy')) + $Extension }
        $False { $OutputFile = $TargetLocation + " - " + $([DateTime]::Now.ToString('HH.mm.ss-dd-MM-yyyy')) + $Extension }
    }
    Return $OutputFile
}
Function Start-MultiThreadJob {
    Param (
        [Parameter(Mandatory=$true,Position=1)]
        [String] $JobName, `
        [Parameter(Mandatory=$true,Position=2)]
        [String[]] $ScriptBlock)
    $SleepTimer = 1
    $GetChildItemJob = Start-Job -Name $JobName -ArgumentList $ScriptBlock -ScriptBlock {Param($Script); Invoke-Expression $Script} -ErrorAction Stop
    $GetChildItemJobState = Get-Job $GetChildItemJob.Id
    While ($GetChildItemJobState.State -eq "Running") {
        Write-Host "." -NoNewline -ForegroundColor Cyan
        Sleep 3
        $SleepTimer ++
    }
    Write-Host " - " -NoNewline
    $GetChildItemJobResults = Receive-Job -Job $GetChildItemJob
    Return $GetChildItemJobResults
}

Clear-Host

#region Getting NAT External Address
Write-Color -Text "Getting ", "External NAT IP Addresses", " - " -Color White, Yellow, White
    $NATExternalAddress = Start-MultiThreadJob -ScriptBlock 'Get-NetNatExternalAddress -ErrorAction Stop' -JobName "GetNATExternalAddress"
    #$NATExternalAddress = Get-NetNatExternalAddress -ErrorAction Stop
Write-Host "Complete" -ForegroundColor Green
#endregion

$PreviousNATName = ""
$PreviousExportFile = ""

$AllNATRules = @()
$AllExportFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\NAT Rules\All NAT Rules" -Extension ".html"

$AllNATRuleErrors = @()
$AllErrorsExportFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\NAT Rules\All NAT Rule Errors" -Extension ".html"

$ExternalAddressCounter = 1
$ExternalAddressCount = $NATExternalAddress.Count
Write-Color -Text "Total External Addresses: ", $ExternalAddressCount -Color White, Yellow -EndLine

$NATNameCounter = 1
$NATNameCount = (($NATExternalAddress.NatName) | Select -Unique).Count
Write-Color -Text "Total NAT Names: ", $NATNameCount -Color White, Yellow -EndLine
ForEach ($NATDetails in $NATExternalAddress) {
    Try {
        If ($PreviousNATName -ne "" -and $NATDetails.NatName -ne $PreviousNATName) {
            Write-Color -Text "$ExternalAddressCounter/$ExternalAddressCount", "-", "$NATNameCounter/$NATNameCount", " - Exporting NAT Details to ", $ExportFile, " - " -Color Cyan, White, Cyan, White, Yellow, White
                New-HTML -InputObject ($NATStaticMappings | Select NatName,ExternalIPAddress,InternalIPAddress,Protocol,ExternalPort,InternalPort,Active) -NATRule $NATDetails.NatName -OutputFile $ExportFile -Overwrite
            Write-Host "Complete" -ForegroundColor Green
            $NATNameCounter ++
        }
        
            If ($NATDetails.NatName -ne $PreviousNATName) { $ExportFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\NAT Rules" -Extension ".html" -VariableName -Name $NATDetails.NatName }
        ElseIf ($NATDetails.NatName -eq $PreviousNATName) { $ExportFile = $PreviousExportFile }

        Write-Color -Text "$ExternalAddressCounter/$ExternalAddressCount", "-", "$NATNameCounter/$NATNameCount", " - Getting Static Mappings - ", $NATDetails.IPAddress, " / ", $NATDetails.NatName, " - " -Color Cyan, White, Cyan, White, Yellow, White, Yellow, White
            $ScriptBlock = 'Get-NetNatStaticMapping -NatName ' + $NATDetails.NatName + ' -ErrorAction Stop'
            $NATStaticMappings = Start-MultiThreadJob -ScriptBlock $ScriptBlock  -JobName "GetNATStaticMappings"
            $AllNATRules += $NATStaticMappings
        Write-Host "Complete" -ForegroundColor Green
    
        $PreviousNATName = $NATDetails.NatName
        $PreviousExportFile = $ExportFile
        #$ExportFile = $null
    }
    Catch {
        Write-Host "Failed" -ForegroundColor Red
        $_
        $ErrorExportFile = $ExportFile + "-ERROR.TXT"
        $HTMLErrorExportFile = Get-TimeStampOutputFile -TargetLocation "C:\Temp\Nat Rules" -Extension ".html" -VariableName $ErrorExportFile
        $ErrorResults = @()
        $ErrorResults += $_
        #$ErrorResults += $_ | Select -ExpandProperty PipelineIterationInfo

        $AllNATRuleErrors += $_
        #$AllNATRuleErrors += $_ | Select -ExpandProperty PipelineIterationInfo

        New-HTML -InputObject $ErrorResults -NATRule "Errors" -OutputFile $HTMLErrorExportFile -Overwrite
        $_ | Out-File $ErrorExportFile -Append -Encoding ascii -NoClobber -ErrorAction Stop
    }
    $ExternalAddressCounter ++
}

Write-Color -Text "Exporting ", "ALL NAT", " Details to ", $ExportFile, " - " -Color White, Yellow, White, Yellow, White
    New-HTML -InputObject ($AllNATRules | Select NatName,ExternalIPAddress,InternalIPAddress,Protocol,ExternalPort,InternalPort,Active) -NATRule "All NAT Rules" -OutputFile $AllExportFile -Overwrite
    New-HTML -InputObject $AllNATRuleErrors -NATRule "Errors" -OutputFile $AllErrorsExportFile -Overwrite
Write-Host "Complete" -ForegroundColor Green
