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
$DuplicateQFEs = @()
$UniqueQFEs = @()
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
        
        If ($QFEs.count -gt 0) {
            If ($server -eq $Servers[0]) {
                $QFEs = $QFEs + $QFE
            }
            ElseIf ($QFEs.HotfixID.Contains($QFE.HotFixID)) {
                $DuplicateQFEs = $DuplicateQFEs + $Qfe
            }
            Else {
                $UniqueQFEs = $UniqueQFEs + $Qfe
            }
        }
        ElseIf ($QFEs.Count -eq 0) {
            $QFEs = $QFEs + $QFE
        }
    }
    Write-Host ("QFE Count - " + $QFEs.Count)
}
#$QFEs | Format-Table Source,HotFixID,Description,InstalledOn,InstalledBy -AutoSize
$txt = $UniqueQFEs | Format-Table Source,HotFixID,Description,InstalledOn,InstalledBy -AutoSize | Format-Table Source,HotFixID,Description,InstalledOn,InstalledBy -AutoSize
$txt | Out-File c:\temp\qfe.txt -Force
notepad c:\temp\qfe.txt
#$DuplicateQFEs | Format-Table -AutoSize