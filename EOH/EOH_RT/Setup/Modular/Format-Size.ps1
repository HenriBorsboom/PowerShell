Function Format-Size {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [Int64] $Size)

    If ($Size -le 1024) { $FormattedSize = ($Size.ToString() + " B") }
    ElseIf ($Size -ge 1025 -and $Size -le 1048576) { $FormattedSize = [Math]::Round($Size / 1024, 2).ToString() + " KB" }
    ElseIf ($Size -ge 1048577 -and $Size -le 1073741824) { $FormattedSize = [Math]::Round($Size / 1024 / 1024, 2).ToString() + " MB" }
    ElseIf ($Size -ge 1073741825 -and $Size -le 1099511627776) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024, 2).ToString() + " GB" }
    ElseIf ($Size -ge 1099511627777 -and $Size -le 1125899906842624) { $FormattedSize = [Math]::Round($Size / 1024 / 1024 / 1024 / 1024, 2).ToString() + " TB" }

    Return $FormattedSize
}
Format-Size -Size $Datastores.FreeSpace