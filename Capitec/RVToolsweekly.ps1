$ExportPath = 'C:\Temp'

$Servers = 'vcsaprd01.mercantile.co.za',

$Servers | %{

. "C:\Program Files (x86)\Robware\RVTools\RVTools.exe" -u RVTools_weekly@vsphere.local -p @Rvt00l$2022! -s vcsaprd01.mercantile.co.za -s "$($_)" -c ExportAll2xls -d "$($ExportPath)" -f "RVTools-$($_)"

}

$smtpServer = 'emlprd01.mercantile.co.za'

$to = 'arvinkumarluckan@capitecbank.co.za'

$from = 'VCSAPRD01@mercantile.co.za'

$att = Get-ChildItem -Path $ExportPath -Filter RVTools*.xlsx | select -ExpandProperty FullName

Send-MailMessage -SmtpServer $smtpServer -Subject 'RVTools reports' -To $to -From $from -Attachments $att

