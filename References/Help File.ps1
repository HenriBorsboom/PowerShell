#region My Help File Template

<#
    .Synopsis
        Brief
    .Description
        Descriptive
        Descriptive
    .Example
        Command
        Result
    .Parameter 1
        Param
    .Inputs
        []
    .OutPuts
        []
    .Notes
        NAME:  Function
        AUTHOR: Henri Borsboom
        LASTEDIT: 09/07/2015
        KEYWORDS: SCVMM;VMM;SC;StaticIP;SCVMM2012R2
    .Link
        https://www.linkedin.com/pulse/powershell-applying-wsus-patches-offline-vhdx-image-henri-borsboom
    #Requires - Version 4.0
#>

#endregion

#region Original Help File Template
    <#
        .Synopsis
            Converts Bytes into the appropriate unit of measure. 
        .Description
            The Get-OptimalSize function converts bytes into the appropriate unit of 
            measure. It returns a string representation of the number.
        .Example
            Get-OptimalSize 1025
            Converts 1025 bytes to 1.00 KiloBytes
        .Example
            Get-OptimalSize -sizeInBytes 10099999 
            Converts 10099999 bytes to 9.63 MegaBytes
        .Parameter SizeInBytes
            The size in bytes to be converted
        .Inputs
            [int64]
        .OutPuts
            [string]
        .Notes
            NAME:  Get-OptimalSize
            AUTHOR: Ed Wilson
            LASTEDIT: 1/4/2010
            KEYWORDS:
        .Link
            Http://www.ScriptingGuys.com
            #Requires -Version 2.0
    #>
#endregion