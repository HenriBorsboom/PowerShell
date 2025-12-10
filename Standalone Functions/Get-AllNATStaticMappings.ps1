Function Get-Mappings {
    Param (
        [Parameter(Mandatory=$false, Position=1)]
        [Switch] $LaunchHTML, `
        [Parameter(Mandatory=$false, Position=2)]
        [Switch] $LaunchTXT)

    #region Variables
    $HTMLHeader="<style>                                               
        BODY{font-family: Arial; font-size: 8pt;}                                              
        H1{font-size: 16px;}                                               
        H2{font-size: 14px;}                                               
        H3{font-size: 12px;}                                               
        TABLE{border: 1px solid black; border-collapse: collapse; font-size: 8pt;}                                         
        TH{border: 1px solid black; background: #dddddd; padding: 5px; color: #000000;}                                           
        TD{border: 1px solid black; padding: 5px; }                                            
        td.pass{background: #7FFF00;}                                             
        td.warn{background: #FFE600;}                                             
        td.fail{background: #FF0000; color: #ffffff;}                                          
        </style>"
    $HTMLBody = "<H2>Windows Azure Pack - NGN NAT Mappings</H2>"

    $HTMLMappings = ".\Mappings.html"
    $TXTMappings = ".\Mappings.txt"
    #endregion
    #region Getting all NAT Static Mappings
    Write-Host "Getting " -NoNewline;
    Write-Host "all NAT Static Mappings" -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
        $AllMappings = Get-NetNatStaticMapping | Select NatName, StaticMappingID, Protocol, ExternalIPAddress, ExternalPort, InternalIPAddress, InternalPort, Active #| Format-Table -AutoSize
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Converting Mappings to HTML Format
    Write-Host "Converting mappings to " -NoNewline
    Write-Host "HTML " -ForegroundColor Yellow -NoNewline
    Write-Host "format - " -NoNewline
        $Mappings = $AllMappings | ConvertTo-Html -Body $HTMLBody -Head $HTMLHeader
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Saving HTML Mappings to File
    Write-Host "Saving " -NoNewline
    Write-Host "HTML " -ForegroundColor Yellow -NoNewline
    Write-Host "mappings to file - " -NoNewline
    Write-Host $HTMLMappings -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
        $HTML = $Mappings | Out-File $HTMLMappings -Force
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Saving Mappings to TXT
    Write-Host "Saving " -NoNewline
    Write-Host "TXT " -ForegroundColor Yellow -NoNewline
    Write-Host "mappings to file - " -NoNewline
    Write-Host $TXTMappings -ForegroundColor Yellow -NoNewline
    Write-Host " - " -NoNewline
        $TXT = $AllMappings | Format-Table -AutoSize | Out-File $TXTMappings -Force
    Write-Host "Complete" -ForegroundColor Green
    #endregion
    #region Display HTML and TXT Mappings
    Switch ($LaunchHTML) { $true { Invoke-Expression $HTMLMappings } }
    Switch ($LaunchTXT)  { $true { Invoke-Expression $TXTMappings } }
    #endregion
}
Get-Mappings -LaunchHTML -LaunchTXT