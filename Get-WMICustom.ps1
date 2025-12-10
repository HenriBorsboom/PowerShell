Function Get-WmiCustom { 
    Param (
        [Parameter(Mandatory=$false, Position=1)]
        [String] $Computername = $env:computername,
        [Parameter(Mandatory=$False, Position=1)]
        [String] $Namespace = 'root\cimv2',
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Class,
        [Parameter(Mandatory=$false, Position=1)]
        [Int] $Timeout=15)

    $ConnectionOptions  = New-Object System.Management.ConnectionOptions 
    $EnumerationOptions = New-Object System.Management.EnumerationOptions

    $TimeoutSeconds = New-TimeSpan -Seconds $Timeout 
    $EnumerationOptions.set_timeout($TimeoutSeconds)

    $AssembledPath = "\\" + $Computername + "\" + $Namespace 
    #write-host $assembledpath -foregroundcolor yellow
        
    $Scope = New-Object System.Management.ManagementScope $AssembledPath, $ConnectionOptions 
    $Scope.Connect()

    $QueryString = "SELECT * FROM " + $Class 
#write-host $querystring

    $Query = New-Object System.Management.ObjectQuery $QueryString 
    $Searcher = New-Object System.Management.ManagementObjectSearcher 
    $Searcher.set_options($EnumerationOptions) 
    $Searcher.Query = $QueryString 
    $Searcher.Scope = $Scope

    trap { $_ } $Result = $Searcher.get()

    return $Result 
}
Get-WmiCustom -Computername $env:COMPUTERNAME -Namespace 'root\cimv2' -Class win32_operatingsystem