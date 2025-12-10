Clear-Host

Function Foo { 
    Param(
        [String] $Name, 
        [Int] $Age, 
        [string] $Path) 
    
    Process { 
        If ("Tom","Dick","Jane" -NotContains $Name) { 
            Throw "$($Name) is not a valid name! Please use Tom, Dick, Jane" 
        } 
        If ($age -lt 21 -OR $age -gt 65) { 
            Throw "$($age) is not a between 21-65" 
        } 
        IF (-NOT (Test-Path $Path -PathType 'Container')) { 
            Throw "$($Path) is not a valid folder" 
        } 
        # All parameters are valid so New-stuff" 
        write-host "New-Foo" 
    }
}

Function Foo2
{ 
    Param( 
        [ValidateSet("Tom","Dick","Jane")] 
        [String] 
        $Name 
    , 
        [ValidateRange(21,65)] 
        [Int] 
        $Age 
    , 
        [ValidateScript({Test-Path $_ -PathType 'Container'})] 
        [string] 
        $Path 
    ) 
    Process 
    { 
        write-host "New-Foo" 
    } 
}

Function Foo3
{ 
    Param( 
        [Parameter(Mandatory=$false,ValueFromPipeline=$true)] 
        [ValidateScript({Test-Path $_})] 
        [String] $Key = 'HKLM:\Software\DoesNotExist') 
    
    Process 
    { 
        Try 
        { 
            Get-ItemProperty -Path $Key -EA 'Stop' 
        } 
        Catch 
        { 
            write-warning 'Error accessing $Key: $($_.Exception.Message)'
        } 
    } 
}

Foo3 -Key HKLM:\Software