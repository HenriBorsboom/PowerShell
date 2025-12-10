Add-WAPackEnvironment -Name "BCXAzurePack" `
                      -PublishSettingsFileUrl https://hosting.domain1.local:30081/publishsettings `
                      -ServiceEndpoint https://pubapi.domain1.local:30006


Get-WAPackPublishSettingsFile -Environment "BCXAzurePack"
Import-WAPackPublishSettingsFile "C:\azure\WAP Admin Testing Plan-Business Connexion Azure Pack-8-18-2015-credentials.publishsettings" -Environment "BCXAzurePack"
Get-WAPackLogicalNetwork

