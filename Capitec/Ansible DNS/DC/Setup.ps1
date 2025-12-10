Register-PSSessionConfiguration -Name DnsDelegation -Path 'C:\Program Files\WindowsPowerShell\Modules\DnsDelegation\SessionConfigs\DnsDelegated.pssc' -Force
Set-PSSessionConfiguration -Name DnsDelegation -ShowSecurityDescriptorUI
# Service account only gets read + execute

New-SelfSignedCertificate -DnsName labadexternal.ansible.local -CertStoreLocation Cert:\LocalMachine\My
$thumb = (Get-ChildItem Cert:\LocalMachine\My  | Where-Object Subject -like '*labadexternal.ansible.local*').Thumbprint
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"labadexternal.ansible.local`";CertificateThumbprint=`"$thumb`"}"
Restart-Service WinRM