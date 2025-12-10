Function New-CredentialFile {
    Param (
    [Parameter(Mandatory=$False, Position=1)]
    [Switch] $VCS, `
    [Parameter(Mandatory=$False, Position=2)]
    [Switch] $Mail, `
    [Parameter(Mandatory=$False, Position=3)]
    [String] $FileName = 'C:\iOCO Tools\Scripts\Keys\File.key')

    If ($VCS) {
        $FileName = 'C:\iOCO Tools\Scripts\Keys\VCS.key'
        $credential = Get-Credential -Message 'Credentials for VCS'
    }
    ElseIf ($Mail) {
        $FileName = 'C:\iOCO Tools\Scripts\Keys\Mail.key'
        $credential = Get-Credential -Message 'Credentials for Mail'
    }
    Else {
        $credential = Get-Credential -Message ('Supply Credentials for ' + $FileName)
    }
    
    $credential.Password | ConvertFrom-SecureString | Set-Content $FileName
    Write-Host ('Encrypted Password saved to ' + $FileName)
}
#New-CredentialFile -VCS
#New-CredentialFile -Mail
#New-CredentialFile -FileName 'C:\iOCO Tools\Scripts\Keys\VCSAPRD01.key'
#New-CredentialFile -FileName 'C:\iOCO Tools\Scripts\Keys\VMVCPRD01.key'
New-CredentialFile -FileName 'C:\iOCO Tools\Scripts\Keys\POSVCPRD01.key'