# Windows Update Functions

Function Get-InstalledUpdates {
    [cmdletbinding(DefaultParameterSetName="All")]

    Param(
        [parameter(mandatory=$true,parametersetname='All')]
        [parameter(mandatory=$true,parametersetname='HotFixes')]
        [parameter(mandatory=$true,parametersetname='Updates')]
        [array]$ComputerName,
        [parameter(mandatory=$false,parametersetname='All')][switch]$All,
        [parameter(mandatory=$false,parametersetname='HotFixes')][switch]$HotFixes,
        [parameter(mandatory=$false,parametersetname='Updates')][switch]$Updates)

    $Session = New-PSSession -ComputerName $ComputerName
    Invoke-Command -Session $Session -ScriptBlock {$Session = New-Object -ComObject Microsoft.Update.Session}
    Invoke-Command -Session $Session -ScriptBlock {$Searcher = $Session.CreateUpdateSearcher()}
    Invoke-Command -Session $Session -ScriptBlock {$HistoryCount = $Searcher.GetTotalHistoryCount()}
    
    If (($PSCmdlet.ParameterSetName -eq 'All') -or ($PSCmdlet.ParameterSetName -eq 'Updates')) {
        $Output = Invoke-Command -Session $Session -ScriptBlock {
            $Updates = $Searcher.QueryHistory(0,$HistoryCount) 
            ForEach ($Update in $Updates) {
                [regex]::match($Update.Title,'(KB[0-9]{6,7})').value | Where-Object {$_ -ne ""} | `
                ForEach {
                    $Object = New-Object -TypeName PSObject
                    $Object | Add-Member -MemberType NoteProperty -Name KB -Value $_
                    $Object | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'Update'
                    $Object
                }
            }
        }
        $Output | Select-Object KB,Type,@{Name="ComputerName";Expression={$_.PSComputerName}}
    }
    If (($PSCmdlet.ParameterSetName -eq 'All') -or ($PSCmdlet.ParameterSetName -eq 'HotFixes')) {
        $Output = Invoke-Command -Session $Session -ScriptBlock { 
            $HotFixes = Get-HotFix | Select-Object -ExpandProperty HotFixID 
            ForEach ($HotFix in $HotFixes) {
                $Object = New-Object -TypeName PSObject
                $Object | Add-Member -MemberType NoteProperty -Name KB -Value $HotFix
                $Object | Add-Member -MemberType NoteProperty -Name 'Type' -Value 'HotFix'
                $Object
            }
        }
        $Output | Select-Object KB,Type,@{Name="ComputerName";Expression={$_.PSComputerName}} 
    }
    Remove-PSSession $Session
}

Function Get-MSHotfix {
    $outputs = Invoke-Expression "wmic qfe list"
    $outputs = $outputs[1..($outputs.length)]
    
    ForEach ($output in $Outputs) {
        If ($output) {
            $output = $output -replace 'y U','y-U'
            $output = $output -replace 'NT A','NT-A'
            $output = $output -replace '\s+',' '
            $parts = $output -split ' '
            If ($parts[5] -like "*/*/*") {
                $Dateis = [datetime]::ParseExact($parts[5], '%M/%d/yyyy',[Globalization.cultureinfo]::GetCultureInfo("en-US").DateTimeFormat)
            }
            ElseIf (($parts[5] -eq $null) -or ($parts[5] -eq '')) {
                $Dateis = [datetime]1700
            }
            Else {$Dateis = get-date([DateTime][Convert]::ToInt64("$parts[5]", 16))-Format '%M/%d/yyyy'}
            
            New-Object -Type PSObject -Property @{
                KBArticle = [string]$parts[0]
                Computername = [string]$parts[1]
                Description = [string]$parts[2]
                HotFixID = [string]$parts[3]
                InstalledOn = Get-Date($Dateis)-format "dddd d MMMM yyyy"
                InstalledBy = [string]$parts[4]
                FixComments = [string]$parts[6]
                InstallDate = [string]$parts[7]
                Name = [string]$parts[8]
                ServicePackInEffect = [string]$parts[9]
                Status = [string]$parts[10]
            }
        }
    }
}

Function Report-WindowsUpdate {
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [bool] $DomainWide, `
        [Parameter(Mandatory=$False,Position=2)]
        [array] $Servers)

    If ($DomainWide -eq $True) {
        $Computers = Get-Content "C:\temp\computers.txt"
        ForEach ($Server in $Computers) {
            Write-Host "Processing $Server - " -NoNewline
            Try {
                Invoke-Command -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
    }
    Else {
        ForEach ($Server in $Servers) {
            Write-Host "Processing $Server - " -NoNewline
            Try {
                Invoke-Command -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
    }
}
