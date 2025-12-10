$ADID = "Cloud-Admins2"

$CommandResult = get-adgroup -Identity $ADID

$CommandResult

#If () {
#    Write-Host "True"
#}
#Else {
#    Write-Host "False"
#}