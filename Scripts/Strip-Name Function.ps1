Function Strip-Name{
    Param([String] $Name)

    [String] $NewName = $item
    $NewName = $NewName.Remove(0, 7)
    $NewName = $NewName.Remove($NewName.Length - 1, 1)

    Return $NewName
}