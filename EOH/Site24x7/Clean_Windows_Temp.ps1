#Scan drives for TMP and DMP files
#Delete TMP and DMP files

#$FileTypes = @('*.tmp', '*.dmp', '*.txt', '*.log')
$WindowsTempFiles = ($env:windir + '\temp')
Get-ChildItem -Path $WindowsTempFiles -Recurse | Remove-Item -Recurse