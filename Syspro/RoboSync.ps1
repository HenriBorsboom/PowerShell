Clear-Host
$Source       = 'C:\FolderRedirect\pat'
$Destination1 = 'C:\Temp\pat'
$Destination2 = '\\192.168.1.127\redirect$\pat'

robocopy /zb /copyall /e /r:1 /w:1 /v $Source $Destination2 /xf *tmp* /xd *recycle*