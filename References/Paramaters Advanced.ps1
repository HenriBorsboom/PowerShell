Function MS-Example {
    Param (
        [parameter(Mandatory=$true, ParameterSetName="Computer")]
        [String[]] $ComputerName,

        [parameter(Mandatory=$true, ParameterSetName="User")]
        [String[]] $UserName,

        [parameter(Mandatory=$false, ParameterSetName="Computer")]
        [parameter(Mandatory=$true, ParameterSetName="User")]
        [Switch] $Summary)

    Switch ($PSCmdlet.ParameterSetName) {
        "" {}
        Default  {}
    }
}
Function Test {
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param( 
        [Parameter(Mandatory=$True, Position = 1,ParameterSetName='Normal')]
        [String[]] $Text, `
        [Parameter(Mandatory=$False, Position = 2,ParameterSetName='Normal')]
        [ConsoleColor[]] $ForegroundColor, `
        [Parameter(Mandatory=$False, Position = 3,ParameterSetName='Normal')]
        [ConsoleColor[]] $BackgroundColor, `
        [Parameter(Mandatory=$False, Position = 4,ParameterSetName='Normal')]
        [Switch] $NoNewLine, `
        [Parameter(Mandatory=$False, Position = 5,ParameterSetName='Complete')]
        [Switch] $Complete)

    Switch ($PSCmdlet.ParameterSetName) {
        '' {
        
        }
        '' {
        
        }
        Default  {
        
        }
    }
}
Function Do-Something {
    <#
    .SYNOPSIS
        Describe the function here
    .DESCRIPTION
        Describe the function in more detail
    .EXAMPLE
        Give an example of how to use it
    .EXAMPLE
        Give another example of how to use it
    .PARAMETER computername
        The computer name to query. Just one.
    .PARAMETER logname
        The name of a file to write failed computer names to. Defaults to errors.txt.
    #>
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
    [CmdletBinding(DefaultParameterSetName='Normal')]
    Param (
        [Parameter(Mandatory=$True,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,HelpMessage='What computer name would you like to target?')]
        [Alias('host')]
        [ValidateLength(3,30)]
        [string[]]$computername,
    
    [string]$logname = 'errors.txt')

    Begin {
        write-verbose "Deleting $logname"
        del $logname -ErrorActionSilentlyContinue
    }
    Process {
        write-verbose "Beginning process loop"

        ForEach ($computer in $computername) {
            Write-Verbose "Processing $computer"
            If ($pscmdlet.ShouldProcess($computer)) {
                # use $computer here
            }
        }
    }
    End {

    }
}