function Set-Name {
    Param(
        [Parameter(Mandatory=$True)]
        [Validatescript({
			if ($ValidSet -contains $_) {$true}
			else { throw $ValidSet}
			})]
        [String]$Name
    )
	$Name
}

$ValidSet = "a","b","c"
Set-Name -Name "s"