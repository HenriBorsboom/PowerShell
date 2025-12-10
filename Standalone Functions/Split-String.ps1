Function Split-String {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $VMMUserID)
    $Separator = "_"
    $Option = [System.StringSplitOptions]::RemoveEmptyEntries
    $IDSplit = $VMMUserID.Split($Separator,2, $Option)
    $SQLUserID = $IDSplit[0]
    Return $SQLUserID
}
