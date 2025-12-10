#region Retrieve Templates
    Write-Host "Retrieving templates where name starts with 'Temp*' - " -NoNewline
    $Templates = Get-SCVMTemplate | Where-Object {$_.Name -like "Temp*"}
    Write-Host "Done" -ForegroundColor Green
#endregion

Write-Host "Checking if templates retrieved containts templates - " -NoNewline
If ($Templates -ne $null)
{
    Write-Host "Templates found" -ForegroundColor Green
    ForEach ($Template in $Templates)
    {
        Write-Host " Retrieving Template - $Template - information " -ForegroundColor Yellow -NoNewline
            $RemoveTemplate = Get-SCVMTemplate -Name $Template
        Write-Host "Completed" -ForegroundColor Green
        
        Write-Host " Attemping to remove template - $Template - " -ForegroundColor Yellow -NoNewline
        Try
        {
            $empty = Remove-SCVMTemplate -VMTemplate $RemoveTemplate -ErrorAction Stop
            Write-Host "Succesfull" -ForegroundColor Green
        }
        Catch
        {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}
Else
{
    Write-Host "No Templates found" -ForegroundColor Yellow
}