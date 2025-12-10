Param(
    [Parameter(Mandatory=$True,Position=1)]
    [Array] $HoststoSearch, `
    [Parameter(Mandatory=$False,Position=2)]
    [String] $FilterByName, `
    [Parameter(Mandatory=$False,Position=3)]
    [Bool] $ExportToCSV, `
    [Parameter(Mandatory=$False,Position=4)]
    [string] $CSVExportFile)
    
Function Debug
{
    Param([Parameter(Mandatory=$false,Position=1)]
    $Variable)
    
    If ($Variable -eq $null)
    {
        $VariableDetails = "Empty Variable"
    }
    Else
    {
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c")
    {
        Return
    }
    Else
    {
        Exit 1
    }
}

Function Get-VMIDsOnHost
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [Array] $VMHosts, `
        [Parameter(Mandatory=$False,Position=2)]
        [String] $NameFilter, `
        [Parameter(Mandatory=$False,Position=3)]
        [Bool] $Export, `
        [Parameter(Mandatory=$False,Position=4)]
        [string] $ExportFile)
    
    If ($Export -eq $True -and $ExportFile -ne "")
    {
        Try
        {
            If ((Test-Path $ExportFile) -eq $True)
            {
                Remove-Item $ExportFile -Force -ErrorAction Stop
            }
        }
        Catch
        {
            Write-Host "Unable to remove " -NoNewline
            Write-Host "$ExportFile" -ForegroundColor Red
            Write-Host "Disabling Export"
            
            $Export = $False
        }
    }

    ForEach ($VMHost in $VMHosts)
    {
        If ($NameFilter -ne "")
        {
            $VMs = Get-Vm -ComputerName $VMHost -ErrorAction Stop | Where-Object {$_.Name -like $NameFilter} | Select Name
            If ($VMs -eq $null)
            {
                Write-Host "Unable to retrieve VMs from " -NoNewline
                Write-Host "$VMHost " -ForegroundColor Red
            }
        }
        Else
        {
            $VMs = Get-Vm -ComputerName $VMHost -ErrorAction Stop | Select Name
            If ($VMs -eq $null)
            {
                Write-Host "Unable to retrieve VMs from " -NoNewline
                Write-Host "$VMHost " -ForegroundColor Red
            }
        }
        
        ForEach ($VM in $VMs)
        {
            $Output = New-Object PSObject
            [String] $VMName = $VM
            $VMName = $VMName.Remove(0, 7)
            $VMName = $VMName.Remove($VMName.Length -1, 1)

            $VMID = Get-VM -Name $VMName -ComputerName $VMHost | Select ID
        
            [String] $NewVMID = $VMID
            $NewVMID = $NewVMID.Remove(0, 5)
            $NewVMID = $NewVMID.Remove($NewVMID.Length - 1, 1)

            $Output | Add-Member -MemberType NoteProperty -Name VM -Value $VMName
            $Output | Add-Member -MemberType NoteProperty -Name ID -Value $NewVMID
            $Output | Add-Member -MemberType NoteProperty -Name Host -Value $VMHost
            
            If ($Export -eq $True)
            {
                $Output | Export-Csv -path $ExportFile -Append -NoClobber -NoTypeInformation
            }
            $Output | Sort-Object -Property VMName
         }
    }
    If ($Export -eq $True)
    {
        Write-Host ""
        Write-Host "Data has been exported to " -NoNewline
        Write-Host "$ExportFile" -ForegroundColor Green -NoNewline
        Write-Host " sucessfully"
    }
}

Get-VMIDsOnHost -VMHosts $HoststoSearch -NameFilter $FilterByName -Export $ExportToCSV -ExportFile $CSVExportFile

