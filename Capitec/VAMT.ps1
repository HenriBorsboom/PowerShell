# Save Unknown Status to C:\Temp\File.xml
# Read the content of the file
$File = Get-Content C:\temp\file.xml
# Convert the contect to XML and get Computers
$Computers = ([XML] $File).SoftwareLicensingData.computers.Computer

$Details = @()
ForEach ($Server in $Computers) {
    $Details += ,(Get-ADComputer $Server -Properties *)
}
$Details | Out-Gridview