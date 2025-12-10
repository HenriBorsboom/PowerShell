#New-ADGroup -Name 'G_ICAPITEC_Folder1_RW' -SamAccountName 'G_ICAPITEC_Folder1_RW' -GroupCategory Security -GroupScope Global -Path 'OU=Groups,OU=Migrated,DC=lab,DC=local' -Description 'iCapitec Folder1' -ManagedBy 'Manager1'
#Add-ADGroupMember -Identity 'G_ICAPITEC_Folder1_RW' -Members User1, User2
#Param
$GroupCategory  = 'Security'
$GroupScope = 'Global'
$Path = 'OU=Groups,OU=Migrated,DC=capitecbank,DC=fin,DC=sky'

$Cont = Import-Csv 'C:\Offline\iCapitec-Create-Groups.csv'
$UniqueGroups = $Cont | Select-Object -Unique Group, FolderOwnerSamAccount
$OutFile = 'C:\Offline\iCapitec-Create-Groups.txt'
For ($GroupI = 0; $GroupI -lt $UniqueGroups.Count; $GroupI ++) {
    Write-Output (($GroupI + 1).ToString() + '/' + $UniqueGroups.Count.ToString() + ' - Processing ' + $UniqueGroups[$GroupI].Group)
    $StartIndex = [Array]::IndexOf($Cont.Group ,$UniqueGroups[$GroupI].Group)
    If ($GroupI + 1 -eq $UniqueGroups.Count) {
        $EndIndex = [Array]::IndexOf($Cont.Group ,$UniqueGroups[-1].Group)
    }
    Else {
        $EndIndex = ([Array]::IndexOf($Cont.Group ,$UniqueGroups[$GroupI + 1].Group) - 1)
    }
    $GroupMembers = @()
    For ($UsersI = $StartIndex; $UsersI -le $EndIndex; $UsersI ++) {
        $GroupMembers += ,($Cont[$UsersI].SAMAccountName)
    }
    #$Cont[$GroupI]
    ('New-ADGroup -Name ''' + $UniqueGroups[$Groupi].Group + ''' -SamAccountName ''' + $UniqueGroups[$Groupi].Group + ''' -GroupCategory ' + $GroupCategory + ' -GroupScope ' + $GroupScope + ' -Path ''' + $Path + ''' -Description ''' + ('iCapitec ' + $UniqueGroups[$Groupi].Group) + ''' -ManagedBy ' + $UniqueGroups[$Groupi].FolderOwnerSamAccount) | Out-File $OutFile -Encoding ascii -Append
    ('Add-ADGroupMember -Identity ''' + $UniqueGroups[$Groupi].Group + ''' -Members ' + ($GroupMembers -join ',')) | Out-File $OutFile -Encoding ascii -Append
    ('') | Out-File $OutFile -Encoding ascii -Append
    $GroupMembers = $null
}
