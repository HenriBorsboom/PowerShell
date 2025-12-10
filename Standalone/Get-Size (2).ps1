Function Get-Size {
    Param (
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Path)

    If ($Path -eq "") { $Path = ".\" }
    $MBSize = @{Name='Size (MB)'; Expression={ if ($_.Length -ne $null) {'{0:N3} MB' -f ($_.Length / 1KB) } else { 'n/a'} }}
    Get-ChildItem $path | Format-Table -AutoSize FullName, $MBSize, Mode, LastAccessTime, LastWriteTime
}

Get-Size c:\

#(Dir $env:windir) | Select-Object Name, LastWriteTime, $MBSize
#dir | Get-Member | Where MemberType -eq "Property" | select Name
