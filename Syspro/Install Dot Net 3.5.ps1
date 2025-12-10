$Source = '\\sysjhbstore\repo\windows\Windows 2012R2\Partner\sources\sxs'
$Features = @('NET-Framework-Features', 'NET-Framework-Core')

Install-WindowsFeature $Features -Source $Source