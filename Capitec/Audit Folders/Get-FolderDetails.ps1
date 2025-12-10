function Get-FolderAccessReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RootPath,
        [int]$Depth = 3
    )

    # Compute how deep our root is
    $rootDepth = ($RootPath.TrimEnd('\') -split '\\').Count

    # Gather all folders within Depth
    Get-ChildItem -LiteralPath $RootPath -Directory -Recurse |
      Where-Object {
        ($_.FullName.TrimEnd('\') -split '\\').Count -le ($rootDepth + $Depth)
      } |
      ForEach-Object {
        $folder   = $_.FullName
        $stats    = Get-ChildItem -LiteralPath $folder -File -Recurse -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum
        $acl      = Get-Acl -LiteralPath $folder
        $created  = $_.CreationTime
        $lastAccM = $_.LastAccessTime

        # Pull the most recent 4663 event for this folder (if auditing is on)

        [PSCustomObject]@{
          FolderPath      = $folder
          SizeBytes       = ($stats.Sum  -as [long])
          CreatedBy       = $acl.Owner
          CreatedDate     = $created
          LastAccessDate  = $lastAccM 
        }
      }
}

# Example usage:
Get-FolderAccessReport -RootPath '\\cbfp01\icapitec' `
                       -Depth 3 | Out-GridView
  #Export-Csv .\FolderReport.csv -NoTypeInformation
