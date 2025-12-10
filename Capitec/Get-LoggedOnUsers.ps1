Function Get-byEventLog {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Computername = "",
        [Parameter(Mandatory=$False, Position=2)]
        [Int] $EntryCount = 10
    )
    If ($Computername -ne "") {
        Get-WinEvent -Computer $Computername -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents $EntryCount | Select-Object @{N='User';E={$_.Properties[1].Value}}, TimeCreated
    }
    Else {
        Get-WinEvent -FilterHashtable @{Logname='Security';ID=4672} -MaxEvents $EntryCount | Select-Object @{N='User';E={$_.Properties[1].Value}}, TimeCreated
    }
}
Function Get-byUsersFolder {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Computername = "",
        [Parameter(Mandatory=$False, Position=2)]
        [Int] $EntryCount = 10
    )
    If ($Computername -ne "") {
        Get-ChildItem "\\$Computername\c$\Users" | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -First $EntryCount
    }
    Else {
        Get-ChildItem C:\Users | Sort-Object LastWriteTime -Descending | Select-Object Name, LastWriteTime -First $EntryCount
    }
}
Function Get-byWMIClass {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Computername = "",
        [Parameter(Mandatory=$False, Position=2)]
        [Int] $EntryCount = 10
    )
    If ($Computername -ne "") {
        Get-WmiObject -Class Win32_NetworkLoginProfile -ComputerName $Computername | Sort-Object -Property LastLogon -Descending `
        | Select-Object -Property * -First $EntryCount `
        | Where-Object {$_.LastLogon -match "(\d{14})"} `
        | Foreach-Object { New-Object PSObject -Property @{ Name=$_.Name;LastLogon=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)}} | Select-Object Name, LastLogon
    }
    Else {
        Get-WmiObject -Class Win32_NetworkLoginProfile | Sort-Object -Property LastLogon -Descending `
        | Select-Object -Property * -First $EntryCount `
        | Where-Object {$_.LastLogon -match "(\d{14})"} `
        | Foreach-Object { New-Object PSObject -Property @{ Name=$_.Name;LastLogon=[datetime]::ParseExact($matches[0], "yyyyMMddHHmmss", $null)}} | Select-Object Name, LastLogon
    }
}

Get-byEventLog
Get-byUsersFolder
Get-byWMIClass
