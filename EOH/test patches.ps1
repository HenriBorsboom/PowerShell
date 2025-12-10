Clear-Host
$BaseLink = 'https://support.microsoft.com/en-za/help/'

Write-Host "Getting QFE - " -NoNewline
$QFE = Get-WmiObject -Class Win32_QuickFixEngineering -Property *
Write-Host ($QFE.Count.tostring() + " found")

$KBResults = @()
For ($QFEi = 0; $QFEi -lt $QFE.Count; $QFEi ++) {
    $KB = $QFE[$QFEi].HotFixID.Replace("KB","")

    $FullLink = $BaseLink + $KB
    Write-Host ("Getting info on " + $QFE[$QFEi].HotFixID)
    $LinkResults = Invoke-WebRequest $FullLink
    $Test =  $LinkResults.AllElements[448].innerHTML -split '"title": "'
    $NewTest = $Test[7] -split '",'
    $KBResults += ,(New-Object -TypeName PSObject -Property @{
        KB = $QFE[$QFEi].HotFixID
        Description = $NewTest[0]
        Link = $FullLink
    } | Select KB, Description, Link)
}    

$KBResults
