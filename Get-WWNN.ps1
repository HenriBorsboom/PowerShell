Clear-Host

#region Common Functions
Function Debug{
    Param([Parameter(Mandatory=$false,Position=1)]
    $Variable)
    
    If ($Variable -eq $null)
    {
        $VariableDetails = "Empty Variable"
    }
    Else
    {
        $VariableDetails = $Variable.getType()
    }
    
    Write-Host "------ DEBUG ------" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Variable Type: " -NoNewline -ForegroundColor Yellow
    Write-Host "$VariableDetails" -ForegroundColor Red
    Write-Host "  Variable Contents" -ForegroundColor Yellow
    Write-Host "  $Variable" -ForegroundColor Red
    Write-Host "  Complete" -ForegroundColor Green
    Write-Host ""
    
    $Return = Read-Host "Press C to continue. Any other key will quit. "
    If ($Return.ToLower() -eq "c")
    {
        Return
    }
    Else
    {
        Exit 1
    }
}

Function Strip-Name{
    Param([String] $Name)
        
    $Name = $Name.Remove(0, 7)
    $Name = $Name.Remove($Name.Length - 1, 1)
    Return $Name
}

Function Write-Color {
    Param(
        [String[]]$Text, `
        [ConsoleColor[]]$Color, `
        [bool] $EndLine)
    
    For ($i = 0; $i -lt $Text.Length; $i++) {
        Write-Host $Text[$i] -Foreground $Color[$i] -NoNewLine
    }
    
    Switch ($EndLine)
    {
        $true {Write-Host}
        $false {Write-Host -NoNewline}
    }
    #Write-Color -Text "Reading data from ","host1", " - ","complete" -Color White,Cyan,White,Green
}

#endregion

#Remove-Item .\wwn.csv -Force
$CSCServers = Get-ADComputer -SearchBase "OU=Servers,OU=HQ,DC=domain2,DC=com" -Filter "Name -like 'NRAZUREVMH103*'" | select Name

$x = 1
Write-Host "Total Servers: " $CSCServers.Count
ForEach ($CSCServer in $CSCServers){
    $Server = Strip-Name -Name $CSCServer
    If ($Server -notlike "*NRAZUREVMH103*"){
        Write-Host "$x - $Server"
        Try{
            $nodewwntmp = Get-WmiObject -ComputerName $Server -class MSFC_FCAdapterHBAAttributes -Namespace “root\wmi” -Impersonation Impersonate -Authentication PacketPrivacy -ErrorAction Stop | select NodeWWN
            
            ForEach ($WMIWWNN in $nodewwntmp)
            {
                $output = New-Object PSObject

                $WWN = (($WMIWWNN.NodeWWN) | ForEach-Object {“{0:x2}” -f $_}) -join “:”
                $output | Add-Member -MemberType NoteProperty -Name Server -Value $Server
                $output | Add-Member -MemberType NoteProperty -Name WWNN -Value $WWN
                $output #| Export-Csv -Path ".\wwn.csv" -Encoding ASCII -Append -Delimiter ";" -NoTypeInformation
            }
        }
        Catch{}
    }
    $x ++
}
notepad.exe .\wwn.csv