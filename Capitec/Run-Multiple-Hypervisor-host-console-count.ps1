$vCenters = @()
$vCenters += ,(New-Object -TypeName PSObject -Property @{ 
    'System Name' = ''; 
    'IP Address'  = ''; 
    'Common Name' = ''; 
    'Platform'    = ''; 
    'Username'    = ''; 
    'Password'    = ''}) 

Clear-Host

$ScriptPath = 'C:\iOCO Tools\Scripts\Hypervisor-host-console-count.ps1'

For ($i = 0; $i -lt $vCenters.Count; $i ++) {
    $ActivevCenter = $vCenters[$i]
    $CommonName = ('(' + ($i + 1).ToString() + '-' + $vCenters.Count.ToString() + ') ' + $vCenters[$i].'Common Name')
    Write-Host (($i + 1).ToString() + "/" + $vCenters.Count.ToString() + " Processing Report for " + $vCenters[$i].'Common Name' + " - ") -NoNewLine
    $ArgumentList = @()
    $ArgumentList += (" -SystemName", ('"' + $ActivevCenter.'System Name' +'"'))
    $ArgumentList += (" -IPAddress", ('"' + $ActivevCenter.'IP Address' +'"'))
    $ArgumentList += (" -CommonName", ('"' + $CommonName +'"'))
    $ArgumentList += (" -Platform", ('"' + $ActivevCenter.'Platform' +'"'))
    $ArgumentList += (" -Username", ('"' + $ActivevCenter.'Username' +'"'))
    $ArgumentList += (" -Password", ('"' + $ActivevCenter.'Password' +'"'))
    Invoke-Expression "& `"$ScriptPath`" $ArgumentList"
    Write-Host "Complete"
}
