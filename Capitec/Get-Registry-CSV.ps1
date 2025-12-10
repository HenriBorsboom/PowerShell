Function Get-CSVData {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Path
    )
    $CSVs = Get-ChildItem ($Path + '\*.csv')
    $Details = @()
    ForEach ($CSV in $CSVs) {
        $Data = Import-Csv $CSV.FullName
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Data.Server
            ValueType = $Data.ValueType
            Value = $Data.Value
            Result = $Data.Result
        })
        Remove-Variable Data
    }
    Return $Details
}
$Folders = @()
$Folders += ,('C:\Temp\Henri\Reg')

$Details = @()
ForEach ($Path in $Folders) {
    $Results = Get-CSVData -Path $Path
    ForEach ($Result in $Results) {
        $Details += ,(New-Object -TypeName PSObject -Property @{
            Server = $Result.Server
            ValueType = $Result.ValueType
            Value = $Result.Value
            Result = $Result.Result
        })
    }
    Remove-Variable Results
    [GC]::Collect()
}
$Details | Select-Object Server, ValueType, Value, Result | Out-GridView

# Check running:
# While ($true) { Write-Host "Running: " -NoNewline; (Get-Process Powershell).Count; Start-Sleep -Seconds 1 }