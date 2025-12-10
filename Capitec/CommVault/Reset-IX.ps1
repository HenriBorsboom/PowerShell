Function Reset-XI {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int] $i, 
        [Parameter(Mandatory=$True, Position=2)]
        [Int] $x
    )
    $ResumeIFile = 'D:\Temp\CommVault\ResumeI.txt'
    $ResumeXFile = 'D:\Temp\CommVault\ResumeX.txt'
    $i | Out-File $ResumeIFile -Encoding ascii -Force
    $x | Out-File $ResumeXFile -Encoding ascii -Force
}
Function Get-XI {
    $ResumeIFile = 'D:\Temp\CommVault\ResumeI.txt'
    $ResumeXFile = 'D:\Temp\CommVault\ResumeX.txt'
    Write-Host ("I = " + (Get-Content $ResumeIFile))
    Write-Host ("X = " + (Get-Content $ResumeXFile))
}
#Get-XI
Reset-XI -i 6 -x 8047