New-SelfSignedCertificate -DnsName jump01.ansible.local -CertStoreLocation Cert:\LocalMachine\My
$thumb = (Get-ChildItem Cert:\LocalMachine\My  | Where-Object Subject -like '*jump01.ansible.local*').Thumbprint
winrm delete winrm/config/Listener?Address=*+Transport=HTTPS
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"jump01.ansible.local`";CertificateThumbprint=`"$thumb`"}"
Restart-Service WinRM

net localgroup administrators s_draas_dns_prod /add