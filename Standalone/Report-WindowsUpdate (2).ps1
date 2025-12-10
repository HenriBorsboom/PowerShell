Param(
    [Parameter(Mandatory=$True,Position=1)]
    [bool] $DomainWide, `
    [Parameter(Mandatory=$False,Position=2)]
    [array] $Servers)

If ($DomainWide -eq $True)
{
    $Computers = Get-Content "C:\temp\computers.txt"
    ForEach ($Server in $Computers)
    {
        Write-Host "Processing $Server - " -NoNewline
        Try
        {
            icm -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch
        {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}
Else
{
    ForEach ($Server in $Servers)
    {
        Write-Host "Processing $Server - " -NoNewline
        Try
        {
            icm -ComputerName $Server -ScriptBlock {wuauclt /reportnow} -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch
        {
            Write-Host "Failed" -ForegroundColor Red
        }
    }
}
