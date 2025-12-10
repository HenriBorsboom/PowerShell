Function Write-Color {
    Param(
        [Parameter(Mandatory=$true, Position=1)]
        [String[]] $Text, `
        [Parameter(Mandatory=$true, Position=2)]
        [ConsoleColor[]] $Color, `
        [Parameter(Mandatory=$false, Position=3)]
        [switch] $EndLine)
    
    If ($Text.Count -ne $Color.Length) {
        Write-Host "The amount of Text variables and the amount of color variables does not match" -ForegroundColor Red
        Write-Host "Text Variables:  " -NoNewline
        Write-Host $Text.Count -ForegroundColor Yellow -NoNewline
        Write-Host " - Color Variables: " -NoNewline
        Write-Host $Color.Length -ForegroundColor Yellow
        Break
    }
    Else {
        For ($TextArrayIndex = 0; $TextArrayIndex -lt $Text.Length; $TextArrayIndex ++) {
            Write-Host $Text[$TextArrayIndex] -Foreground $Color[$TextArrayIndex] -NoNewLine
        }
        Switch ($EndLine) {
            $true  { Write-Host }
            $false { Write-Host -NoNewline}
        }
    }
}
Function Get-ADGroupDetails {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [String] $GroupName)

    $ReturnObjects = New-Object PSObject
    $GroupADMembers = (Get-ADGroup $GroupName -Properties *).Members
    $StrippedGroupADMembers =  Get-ADGroupObjects -GroupDetails $GroupADMembers 
    $GroupADMemberOf = (Get-ADGroup $GroupName -Properties *).MemberOf
    $StrippedGroupADMemberOf =  Get-ADGroupObjects -GroupDetails $GroupADMemberOf 
            
    $ReturnObjects | Add-Member -MemberType NoteProperty "Members" -Value $StrippedGroupADMembers
    $ReturnObjects | Add-Member -MemberType NoteProperty "MemberOf" -Value $StrippedGroupADMemberOf
    
    Return $ReturnObjects
}
Function Get-ADGroupObjects {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object[]] $GroupDetails)
            
    $MembersTrimmed = @()

    ForEach ($Member in $GroupDetails) { 
        [String] $TrimmedAdmin = $Member
        $TrimmedAdmin = ($TrimmedAdmin.Split(",",6))[0]
        $TrimmedAdmin = $TrimmedAdmin.Remove(0, 3)
        $MembersTrimmed = $MembersTrimmed + $TrimmedAdmin
    }

    Return $MembersTrimmed
}
Function Create-Domain1Credentials {
    $SecPWD = ConvertTo-SecureString "YourPasswordHere" -AsPlainText -Force
    $Creds = New-Object PSCredential("DOMAIN1\username", $SecPWD)
    Return $Creds
}
Function Create-Domain1ADUser {
    Param ($DisplayName)
    
    $Credentials = Create-Domain1Credentials
    $ADUser = Get-ADUser -Filter {DisplayName -eq $DisplayName}
    $ADPassword = ConvertTo-SecureString "P@ssw0rd123" -AsPlainText -Force
    $ADUserUPN = $ADUser.SamAccountName + "@domain1.local"
    Try {
        Write-Color -Text "Creating ", $DisplayName, " - " -Color White, Yellow, White
            Invoke-Command -ComputerName "VMSERVER112.domain1.local" -Credential $Credentials -ArgumentList $ADUser,$ADPassword,$ADUserUPN -ScriptBlock `
                {
                    Param($ADUser,$ADPassword,$ADUserUPN)
                    New-ADUser `
                        -GivenName $ADUser.GivenName `
                        -Name $ADUser.Name `
                        -SamAccountName $ADUser.SamAccountName `
                        -Surname $ADUser.Surname `
                        -UserPrincipalName $ADUserUPN `
                        -AccountPassword $ADPassword `
                        -Enabled $true `
                        -ChangePasswordAtLogon $False `
                        -ErrorAction Stop
                }
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch { Write-Host "Failed" -ForegroundColor Red; }#$_ }
}



Clear-Host
$GroupObjects = Get-ADGroupDetails -GroupName "Domain Admins"

ForEach ($Member in $GroupObjects.Members) {
    # $Member
    Create-Domain1ADUser -DisplayName $Member
}

#ForEach ($MemberOf in $GroupObjects.MemberOf) {
#    $MemberOf
#    # Create-Domain1ADUser -DisplayName $Member
#}