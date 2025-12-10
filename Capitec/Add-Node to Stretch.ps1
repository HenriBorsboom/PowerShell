Function HardenServer {
    param (
        $scorch,
        $node,
        $SDLC,
        $Location,
        $ClientSeceret
    )

    If ($SDLC -eq 'DEV' -or $SDLC -eq 'INT' -or $SDLC -eq 'QA') {
        $Location = 'NP'
    }
    ElseIf ($SDLC -eq 'PRD' -or $SDLC -eq 'DR' -or $SDLC -eq 'ESIG') {
        $Location = 'PRD'
    }

    $IDP = 'https://idp-prod.int.capinet/auth/realms/PROD/protocol/openid-connect/token'
    $ClientID = "SecurityServices"
 
    $headers = @{
        "content-type" = "application/x-www-form-urlencoded"
        "Authorization" = ("Basic", [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(($ClientID+":"+$ClientSeceret))) -join " ")
    }

    $creds = @{
        username = $scorch.username
        password = $scorch.GetNetworkCredential().password
        grant_type = "password"
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $response = Invoke-RestMethod $IDP -Method Post -Body $creds -Headers $headers
    $token = $response.access_token

    $secure = $false
    $SQLServer = $false
    $Cluster = $true
    $servername = $node
             
    If ( $Secure -eq $true )     { [int] $Secure = 1 }
    If ( $Secure -eq $false )    { [int] $Secure = 0 }
    If ( $SQLServer -eq $true )  { [int] $SQLServer = 1 }
    If ( $SQLServer -eq $false ) { [int] $SQLServer = 0 }
    If ( $Cluster -eq $true )    { [int] $Cluster = 1 }
    If ( $Cluster -eq $false )   { [int] $Cluster = 0 }
    
    $hash = @{scpritFriendlyName = "HardenServer";
        scriptParameters = @{
        Servername=$Servername
        Location = $Location
        Secure = $Secure
        SQLServer = $SQLServer
        Cluster = $Cluster
        SDLC = $SDLC
        SMUserName = $env:Username
        LogID = '99999999'}
        scriptTimeout = 240000
    }

    $JSON = $hash | convertto-json

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("Authorization", $("bearer $token"))

    $result = Invoke-RestMethod -Uri "https://cbsecpsapi.int.capinet/api/ScriptExecutionAPI/run/script" -Headers $headers -Method POST -ContentType "application/json" -Body $JSON
    return $result.exitcode
}


$username = 'svc_orchestrator'
$password = 'S3rviceSc0rchrpWd'
$pass = ConvertTo-SecureString -AsPlainText $Password -Force
$SecureString = $pass
$scorch = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString

$node01 = 'Cbvmndvdbw052'
$SDLC = 'DEV'
$Location = 'NP'
$ClientSeceret = '602be3dd-644f-47ec-b6c4-5adece5cadb6'

HardenServer -scorch $scorch -node $node01 -SDLC $SDLC -Location $Location -ClientSeceret $ClientSeceret




Function CheckGroupMembership {
    Param ($node,$Location)
    
    Switch ($Location) {
        "BLV"  {$LocalDC = "CBDC01.capitecbank.fin.sky"}
        "STB"  {$LocalDC = "CBDC03.capitecbank.fin.sky"}
        "NP"   {$LocalDC = "CBDC001.capitecbank.fin.sky"}
        "PRD"  {$LocalDC = "CBDC002.capitecbank.fin.sky"}
        "DR"   {$LocalDC = "CBDC002.capitecbank.fin.sky"}
        "BFTC" {$LocalDC = "CBBFTCDC001.capitecbank.fin.sky"}
    }

    $strFilter = "(&(objectCategory=Computer)(Name=$node))"
    $objSearcher = [adsisearcher]([adsi]"LDAP://$LocalDC")
    $objSearcher.Filter = $strFilter
    $objPath = $objSearcher.FindOne()
    $objComputer = $objPath.GetDirectoryEntry()
    $info = $objComputer.memberOf
    $info | ForEach-Object{
    if($_ -like '*ClusterSvc-Enabled*')
    {
        object = $_
        return 99,$_
    }}
}
$Location = 'BFTC'




CheckGroupMembership -node $node01 -Location $location