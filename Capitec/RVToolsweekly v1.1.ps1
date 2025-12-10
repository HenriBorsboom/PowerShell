$ErrorActionPreference = "silentlycontinue"
$ExportPath = 'C:\Temp'
cd 'C:\Program Files (x86)\Robware\RVTools'
$Date = (Get-Date).ToString("yyyy-MM-dd")
& .\RVTools.exe -u 'RVTools_weekly@vsphere.local' -p '@Rvt00l$2022!' -s 'vcsaprd01.mercantile.co.za' -c ExportAll2xls -d "$ExportPath" -f ("RVTools-vcsaprd01.mercantile.co.za " + $Date)
Sleep 3
While (Get-Process rvtools) {
    Sleep 1
}
$smtpServer = 'emlprd01.mercantile.co.za'
$to = 'arvinkumarluckan@capitecbank.co.za', 'hborsboom@mercantile.co.za'
$from = 'VCSAPRD01@mercantile.co.za'

Send-MailMessage -SmtpServer $smtpServer -Subject 'RVTools reports' -To $to -From $from -Attachments ($ExportPath + "\RVTools-vcsaprd01.mercantile.co.za " + $Date + ".xlsx")