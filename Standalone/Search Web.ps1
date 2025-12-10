### Web Reference
# https://4sysops.com/archives/powershell-invoke-webrequest-parse-and-scrape-a-web-page/

Clear-Host
#(wget https://who.is).forms
$Fields = @{"search_type" = "Whois"; "query" = "165.233.158.1"}
$WebResponse = Invoke-WebRequest -Uri "https://who.is/domains/search" -Method Post -Body $Fields
$Pre = $WebResponse.AllElements | Where {$_.TagName -eq "pre"}
$Pre.innerText
#$WebResponse.AllElements | Where {$_.TagName -eq "pre"}
#If ($Pre -match "country:\s+(\w{2})" -or $Pre -match "orgname:\s+(\w{9})") {
#    Write-Host "Country:" $Match[1]
#    Write-Host "Orginization:" $Match[2]
#}