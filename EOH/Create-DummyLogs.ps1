Function Create-DummyLogs {
    # PowerShell script to find executables in the Windows\System32 folder
    Clear-Host
    $Path = 'C:\users\Henri.Borsboom'
    For ($i = 0; $i -lt 10; $i ++) {
        $DummyFile = ("c:Dummy" + $i.ToString() + ".log")
        fsutil file createnew $DummyFile 1000
    }
}
Create-DummyLogs