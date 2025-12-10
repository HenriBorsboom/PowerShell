#--------------------------------------
#              Functions
#--------------------------------------

function ValidateInputs
{
    param([Parameter(Mandatory=$true)]
          [string]$node01,
          [Parameter(Mandatory=$true)]
          [string]$node02,
          [Parameter(Mandatory=$true)]
          [ValidateLength(5,15)]
          [string]$CNO,
          [Parameter(Mandatory=$true)]
          [ValidateLength(5,15)]
          [string]$VCO,
          [Parameter(Mandatory=$true)]
          [ValidateSet('DEV','INT','QA','PRD')]
          [string]$SDLC,
          [Parameter(Mandatory=$true)]
          [ValidateSet('NP','PRD')]
          [string]$Location,
          [Parameter(Mandatory=$true)]
          [string]$ClientSeceret
          )
}

function CheckGroupMembership
{
    param($node,$Location)
    
    switch ($Location) 
    {
        "BLV" {$LocalDC = "CBDC01.capitecbank.fin.sky"}
        "STB" {$LocalDC = "CBDC03.capitecbank.fin.sky"}
        "NP" {$LocalDC = "CBDC001.capitecbank.fin.sky"}
        "PRD" {$LocalDC = "CBDC002.capitecbank.fin.sky"}
        "DR" {$LocalDC = "CBDC003.capitecbank.fin.sky"}
    }

    $strFilter = "(&(objectCategory=Computer)(Name=$node))"
    $objSearcher = [adsisearcher]([adsi]"LDAP://$LocalDC")
    $objSearcher.Filter = $strFilter
    $objPath = $objSearcher.FindOne()
    $objComputer = $objPath.GetDirectoryEntry()
    $info = $objComputer.memberOf
    $info | %{
    if($_ -like '*ClusterSvc-Enabled*')
    {
        $object = $_
        return 99,$_
    }}
}

function CreateCredentials
{
    param($SDLC)
    switch($SDLC)
    {
        'dev' {
            $username = 'svc_scvmm_action_dev'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $vmmaction = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString
            $username = 'svc_orchestrator'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $scorch = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString}
        'int' {
            $username = 'svc_scvmm_action_dev'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $vmmaction = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString
            $username = 'svc_orchestrator'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $scorch = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString}
        'qa' {
            $username = 'svc_scvmm_action_dev'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $vmmaction = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString
            $username = 'svc_orchestrator'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $scorch = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString}
        'prd' {
            $username = 'svc_scvmm_action'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $vmmaction = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString
            $username = 'svc_orchestrator'
            $password = read-host -Prompt "Enter the password from flexwallet for $username"
            $pass = ConvertTo-SecureString -AsPlainText $Password -Force
            $SecureString = $pass
            $scorch = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $Username,$SecureString}
    }
    return $vmmaction,$scorch
}

