Clear-Host
$ErrorActionPreference = "SilentlyContinue"
For ($VolNumber = 1; $VolNumber -lt 3; $VolNumber ++) {
    $startFolder = "\\NRAZUREDBSC102\C$\ClusterStorage\Volume" + $VolNumber.ToString()
    $colItems = (Get-ChildItem $startFolder | Where-Object {$_.PSIsContainer -eq $True} | Sort-Object)
    ForEach ($i in $colItems) {
        $subFolderItems = (Get-ChildItem $i.FullName | Measure-Object -property length -sum)
        $Result = "{0:N2}" -f ($subFolderItems.sum / 1MB)
        #If ($Result -like "0,*") {
            Write-Host $i.FullName "-" $Result
        #}
    }
}
