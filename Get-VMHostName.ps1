Function Get-VMHostName {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $VMName)
    Try { Return $VMHost = (Get-SCVirtualMachine -Name $VMName).VMHost.Name }
    Catch { Return $false }
}