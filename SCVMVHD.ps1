Clear-Host
Import-Module VirtualMachineManager

Function Set-SCVMVHDTags
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [Array] $Tags, `
        [Parameter(Mandatory=$True,Position=2)]
        [string] $VHDName)

    If ($Tags -ne $null)
    {
        Write-Host "Confirming " -NoNewline
        Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
        Write-Host " exists in VMM library - " -NoNewline
        Try
        {
            $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch
        {
            Write-Host "Failed" -ForegroundColor Red
            Exit
        }
        $empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag $Tags
        $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
        If ($Tags.Tag -ne $null)
        {
            ForEach ($Tag in $Tags.Tag)
            {
                $OutFile  = New-Object -Type PSObject
                $OutFile | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName                $OutFile | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag                $OutFile
            }
        }
    }
    Else
    {
        Write-Host 'The Tags supplied are empty. Please supply tags in ARRAY format'
        Write-Host ' Example 1: @("WindowsServer","R2")'
        Write-Host ' Example 2: "WindowsServer","R2"'
    }
}

Function Get-SCVMVHDTags
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $VHDName)

    Write-Host "Confirming " -NoNewline
    Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
    Write-Host " exists in VMM library - " -NoNewline
    Try
    {
        $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
        Exit
    }
    $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
    If ($Tags.Tag -ne $null)
    {
        ForEach ($Tag in $Tags.Tag)
        {
            $OutFile  = New-Object -Type PSObject
            $OutFile | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName            $OutFile | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag            $OutFile
        }
    }
    Else
    {
        Write-Host "There are no tags set on " -NoNewline
        Write-Host $VHDName -ForegroundColor Yellow
    }
}

Function Get-SCVMVHD
{
    Get-SCVirtualHardDisk | Select Name
}

Function Clear-SCVMVHDTags
{
    Param(
        [parameter(Mandatory=$True,Position=1)]
        [string] $VHDName)

    Write-Host "Confirming " -NoNewline
    Write-Host "$VHDName" -NoNewline -ForegroundColor Yellow
    Write-Host " exists in VMM library - " -NoNewline
    Try
    {
        $VHD = Get-SCVirtualHardDisk -Name $VHDName
        Write-Host "Complete" -ForegroundColor Green
    }
    Catch
    {
        Write-Host "Failed" -ForegroundColor Red
        S
    }

    $Empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag ""

    $Tags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
    ForEach ($Tag in $Tags.Tag)
    {
        $Output = New-Object PSObject
        $Output | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName
        $Output | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag
        $Output
    }
}

Function Add-SCVMVHDTags
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [string] $VHDName, `
        [Parameter(Mandatory=$True,Position=2)]
        [array] $Tags)

    If ($Tags -ne $null)
    {
        Write-Host "Confirming that " -NoNewline
        Write-Host $VHDName -ForegroundColor Yellow -NoNewline
        Write-Host " exists in VMM Library - " -NoNewline
        Try
        {
            $VHD = Get-SCVirtualHardDisk -Name $VHDName -ErrorAction Stop
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch
        {
            Write-Host "Failed" -ForegroundColor Red
            Exit
        }
        $CurrentTags = $VHD | select Tag
        [Array] $AllTags = $CurrentTags.Tag
        
                ForEach ($Tag in $Tags)
        {
            If ($AllTags -notcontains $Tag)
            {
                $AllTags += $Tag
            }
            Else
            {
                Write-Host "$VHDName already contains $Tag " -ForegroundColor Yellow -NoNewline
                Write-Host "Skipped" -ForegroundColor Green
            }
        }
        
        $empty = Set-SCVirtualHardDisk -VirtualHardDisk $VHD -Tag $AllTags
        $AllSetTags = Get-SCVirtualHardDisk -Name $VHDName | Select Tag
        ForEach ($Tag in $AllSetTags.Tag)
        {
            $Output = New-Object PSObject
            $Output | Add-Member -MemberType NoteProperty -Name VHD -Value $VHDName
            $Output | Add-Member -MemberType NoteProperty -Name Tag -Value $Tag
            $Output
        }
    }
    Else
    {
        Write-Host "Please specify tags in array format"
        Write-Host ' Example 1: @("WindowsServer2012","R2")'
        Write-Host ' Example 2: "WindowsServer", "R2"'
    }
}

Get-SCVMVHD
#Get-SCVMVHDTags -VHDName "Windows Server 2012 R2 Standard"
#Set-SCVMVHDTags -VHDName "Windows Server 2012 R2 Standard" -Tags "WindowsServer","R2"
#Add-SCVMVHDTags -VHDName "Windows Server 2012 R2 Standard" -Tags "Windows"
#Clear-SCVMVHDTags -VHDName "Windows Server 2012 R2 Standard"