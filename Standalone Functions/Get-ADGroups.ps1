Function Members {
    $SQLAdminMembers = (Get-ADGroup SQL-Admins -Properties *).Members
    $SQLAdminMembersTrimmed = @()
    
    ForEach ($SQLAdmin in $SQLAdminMembers) { 
        [String] $TrimmedAdmin = $SQLAdmin
        $TrimmedAdmin = ($TrimmedAdmin.Split(",",6))[0]
        $TrimmedAdmin = $TrimmedAdmin.Remove(0, 3)
        $SQLAdminMembersTrimmed = $SQLAdminMembersTrimmed + $TrimmedAdmin
    }

    ForEach ($Member in $SQLAdminMembersTrimmed) { Write-Host $Member }
}

Function MemberOf {
    $SQLAdminMemberOf = (Get-ADGroup SQL-Admins -Properties *).MemberOf
    $SQLAdminMemberOfTrimmed = @()

    ForEach ($SQLAdmin in $SQLAdminMemberOf) { 
        [String] $TrimmedAdmin = $SQLAdmin
        $TrimmedAdmin = ($TrimmedAdmin.Split(",",6))[0]
        $TrimmedAdmin = $TrimmedAdmin.Remove(0, 3)
        $SQLAdminMemberOfTrimmed = $SQLAdminMemberOfTrimmed + $TrimmedAdmin
    }

    ForEach ($MemberOf in $SQLMemberOf) { Write-Host $MemberOf }
}

$ErrorActionPreference = "Stop"

Clear-Host

Write-Host "Members" -ForegroundColor Green
Members
Write-Host

Write-Host "MemberOf" -ForegroundColor Green
MemberOf
