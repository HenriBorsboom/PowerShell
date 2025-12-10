$Source = 'C:\' #Mapped Drive on micro server
$Target = 'D:\FILESERVER01\D' #Target folder on micro server

$Commands = @()
$Commands += ,('Robocopy /r:0 /w:0 /copyall /zb /mir /mt:32 /np /log:c:\robocopy_logs\root.log /ns /nc /nfl /ndl ' + $Source + ' ' + $Target)
$Folders = Get-ChildItem $Source -Directory -Force
ForEach ($Folder in $Folders) {
    If ($Folder.Name -notlike '*System Volume Information*' -and $Folder.Name -notlike '*$Recycle.Bin*') {
        $Commands += ,('Robocopy /e /r:0 /w:0 /copyall /zb /mir /mt:32 /np /log:C:\Robocopy_Logs\' + $Folder.BaseName + '.log /ns /nc /nfl /ndl ' + $Folder.FullName + ' ' + $Target + '\' + $Folder.BaseName)
    }
}
If (Test-Path C:\Robocopy_Logs) {

}
Else {
    md C:\Robocopy_Logs
}
$Commands