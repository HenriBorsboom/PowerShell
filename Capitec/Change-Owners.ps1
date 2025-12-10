#$ErrorActionPreference = 'Stop'
Function Change-Owner {
    Param (
        [Parameter(Mandatory=$True)]
        [String] $folderPath) # = "C:\Path\To\Your\Folder"

    
    function Take-Ownership {
        param (
            [Parameter(Mandatory=$true)]
            [string]$Path
        )
        Try {
            # Get the current ACL
            $acl = Get-Acl -LiteralPath $Path

            # Get the current owner
            $currentOwner = $acl.Owner

            # Set the local Administrators group as the owner
            $acl.SetOwner([System.Security.Principal.NTAccount]"BUILTIN\Administrators")

            # Set the new ACL
            Set-Acl -LiteralPath $Path -AclObject $acl
        }
        Catch {
            Write-Error $_
        }
    }
    Try {
        # Get the current owner of the folder
        $currentOwner = (Get-Acl -LiteralPath $folderPath -ErrorAction Stop).Owner 
        If ($currentOwner -ne 'BUILTIN\Administrators') {
            # Get the current ACL of the folder
            $currentACL = Get-Acl -LiteralPath $folderPath -ErrorAction Stop

            # New owner for the folder (local Administrators group)
            $newOwner = "BUILTIN\Administrators"

            # Change ownership of the folder
            Take-Ownership -Path $folderPath
            Set-Acl -LiteralPath $folderPath -AclObject $currentACL -ErrorAction Stop

            # Replace ownership on all subcontainers and objects
            Get-ChildItem -LiteralPath $folderPath -Recurse  -ErrorAction Stop| ForEach-Object {
                Try {
                    #Write-Host $_.FullName
                    Take-Ownership -Path $_.FullName
                }
                Catch {
                    Write-Error $_.FullName
                    Write-Error $_
                }
            }

            # Re-add the original ACL to the folder with the new owner
            $currentACL.SetOwner([System.Security.Principal.NTAccount]$newOwner)
            Set-Acl -Path $folderPath -AclObject $currentACL
        }
        Else {
            Write-Host "Already owned by Administrators" -ForegroundColor Yellow
        }
    }
    Catch {
        Write-Error $_
    }

}
For ($i = 123; $i -lt $Folders.Count; $i ++) {
    Write-Host (($i + 1).ToString() + '/' + $Folders.Count.ToString() + ' - Processing ' + $Folders[$i])
    Change-Owner -folderPath $Folders[$i]
}