function HardenServer
{
    param($scorch,
    $node,
    $SDLC,
    $Location,
    $ClientSeceret)

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
             
    if($Secure -eq $true){$Secure = 1 -as [int]}
    if($Secure -eq $false){$Secure = 0 -as [int]}
    if($SQLServer -eq $true){$SQLServer = 1 -as [int]}
    if($SQLServer -eq $false){$SQLServer = 0 -as [int]}
    if($Cluster -eq $true){$Cluster = 1 -as [int]}
    if($Cluster -eq $false){$Cluster = 0 -as [int]}
    
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

function RetreiveIPAMClusterIP
{
        param($node01,
        $CNO,
        $scorch)

        $IPAddress = (Test-Connection -count 1 -ComputerName $Node01).IPV4Address.IPAddressToString
        $FreeIP = invoke-command -ComputerName CBSTBIPAM01 -Credential $Scorch -ScriptBlock {
        param($IPAddress,
                $CNO)
        $NetworkInfo = $IPAddress.split('.')[0] + '.' + $IPAddress.split('.')[1] + '.' + $IPAddress.split('.')[2]
        $StartNetwork = ($NetworkInfo + '.1')
        $EndNetwork = ($NetworkInfo + '.254')
        $FreeIP = Get-IpamRange -StartIPAddress $StartNetwork -EndIPAddress $EndNetwork | Find-IpamFreeAddress -NumAddress 125 -TestReachability | Where-Object {$_."PingStatus" -eq "Noreply"} | Where-Object {$_."DnsRecordStatus" -eq "NotFound"} | select-object -expandproperty IPAddress | select -first 1
        Add-IpamAddress -IpAddress $FreeIP -ManagedByService IPAM -Description $CNO
        return $FreeIP} -ArgumentList $IPAddress,$CNO -ErrorAction stop
        return $FreeIP
        
}

function InstallFailoverCluster
{
    param($node)
    invoke-command -computername $node -scriptblock {
    $null = (gwmi win32_process | ?{$_.name -like '*tiworker*'}).terminate()
    if((Get-WindowsFeature -name RSAT-Clustering).installstate -ne 'installed')
    {
        sleep -s 5
        install-windowsfeature -Name RSAT-Clustering -IncludeManagementTools
    }}
}

function CreateClusterJob
{
    param($CNO,$Node01,$Node02,$ClusterIP,$vmmaction)

    $PasswordAction = $vmmaction.GetNetworkCredential().password
    $UserAction = $vmmaction.GetNetworkCredential().username
    $UserAction = ($UserAction -split "/")[0]

    invoke-command -computername $Node01 -scriptblock {
    param($CNO,
            $Node01,
            $Node02,
            $ClusterIP,
            $PasswordAction,
            $UserAction)

    if(test-path c:\temp\cluster.ps1)
    {
        remove-item c:\temp\cluster.ps1
    }

    if(test-path c:\temp\cluserout.txt)
    {
        remove-item c:\temp\cluserout.txt
    }

    if(get-scheduledtask -taskname ClusterCreate)
    {
        get-scheduledtask -taskname ClusterCreate | unregister-scheduledtask  -confirm:$false
    }

    $command = "New-Cluster -Name $CNO -Node $Node01,$Node02 -StaticAddress $ClusterIP -NoStorage | out-file c:\temp\cluserout.txt -append"
    'invoke-expression -command ' + '"' + $command + '"' | out-file c:\temp\cluster.ps1 -Encoding ASCII -append

    Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds -Value 0 -Force
    [string]$timescheduleforcluster = get-date -Format HH:mm (get-date).Addhours(1)
    get-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds
    SCHTASKS /Create /TN ClusterCreate /SC ONCE /TR 'powershell -command c:\temp\cluster.ps1' /ST $timescheduleforcluster /RL HIGHEST /RU capitecbank\$UserAction /RP $PasswordAction
    while(!(get-scheduledtask ClusterCreate))
    {
        sleep -seconds 5
        write-host "Waiting for task [ClusterCreate] to be created..." -ForegroundColor Green
    }

    } -argumentlist $CNO,$Node01,$Node02,$ClusterIP,$PasswordAction,$UserAction

}

function RestartServer
{
    param($node)
    start-job -name "Restarting node $node" -ScriptBlock {param($node) sleep -seconds 10; Restart-Computer -ComputerName $node -Force} -ArgumentList $node

    while((Test-NetConnection -computername $node).PingSucceeded -eq 'true')
    {
        write-host "Shutting down node $node"
        sleep -seconds 1
    }

    while((Test-NetConnection -computername $node).PingSucceeded -ne 'true')
    {
        write-host "Starting up node $node"
        sleep -seconds 1
    }

    while(!(invoke-Command -ComputerName $node -ScriptBlock {hostname}))
    {
        write-host "Waiting for WMI response on node $node"
        sleep -seconds 1
    }
}

function PreStageVCO
{
    param([Parameter(Mandatory=$true)]
          [string]$VCO,
          [Parameter(Mandatory=$true)]
          [string]$CNO,
          [Parameter(Mandatory=$true)]
          [string]$Location,
          $vmmaction
          )

          Try{

            Import-module "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ActiveDirectory\ActiveDirectory.psd1"
            switch ($Location) 
            {
                "BLV" {$LocalDC = "CBDC01.capitecbank.fin.sky"}
                "STB" {$LocalDC = "CBDC03.capitecbank.fin.sky"}
                "NP" {$LocalDC = "CBDC001.capitecbank.fin.sky"}
                "PRD" {$LocalDC = "CBDC002.capitecbank.fin.sky"}
                "DR" {$LocalDC = "CBDC003.capitecbank.fin.sky"}
            }
           
$pattrn = @"
^CN=(.+?)(?:(?<!\\),|$)
"@
            $dn =  Get-ADComputer $CNO -Server $LocalDC
            $OU= $($dn.DistinguishedName) -replace ($pattrn)
            $OU
            
            New-ADComputer -Name $VCO -Description "Failover cluster virtual network name account" -Path $OU -Credential $vmmaction -Server $LocalDC
            
            Write-Output "VCO created successfully"} 

            catch{
                $errormessage = $_.exception.message
                Write-Error $errormessage -ErrorAction Stop}

}

function SetVCOACL
{
    param($CNO,
          $VCO,
          $Location,
          $vmmaction)


    Import-module "C:\WINDOWS\system32\WindowsPowerShell\v1.0\Modules\ActiveDirectory\ActiveDirectory.psd1"

    switch ($Location) 
    {
        "BLV" {$LocalDC = "CBDC01.capitecbank.fin.sky"}
        "STB" {$LocalDC = "CBDC03.capitecbank.fin.sky"}
        "NP" {$LocalDC = "CBDC001.capitecbank.fin.sky"}
        "PRD" {$LocalDC = "CBDC002.capitecbank.fin.sky"}
        "DR" {$LocalDC = "CBDC003.capitecbank.fin.sky"}
    }

    if(Get-PSDrive -name AD) {Remove-PSDrive AD -ErrorAction SilentlyContinue}
    New-PSDrive -Name AD -PSProvider ActiveDirectory -Root "" -server $LocalDC -Credential $vmmaction
    $VCO = Get-ADComputer $VCO -Server $LocalDC -Credential $vmmaction
    write-output $VCO
    $CNO = Get-ADComputer $CNO -Server $LocalDC -Credential $vmmaction
    write-output $CNO
    $VCODistinguishedName = $VCO.DistinguishedName  # input AD computer distinguishedname
    $VCOacl = Get-Acl "AD:\$VCODistinguishedName"
    Write-Output $VCOacl
    $SID = [System.Security.Principal.SecurityIdentifier] $CNO.SID
    $identity = [System.Security.Principal.IdentityReference] $SID
    $adRights = [System.DirectoryServices.ActiveDirectoryRights] "GenericAll"
    $type = [System.Security.AccessControl.AccessControlType] "Allow"
    $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
    $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule $identity,$adRights,$type,$inheritanceType
    write-output $ace
    $VCOacl.AddAccessRule($ace)
    Set-Acl -path "AD:\$VCODistinguishedName" -AclObject $VCOacl -ErrorAction Stop
    Write-Output "$ClusterCNO has been granted Full control over $ClusterVCO "
}

#--------------------------------------
#              Input Variables
#--------------------------------------

$node01 = read-host -Prompt "Please provide the first node name [Not FQDN]"
$node02 = read-host -Prompt "Please provide the second node name [Not FQDN]"
$CNO = read-host -Prompt "Please provide the cluster name object [CNO]"
$VCO = read-host -Prompt "Please provide the virtual computer name object [VCO]"
$SDLC = read-host -Prompt "Please provide SDLC [DEV/INT/QA/PRD]"
$Location = read-host -Prompt "Please provide Location [NP/PRD]"
$ClientSeceret = read-host -Prompt "Please enter the production clientID (SecurityServices) password to retrieve token from IDP"


#--------------------------------------
#              Runtime
#--------------------------------------



try{ValidateInputs -node01 $node01 -node02 $node02 -CNO $CNO -VCO $VCO -SDLC $SDLC -Location $Location -ClientSeceret $ClientSeceret -ErrorAction stop}
catch{$error[0].Exception
write-error "Please review the error and modify parameters" -ErrorAction stop}

$vmmaction,$scorch = CreateCredentials -SDLC $SDLC
$ActionAccount = $vmmaction.UserName

try{gwmi win32_operatingsystem -ComputerName $node01 -ErrorAction stop
write-host "Your account has access to node $node01" -ForegroundColor green}
catch{Write-Error "Your account does not have access to node $node01" -ErrorAction stop
}

try{gwmi win32_operatingsystem -ComputerName $node02 -ErrorAction stop
write-host "Your account has access to node $node02" -ForegroundColor green}
catch{write-Error "Your account does not have access to node $node02" -ErrorAction stop
}

try{gwmi win32_operatingsystem -ComputerName cbstbipam01 -Credential $scorch -ErrorAction stop
write-host "The Scorch account access granted to CBSTBIPAM01" -ForegroundColor green}
catch{write-Error "The Scorch account could not access CBSTBIPAM01" -ErrorAction stop
}

try{gwmi win32_operatingsystem -ComputerName $node01 -Credential $vmmaction -ErrorAction stop
write-host "The VMMAction account access granted to $node01" -ForegroundColor green}
catch{write-Error "The VMMAction account could not access $node01" -ErrorAction stop
}

try{gwmi win32_operatingsystem -ComputerName $node02 -Credential $vmmaction -ErrorAction stop
write-host "The VMMAction account access granted to $node02" -ForegroundColor green}
catch{write-Error "The VMMAction account could not access $node02" -ErrorAction stop
}

$result = HardenServer -scorch $scorch -node $node01 -SDLC $SDLC -Location $Location -ClientSeceret $ClientSeceret

if($result -ne 0)
{
    write-error "Hardening failed on node $node01" -ErrorAction stop
    exit 1
}
invoke-command -ComputerName $node01 -ScriptBlock {gpupdate /force}

$groupcheck = CheckGroupMembership -node $node01 -Location $location
$checkresult = $groupcheck[0]
$clustergroup = $groupcheck[1]
if($checkresult -ne 99)
{
    write-error "Groups missing on $node01 after hardening" -ErrorAction stop
    EXIT 1
}
else
{
    write-host "Server $node01 added successfully to $clustergroup" -ForegroundColor Green
}


$result = HardenServer -scorch $scorch -node $node02 -SDLC $SDLC -Location $Location -ClientSeceret $ClientSeceret


if($result -ne 0)
{
    write-error "Hardening failed on node $node02" -ErrorAction stop
    exit 1
}
invoke-command -ComputerName $node01 -ScriptBlock {gpupdate /force}

$groupcheck = CheckGroupMembership -node $node02 -Location $location
$checkresult = $groupcheck[0]
$clustergroup = $groupcheck[1]
if($checkresult -ne 99)
{
    write-error "Groups missing on $node02 after hardening" -ErrorAction stop
    EXIT 1
}
else
{
    write-host "Server $node02 added successfully to $clustergroup" -ForegroundColor Green
}

RestartServer -node $node01
RestartServer -node $node02

<#$info = InstallFailoverCluster -node $node01
if($info.RestartNeeded -ne 'no')
{
    RestartServer -node $node01
}
$info = InstallFailoverCluster -node $node02
if($info.RestartNeeded -ne 'no')
{
    RestartServer -node $node02
}#>

$FreeIP = RetreiveIPAMClusterIP -node01 $node01 -CNO $CNO -scorch $scorch
$ClusterIP = $FreeIP.IPAddressToString
if(!($ClusterIP))
{
    write-error "no cluster ip could be allocated" -ErrorAction stop
    exit 1
}
write-host "ClusterIP: $ClusterIP" -ForegroundColor Green

while(((invoke-command -ComputerName $node01 -ScriptBlock {test-path c:\temp\clusteout.txt}) -eq $false) -and ((invoke-command -ComputerName $node01 -ScriptBlock {(get-content c:\temp\cluserout.txt).length -eq 0})))
{
    CreateClusterJob -CNO $CNO -Node01 $node01 -Node02 $node02 -ClusterIP $ClusterIP -vmmaction $vmmaction

    invoke-command -computername $node01 -scriptblock {Clear-ClusterNode -Force}
    invoke-command -computername $node02 -scriptblock {Clear-ClusterNode -force}
    
    for($x=100;$x-gt0;$x--)
    {
        write-host "Waiting for a further $x seconds to update cluster config..."
        sleep -seconds 1
    }
    invoke-command -computername $node01 -scriptblock {Set-ItemProperty -Path HKLM:SYSTEM\CurrentControlSet\Control\Lsa -Name disabledomaincreds -Value 0 -Force}
    invoke-command -computername $node01 -scriptblock {start-scheduledtask ClusterCreate}
    invoke-command -computername $node01 -scriptblock {
    while((get-scheduledtask -taskname ClusterCreate | %{$_.state}) -ne 'ready')
    {
        write-host "Waiting for cluster to be created" -ForegroundColor Green

        sleep -seconds 30
    }}
}

for($x=100;$x-gt0;$x--)
{
    write-host "Giving some time to register DNS..$x seconds"
    sleep -seconds 1
}
PreStageVCO -VCO $VCO -CNO $CNO -Location $Location -vmmaction $vmmaction
SetVCOACL -CNO $CNO -VCO $VCO -Location $Location -vmmaction $vmmaction