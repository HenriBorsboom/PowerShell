Function WMIQuery
{
    Param(
        [String] $Server, `
        [String] $NameSpace, `
        [String] $Class)

    # Get-WmiObject -ComputerName $server -Namespace root\WebAdministration -Class ApplicationPool -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | Select Name
    # Get-WmiObject -ComputerName $ProblemServers -Namespace root\microsoftiisv2 -Class IIsApplicationPoolSetting -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | Select Name

    Try
    {
        $WMIValues = Get-WmiObject -ComputerName $Server -Namespace $NameSpace -Class $Class `
            -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | Select Name
    }
    Catch
    {
        $WMIValues = $null
        Return $WMIValues
    }
    Return $WMIValues
}