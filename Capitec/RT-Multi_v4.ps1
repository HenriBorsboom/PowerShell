$vCenters = @()
<#$vCenters += ,(New-Object -TypeName PSObject -Property @{ 
    'System Name' = 'VCSAPRD01'; 
    'IP Address'  = '10.10.222.60'; 
    'Common Name' = 'VCSAPRD01 6.7'; 
    'Platform'    = 'VMWare'; 
    'Username'    = 'snddomain\hborsboom'; 
    'EncryptedPass' = (Get-Content 'C:\iOCO Tools\Scripts\Keys\VCSAPRD01.key')}) #Ex: 'C:\iOCO Tools\Scripts\Keys\File.key'#>
$vCenters += ,(New-Object -TypeName PSObject -Property @{ 
    'System Name' = 'VMVCPRD01'; 
    'IP Address'  = '196.6.245.163'; 
    'Common Name' = 'VMVCPRD01 5.5'; 
    'Platform'    = 'VMWare'; 
    'Username'    = 'snddomain\hborsboom'; 
    'EncryptedPass' = (Get-Content 'C:\iOCO Tools\Scripts\Keys\VMVCPRD01.key')}) #Ex: 'C:\iOCO Tools\Scripts\Keys\File.key'
$vCenters += ,(New-Object -TypeName PSObject -Property @{ 
    'System Name' = 'POSVCPRD01'; 
    'IP Address'  = '10.10.240.21'; 
    'Common Name' = 'Postillion 5.5'; 
    'Platform'    = 'VMWare'; 
    'Username'    = 'mblcard\hborsboom'; 
    'EncryptedPass' = (Get-Content 'C:\iOCO Tools\Scripts\Keys\POSVCPRD01.key')}) #Ex: 'C:\iOCO Tools\Scripts\Keys\File.key'
Clear-Host
$ScriptPath = 'C:\iOCO Tools\Scripts\RT-Single_v4.ps1'

For ($i = 0; $i -lt $vCenters.Count; $i ++) {
    $ActivevCenter = $vCenters[$i]
    $CommonName = ('(' + ($i + 1).ToString() + '-' + $vCenters.Count.ToString() + ') ' + $ActivevCenter.'Common Name')
    Write-Host (($i + 1).ToString() + "/" + $vCenters.Count.ToString() + " Processing Report for " + $ActivevCenter.'Common Name' + " - ") -NoNewLine
    $ArgumentList = @()
    $ArgumentList += (" -SystemName", ('"' + $ActivevCenter.'System Name' +'"'))
    $ArgumentList += (" -IPAddress", ('"' + $ActivevCenter.'IP Address' +'"'))
    $ArgumentList += (" -CommonName", ('"' + $CommonName +'"'))
    $ArgumentList += (" -Platform", ('"' + $ActivevCenter.'Platform' +'"'))
    $ArgumentList += (" -Username", ('"' + $ActivevCenter.'Username' +'"'))
    $ArgumentList += (" -EncryptedPass", ('"' + $ActivevCenter.'EncryptedPass' +'"'))
    Invoke-Expression "& `"$ScriptPath`" $ArgumentList"
    Write-Host "Complete"
}