Function Get-TotalTime {
    Param(
        [Parameter(Mandatory=$True,  Position=1)]
        [DateTime] $StartDate, `
        [Parameter(Mandatory=$True, Position=2)]
        [DateTime] $EndDate)

    $Duration = New-TimeSpan -Start $StartDate -End $EndDate
    $ReturnVariable = ("{0:dd\:hh\:mm\:ss}" -f ([TimeSpan]::FromSeconds($Duration.TotalSeconds)))
    Return $ReturnVariable, $Duration
}
Function Get-StartDate {
    Try {
        Write-Color -Text "Please enter the " ,"Start Date", " (yyyy/MM/dd HH:mm): " -ForegroundColor White, Green, White -NoNewLine; [DateTime] $StartDate = Read-Host
    }
    Catch {
        Write-Color -Text "The supplied value is incorrect. Please specify in ", "yyyy/MM/dd HH:mm", ", format." -ForegroundColor White, Red, White
        Get-StartDate
    }
    Return $StartDate
}
Function Get-EndDate {
    Try {
        Write-Color -Text "Please enter the " ,"End Date", " (yyyy/MM/dd HH:mm): " -ForegroundColor White, Green, White -NoNewLine; [DateTime] $EndDate = Read-Host
    }
    Catch {
        Write-Color -Text "The supplied value is incorrect. Please specify in ", "yyyy/MM/dd HH:mm", ", format." -ForegroundColor White, Red, White
        Get-EndDate
    }
    Return $EndDate
}
Clear-Host

$StartDate = Get-StartDate
$EndDate   = Get-EndDate
Write-Color -Text "------ Results"
Get-TotalTime -StartDate $StartDate -EndDate $EndDate
