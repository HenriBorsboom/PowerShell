Add-WAPackEnvironment -Name BCXWindowsAzurePack -PublishSettingsFileUrl https://hosting.domain1.local:30081/publishsettings -ServiceEndpoint https://pubapi.domain1.local:30006
Get-WAPackPublishSettingsFile -Environment BCXWindowsAzurePack
Import-WAPackPublishSettingsFile 'C:\temp2\WAP Admin Testing Plan-Business Connexion Azure Pack-9-15-2015-credentials.publishsettings' -Environment BCXWindowsAzurePack
$WAPackSubscriptions = Get-WAPackSubscription
Select-WAPackSubscription -Name $WAPackSubscriptions[0].SubscriptionName
#Get-WAPackSubscription Demo | Select-WAPackSubscription Get-WAPackVM | Select Name