Clear-Host

$Width = 180
[String[] ] $MyMenu = @()

$LineDraw = ''
For ($LineDrawIndex = 0; $LineDrawIndex -lt $Width; $LineDrawIndex ++) {
    $LineDraw += '-'
}
$MenuDraw = ''
For ($MenuDrawIndex = 0; $MenuDrawIndex -lt $Width; $MenuDrawIndex ++) {
    If ($MenuDrawIndex -lt (($Width - "Menu".Length) / 2)) {
        $MenuDraw += ' '
    }
    ElseIf ($MenuDrawIndex -eq (($Width - "Menu".Length) / 2)) {
        $MenuDraw += 'Menu'
    }
    ElseIf (($MenuDrawIndex + "Menu".Length) -gt (($Width - "Menu".Length) / 2)) {
        $MenuDraw += ' '
    }
}

$MyMenu += ,($LineDraw)
$MyMenu += ,($MenuDraw)
$MyMenu += ,($LineDraw)


$Properties = @('Name', 'DisplayName', 'Status', 'StartType')
$Services = Get-Service | Select-Object $Properties

$TotalLength = 0
ForEach ($Property in $Properties) {
    $TotalLength += $Property.length
}
$TotalLength += $Properties.Count
$AvailableLength = $Width - $TotalLength
$TableSize = [Math]::Round($AvailableLength / $Properties.Count, 0)

$PropertiesTitleString = ''
For ($PropertiesTitleIndex = 0; $PropertiesTitleIndex -lt $Properties.Count; $PropertiesTitleIndex ++) {
    If ($PropertiesTitleIndex -eq ($Properties.Count - 1)) {
        $PropertiesTitleString = $PropertiesTitleString + $Properties[$PropertiesTitleIndex]
    }
    Else {
        $LongLine = $Properties[$PropertiesTitleIndex]
        For ($ItemIndex = 0; $ItemIndex -lt ($TableSize - $Properties[$PropertiesTitleIndex].Length); $ItemIndex ++) {
            $LongLine += " "
        }
        $PropertiesTitleString += $LongLine
    }
}
$MyMenu += $PropertiesTitleString

For ($ServiceIndex = 0; $ServiceIndex -lt $Services.Count; $ServiceIndex ++) {
    $MenuItemString = ''
    For ($PropertiesTitleIndex = 0; $PropertiesTitleIndex -lt $Properties.Count; $PropertiesTitleIndex ++) {
        If ($PropertiesTitleIndex -eq ($Properties.Count - 1)) {
            $MenuItemString = $MenuItemString + ([String] ($Services[$ServiceIndex] | Select $Properties[$PropertiesTitleIndex])).Replace(('@{' + $Properties[$PropertiesTitleIndex] + '='), '').Replace('}','')
        }
        Else {
            $LongLine = ([String] ($Services[$ServiceIndex] | Select $Properties[$PropertiesTitleIndex])).Replace(('@{' + $Properties[$PropertiesTitleIndex] + '='), '').Replace('}','')
            $LongLineOriginalLength = [Math]::Round($LongLine.Length,0)
            For ($ItemIndex = 0; $ItemIndex -lt ($TableSize - $LongLineOriginalLength); $ItemIndex ++) {
                $LongLine += " "
                #Write-Host " " -NoNewline
            }
            #Write-Host "a" -NoNewline
            #$LongLine += "a"
            $MenuItemString += $LongLine
        }
    }
    $MyMenu += $MenuItemString
}


$MyMenu