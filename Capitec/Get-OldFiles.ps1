$OldFiles = (Get-Date).AddDays(-365)
$iCapitec = 'M:\Company Shared Files\ICapitec'
$OutFile = 'C:\Temp\Henri\iCapitec_OldFiles.txt'

Get-ChildItem -Path $iCapitec -Force -Recurse | Where-Object LastAccessTime -le $OldFiles | Select-Object Fullname, LastAccessTime, LastWriteTime, CreationTime, @{N="Owner";E={ (Get-Acl $_.FullName).Owner }} | Export-Csv $OutFile -Delimiter ";" -Encoding ASCII -NoTypeInformation
Notepad $OutFile