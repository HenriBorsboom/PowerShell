#region Restart VCenter
Stop-Service vctomcat -Verbose
Stop-Service ADAM_VMwareVCMSDS -Verbose
Stop-Service vpxd -Verbose

Start-Service ADAM_VMwareVCMSDS -Verbose
Start-Service vpxd -Verbose
Start-Service vctomcat -Verbose
#endregion
