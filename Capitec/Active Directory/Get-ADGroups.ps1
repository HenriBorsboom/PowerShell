$Users = @()
$Users += ,('Alpheus Khoza')

Write-Host "Getting all AD groups - " -NoNewline -ForegroundColor Cyan
$AllGroups = Get-ADGroup -Filter * -Properties Description, ManagedBy -server cbdc004.capitecbank.fin.sky
Write-Host "Complete" -ForegroundColor Green

For ($UserI = 0; $UserI -lt $Users.Count; $UserI ++) {
    $User = $Users[$UserI]
    Write-Host (($UserI + 1).ToString() + '/' + $Users.Count.ToString() + ' - Getting Groups for ' + $User + ' - ') -NoNewline
    $ADUser = Get-ADUser -Filter {Name -like $User} -Server cbdc004.capitecbank.fin.sky -Properties MemberOf
    Write-Host "Complete" -ForegroundColor Green

    $Details = @()
    For ($GroupI = 0; $GroupI -lt $ADUser.MemberOf.Count; $GroupI ++) {
        Write-Host ('|- ' + ($GroupI + 1).ToString() + '/' + $ADUser.MemberOf.Count.ToString() + ' - Getting details for ' + ($ADUser.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "") + ' - ') -NoNewline
        If (($ADUser.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "") -notlike 'Group_*') {
            $GroupName = ($ADUser.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "")
            $GroupDetails = $AllGroups | Where-Object { $_.Name -like "$GroupName" }
        }
        Else {
            $SpecialGroup = ($ADUser.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "").Replace("Group_","")
            $GroupDetails = $AllGroups | Where-Object { $_.Name -like "*$SpecialGroup*" }
        }
        #$GroupDetails = Get-ADGroup
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Account = $User
            Group = $GroupDetails.Name
            GroupDescription = $GroupDetails.Description
            GroupManagedBy = ($GroupDetails.ManagedBy -split ',').Replace("CN=","")[0]
        })
        Write-Host 'Complete' -ForegroundColor Green
    }
    Write-Host '|- Complete' -ForegroundColor Green
    $Details | Export-CSV ('C:\Temp\ADExtracts\' + $Users[$UserI] + '.csv') -NoTypeInformation -Force
    Write-Host ('|- Exported to C:\Temp\ADExtracts\' + $Users[$UserI] + '.csv') -ForegroundColor Green

    If ($ADUser.SamAccountName -like "CP*") {
        $User = ($ADUser.SamAccountName.Replace("CP","AP"))
    }
    Else {
        $User = ($ADUser.SamAccountName.Replace("CT","AP"))
    }
    
    $Details = @()

    Write-Host (($UserI + 1).ToString() + '/' + $Users.Count.ToString() + ' - Getting Groups for ' + $User + ' - ') -NoNewline
    $AccountGroups = Get-ADUser $User -Properties MemberOf -Server cbdc004.capitecbank.fin.sky
    Write-Host "Complete" -ForegroundColor Green
    
    For ($GroupI = 0; $GroupI -lt $AccountGroups.MemberOf.Count; $GroupI ++) {
        Write-Host ('|- ' + ($GroupI + 1).ToString() + '/' + $AccountGroups.MemberOf.Count.ToString() + ' - Getting details for ' + ($AccountGroups.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "") +' - ') -NoNewline
        If (($AccountGroups.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "") -notlike 'Group_*') {
            $GroupName = ($AccountGroups.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "")
            $GroupDetails = $AllGroups | Where-Object { $_.Name -like "$GroupName" }
        }
        Else {
            $SpecialGroup = ($AccountGroups.MemberOf[$GroupI] -split ",")[0].Replace("CN=", "").Replace("Group_","")
            $GroupDetails = $AllGroups | Where-Object { $_.Name -like "*$SpecialGroup*" }
        }
        #$GroupDetails = Get-ADGroup
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Account = $User
            Group = $GroupDetails.Name
            GroupDescription = $GroupDetails.Description
            GroupManagedBy = ($GroupDetails.ManagedBy -split ',').Replace("CN=","")[0]
        })
        Write-Host 'Complete' -ForegroundColor Green
    }
    #Write-Host '|- Complete' -ForegroundColor Green
    $Details | Export-CSV ('C:\Temp\ADExtracts\' + $Users[$UserI] + '_' + $User + '.csv') -NoTypeInformation -Force
    Write-Host ('|- Exported to C:\Temp\ADExtracts\' + $Users[$UserI] + '_' + $User + '.csv') -ForegroundColor Green
}