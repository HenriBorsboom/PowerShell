Function New-HTML {
    Param (
        [Parameter(Mandatory=$true, Position=1)]
        [Object] $InputObject, `
        [Parameter(Mandatory=$true, Position=1)]
        [String] $NATRule, `
        [Parameter(Mandatory=$true, Position=2)]
        [Object] $OutputFile, `
        [Parameter(Mandatory=$false, Position=3)]
        [Switch] $Launch, `
        [Parameter(Mandatory=$false, Position=4)]
        [Switch] $Overwrite)

        $HTMLOutput ="<html>                                                               
                    <style>                                               
                    BODY{font-family: Arial; font-size: 8pt;}
                    H1{font-size: 16px;}
                    H2{font-size: 14px;}
                    H3{font-size: 12px;}
                    TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}
                    TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}
                    TD{border: 1px solid black; padding: 5px; }
                    td.pass{background: #7FFF00;}
                    td.warn{background: #FFE600;}
                    td.fail{background: #FF0000; color: #ffffff;}
                    </style>
                    <body>
                    <h1 align=""center"">Windows Gateway Server: $env:COMPUTERNAME</h1>
                    <h1 align=""center"">NAT Rule: $NATRule</h1>"
        $HTMLOutput += "<h2 align=""center"">Rules</h2>"
        $HTMLOutput += $InputObject | ConvertTo-HTML -Fragment
    Switch ($Overwrite) {
        $true  { If ((Get-ChildItem $OutputFile -ErrorAction SilentlyContinue) -eq $true) { Remove-Item $OutputFile -Force -ErrorAction SilentlyContinue } $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
        $False { $HTMLOutput = $HTMLOutput | Out-File $OutputFile -Encoding ascii }
    }
    Switch ($Launch) {
        $true { Start-Process $OutputFile }
    }
}