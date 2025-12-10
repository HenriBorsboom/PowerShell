$2008Parent = "C:\VM\Reference Disks\Base11A-WS08R2SP1.vhd"
$2012Parent = "C:\VM\Reference Disks\Base14A-WS12R2.vhd"

ForEach ($VHD in (Get-ChildItem *.vhd -Recurse).FullName) {
    If ($VHD -ne $2008Parent -and $VHD -ne $2012Parent) {
        If ($VHD -like "*08R2*") {
            Set-Vhd -Path $VHD -ParentPath $2008Parent
        }
        ElseIf ($VHD -like "*12R2*") {
            Set-Vhd -Path $VHD -ParentPath $2012Parent
        }
    }
}