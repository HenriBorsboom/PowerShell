Clear-Host

$Servers = @(
    "NRAZUREVMH201", `
    "NRAZUREVMH202", `
    "NRAZUREVMH203", `
    "NRAZUREVMH204", `
    "NRAZUREVMH205", `
    "NRAZUREVMH206", `
    "NRAZUREVMH207", `
    "NRAZUREVMH208")
$QFEs = @()

ForEach ($Server in $Servers) {
    Write-Host $Server
    $Results = Get-WmiObject -Class Win32_QuickFixEngineering -ComputerName $Server
    ForEach ($Result in $Results) {
        $QFE = New-Object PSObject -Property @{
            Source       = $Server
            Description  = $Result.Description
            HotFixID     = $Result.HotFixID
            InstalledBy  = $Result.InstalledBy
            InstalledOn  = $Result.InstalledOn
        }
        $QFEs = $QFEs + $QFE
    }
}
$QFEs | Format-Table -AutoSize
