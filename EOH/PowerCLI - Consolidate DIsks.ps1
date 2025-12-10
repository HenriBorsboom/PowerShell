Function Load-Modules(){
    Param (
        [Parameter(Mandatory=$True, Position=1)][ValidateSet("VMware", "HyperVCluster","HyperV")]
        [String] $HyperVisor)

    $Modules = @()

    Switch ($HyperVisor) {
        "VMWare" {
            $Modules += ,("VMware.VimAutomation.Core")
            $Modules += ,("VMware.VimAutomation.Vds")
            $Modules += ,("VMware.VimAutomation.Cloud")
            $Modules += ,("VMware.VimAutomation.PCloud")
            $Modules += ,("VMware.VimAutomation.Cis.Core")
            $Modules += ,("VMware.VimAutomation.Storage")
            $Modules += ,("VMware.VimAutomation.HorizonView")
            $Modules += ,("VMware.VimAutomation.HA")
            $Modules += ,("VMware.VimAutomation.vROps")
            $Modules += ,("VMware.VumAutomation")
            $Modules += ,("VMware.DeployAutomation")
            $Modules += ,("VMware.ImageBuilder")
            $Modules += ,("VMware.VimAutomation.License")
        }
        "HyperVCluster" {
            $Modules += ,("FailoverClusters")
            $Modules += ,("HyperV")
        }
        "HyperV" {
            $Modules += ,("HyperV")
        }
    }

    $LoadedModules     = Get-Module -Name $Modules -ErrorAction Ignore | ForEach-Object {$_.Name}
    $RegisteredModules = Get-Module -Name $Modules -ListAvailable -ErrorAction Ignore | ForEach-Object {$_.Name}

    ForEach ($Module in $RegisteredModules) {
        If ($LoadedModules -notcontains $Module) {
            Import-Module $Module -ErrorAction SilentlyContinue
        }
   }
}

Clear-Host

$Connection = New-Object -TypeName PSObject -Property @{
    'IP Address'  = '10.190.26.74';
    'Username'    = 'administrator@stanlibdirectory.com';
    'Password'    = 'P@ssw0rd';
}

Write-Host ("Loading modules for VMWare - ") -NoNewline
Load-Modules -HyperVisor VMWare
Write-Host "Complete" -ForegroundColor Green

Write-Host "Connecting to VI Server - " -NoNewline
$Credentials = New-Object -TypeName System.Management.Automation.PSCredential($Connection.'Username', (ConvertTo-SecureString -String $Connection.'Password' -AsPlainText -Force))
Connect-VIServer -Server $Connection.'IP Address' -Credential $Credentials -WarningAction SilentlyContinue
Write-Host "Complte" -ForegroundColor Green

Write-Host "Getting VMs - " -NoNewline
$VMs = Get-VM
Write-Host ($VMs.Count.ToString() + ' found') -ForegroundColor Yellow

$Failure = @()
$Success = @()

For ($i = 0; $i -lt $Vms.Count; $i ++) {
    Write-Host ("Attempting to consolidate disks on " + $VMs[$i].Name + " - ") -NoNewline
    Try { 
        (Get-VM -Name $VMs[$i].Name).ExtensionData.ConsolidateVMDisks() 
        Write-Host "Complete" -ForegroundColor Green
        $Success += ,($VMs[$i])    
    }
    Catch { 
        Write-Host "Failed" -ForegroundColor Red
        $Failure += ,($VMs[$i])
    }
}

Write-Host "---------------------------------------------" -ForegroundColor Yellow
Write-Host ("VM Count: " + $VMs.Count.ToString())
Write-Host ("Success Count: " + $Success.Count.ToString())
Write-Host ("Failure Count: " + $Failure.Count.ToString())
Write-Host "---------------------------------------------" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Red
Write-Host "------------------ Failures -----------------" -ForegroundColor Yellow
Write-Host "---------------------------------------------" -ForegroundColor Red
$Failure