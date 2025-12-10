Function Install-GuestServices {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $GuestSource, `
        [Parameter(Mandatory=$True, Position=2)]
        [Object[]] $ServerList)

    $Arguments = @('/quiet', '/norestart')
    $Failures = @()
    $Success = @()
    $Manuals = @()
    For ($i = 0; $i -lt $ServerList.Count; $i ++) {
        Write-Host (($i + 1).ToString() + '/' + ' Testing connectivity to ' + $ServerList[$i] + ' - ') -NoNewline
        If (Test-Connection -ComputerName $ServerList[$i] -Count 2 -Quiet) {
            Write-Host "Online" -ForegroundColor Green
            Write-Host "   Attempting installation via PSRemoting to the server - " -ForegroundColor Yellow
            Try {
                Invoke-Command -ComputerName $ServerList[$i] -ArgumentList $GuestSource, $Arguments -ScriptBlock {Param($Source, $Params); Invoke-Command $Source -ArgumentList $Params -ErrorAction Stop} -ErrorAction Stop
                Write-Host "Installation Success" -ForegroundColor Green
            }
            Catch {
                Write-Host "PSRemoting failed - manual installation required" -ForegroundColor Red
                $Manuals += ,($ServerList[$i])
            }
        }
        Else {
            Write-Host "Server Offline" -ForegroundColor Red
            $Failures += ,($ServerList[$i])
        }
    }
    Return $Failures, $Success, $Manuals
}
Clear-Host
# Specify the source path of the extraced VMGUEST.ISO file, which is located under C:\Windows\System32 of a Hyper-V host.
$VMGuestx86Source = '\\fileserver\share\vmguest\support\x86\setup.exe'
$VMGuestAMD64Source = '\\fileserver\share\vmguest\support\amd64\setup.exe'

#Here compile the list of all the x86 VMs
$x86Servers = @()
$x86Servers += ,('Server1')
$x86Servers += ,('Server2')

#Here compile the list of all the AMD64 VMs
$AMD64Servers = @()
$AMD64Servers += ,('Server1')
$AMD64Servers += ,('Server2')



#This runs the script, sequentially and installs on x86 VMs
$X86Results = Install-GuestServices -GuestSource $VMGuestx86Source -ServerList $x86Servers
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ("Failure Count: " + $X86Results[0].Count.ToString()) -ForegroundColor Red
Write-Host ("Success Count: " + $X86Results[1].Count.ToString()) -ForegroundColor Green
Write-Host ("Manual Count : " + $X86Results[2].Count.ToString()) -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow

#This runs the script, sequentially and installs on AMD64 VMs
$amd64Results = Install-GuestServices -GuestSource $VMGuestAMD64Source -ServerList $AMD64Servers
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ("Failure Count: " + $amd64Results[0].Count.ToString()) -ForegroundColor Red
Write-Host ("Success Count: " + $amd64Results[1].Count.ToString()) -ForegroundColor Green
Write-Host ("Manual Count : " + $amd64Results[2].Count.ToString()) -ForegroundColor Yellow
Write-Host "--------------------------------------------" -ForegroundColor Yellow