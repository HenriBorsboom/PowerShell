Function Stupid-Function {
    ForEach ($File in $Files) {
        Write-Host $File
    }
}
$Files = Get-ChildItem C:\Temp -Recurse
Stupid-Function