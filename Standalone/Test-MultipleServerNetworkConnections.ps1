$Web = @(
    "WEBSERVER101", `
    "WEBSERVER102", `
    "WEBSERVER103", `
    "WEBSERVER104", `
    "WEBSERVER105", `
    "WEBSERVER106", `
    "WEBSERVER107", `
    "WEBSERVER108")

ForEach ($Server in $Web) {
    Try {
        ForEach ($Server2 in $Web) {

        $Result = Invoke-Command -ComputerName $Server -ArgumentList $Server2 -ScriptBlock {winrm id -r:$Server2} -ErrorAction Stop
        Write-Host $Server "-" $Server2 "-" $Result
        }
    }
    Catch {
        Write-Host $Server "-" $_
    }
}