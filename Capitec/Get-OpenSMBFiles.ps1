$Properties = @('Path','ClientUserName')
$Details = @()
$OutFile = 'C:\temp\OpenFiles\iCapitec_Filter2.csv'
'"Path";"ClientUserName";"CommonName";"Department";"Description";"Manager"' | Out-File $OutFile -Encoding ascii -Force
While ($True) {
    $AddCounter = 0
    $OpenFiles = Get-SmbOpenFile | Where-Object {$_.Path -like 'M:\Company Shared Files\ICapitec\*'} | Select-Object $Properties
    $Date = get-date -Format('yyyy/MM/dd HH:mm:ss')
    Write-Output ($Date + ' - Processing ' + $OpenFiles.Count.ToString())
    For ($i = 0; $i -lt $OpenFiles.Count; $i ++) {
        $NewUser = ($OpenFiles[$i].ClientUserName -split '\\')[1]
        If ($Details.ClientUserName -contains $NewUser -and $Details.Path -contains $OpenFiles[$i].Path) {
        }
        Else {
            Try {
                $AD = Get-ADUser $NewUser -Properties CN, Department, Description, Manager -ErrorAction Stop
            }
            Catch {
                Try {
                    $AD = Get-ADUser $NewUser -Properties CN, Department, Description, Manager -ErrorAction Stop
                    Write-Output ('|- Success on second attempt of Index ' + $i.ToString())
                }
                Catch {
                    Write-Output ('|- Failure on second attempt of Index ' + $i.ToString())
                    $AD = New-Object -TypeName PSObject -Property @{
                        CommonName = $_
                        Department = $_
                        Description = $_
                        Manager = $_
                    }
                }
            }
            $Details += ,(New-Object -TypeName PSObject -Property @{
                Path = $OpenFiles[$i].Path
                ClientUserName = $NewUser
                CommonName = $AD.CN
                Department = $AD.Department
                Description = $AD.Description
                Manager = $AD.Manager
            })
            ('"' + $OpenFiles[$i].Path + '";"' + $NewUser + '";"' + $AD.CN + '";"' + $AD.Department + '";"' + $AD.Description + '";"' + $AD.Manager + '"') | Out-File $OutFile -Encoding ascii -Append
            $AddCounter ++
        }
    }
    Write-Output ('|- ' + $AddCounter.ToString() + ' files added.')
}

#$Details | Select Path, ClientUserName, CommonName, Department, Description, Manager | Export-Csv C:\temp\filter.csv -Delimiter ',' -Force -NoTypeInformation