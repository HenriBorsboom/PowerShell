[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

$sm = New-Object Microsoft.Web.Administration.ServerManager

foreach($site in $sm.Sites)
{
    $root = $site.Applications | where { $_.Path -eq "/" }
    
    $Output = New-Object PSObject
    $Output | Add-Member -MemberType NoteProperty -Name SiteName -Value $Site.Name
    $Output | Add-Member -MemberType NoteProperty -Name AppPool -Value $root.ApplicationPoolName
    $Output | Add-Member -MemberType NoteProperty -Name ServerName -Value $env:COMPUTERNAME
    $Output
    #$Output = @{}
    #$Output.Add($Site.Name,$root.ApplicationPoolName);
    #$Output
    #Write-Output ("Site: " + $site.Name + " | Pool: " + $root.ApplicationPoolName)
}