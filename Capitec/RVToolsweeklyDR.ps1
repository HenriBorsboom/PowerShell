
$ExportPath = 'C:\Temp'

$Servers = 'vcsadrs01.mercantile.co.za',

$Servers | %{

. "C:\Program Files (x86)\Robware\RVTools\RVTools.exe" -u RVTools_weekly@snddomain.local -p @Rvt00l$2022! -s vcsadrs01.mercantile.co.za -s "$($_)" -c ExportAll2xls -d "$($ExportPath)" -f "DRRVTools-$($_)"

}

$smtpServer = 'emlprd01.mercantile.co.za'

$to = 'arvinkumarluckan@capitecbank.co.za'

$from = 'vcsadrs01@mercantile.co.za'

$att = Get-ChildItem -Path $ExportPath -Filter DRRVTools*.xlsx | select -ExpandProperty FullName

Send-MailMessage -SmtpServer $smtpServer -Subject 'RVTools reports' -To $to -From $from -Attachments $att

