$Admin=[adsi]("WinNT://./Administrator, user")
$Admin.psbase.rename("localadmin")
