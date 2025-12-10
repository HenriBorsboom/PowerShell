[XML] $GlobalConfig = Get-Content 'C:\HealthCheck\Scripts\Config.xml'
$objExcel = new-object -comobject excel.application  
$objExcel.Visible = $false
$objWorkbook = $objExcel.Workbooks.Open($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.MasterList) 
$objWorksheet = $objWorkbook.Worksheets.Item(1)
$introw = 1

[Object[]] $ServerList = @()
while($null -ne ($objWorksheet.Cells.Item($intRow, 1).Value()))
{
	if ($objWorksheet.Cells.Item($intRow, 9).Value() -like '*windows*') {
        $ServerList += (New-Object -TypeName PSObject -Property @{
            ServerName = $objWorksheet.Cells.Item($intRow, 1).Value()
            UserName = $objWorksheet.Cells.Item($intRow, 4).Value()
            SDLC = $objWorksheet.Cells.Item($intRow, 7).Value()
            ServerGroup = $objWorksheet.Cells.Item($intRow, 2).Value()
            Description = $objWorksheet.Cells.Item($intRow, 3).Value()
            Location = $objWorksheet.Cells.Item($intRow, 13).Value()
            DMZ = $objWorksheet.Cells.Item($intRow, 14).Value()
            OS = $objWorksheet.Cells.Item($intRow, 9).Value()
        })
    }
        $introw++
	Write-Host "Processed $introw"
}
Remove-item ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.ServerList) -Force
$ServerList | Select-Object ServerName, UserName, SDLC, Servergroup, Description, Location, DMZ, OS | Export-Csv ($GlobalConfig.Settings.Sources.ServerListFolder + $GlobalConfig.Settings.Lists.ServerList) -Force -NoClobber -Encoding ASCII -NoTypeInformation -Delimiter ";"
