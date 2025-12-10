function DownloadFtpDirectory($url, $localPath)
{
    $listRequest = [Net.WebRequest]::Create($url)
    $listRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
    
    $lines = New-Object System.Collections.ArrayList

    $listResponse = $listRequest.GetResponse()
    $listStream = $listResponse.GetResponseStream()
    $listReader = New-Object System.IO.StreamReader($listStream)
    while (!$listReader.EndOfStream)
    {
        $line = $listReader.ReadLine()
        $lines.Add($line) | Out-Null
    }
    $listReader.Dispose()
    $listStream.Dispose()
    $listResponse.Dispose()

    #foreach ($line in $lines) 
    For ($LinesIndex = 0; $LinesIndex -lt $lines.Count; $LinesIndex ++)
    {
        $line = $lines[$LinesIndex]
        Write-Host (($LinesIndex + 1).ToString() + '/' + $Lines.Count.ToString() + " - ") -NoNewline

        $tokens = $line.Split(" ", 9, [StringSplitOptions]::RemoveEmptyEntries)
        $name = $tokens[8]
        $permissions = $tokens[0]

        $localFilePath = Join-Path $localPath $name
        $fileUrl = ($url + $name)

        if ($permissions[0] -eq 'd')
        {
            if (!(Test-Path $localFilePath -PathType container))
            {
                Write-Host "Creating directory $localFilePath"
                New-Item $localFilePath -Type directory | Out-Null
            }

            DownloadFtpDirectory ($fileUrl + "/") $localFilePath
        }
        else
        {
            Write-Host "Downloading $fileUrl to $localFilePath"

            $downloadRequest = [Net.WebRequest]::Create($fileUrl)
            $downloadRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
            
            $downloadResponse = $downloadRequest.GetResponse()
            $sourceStream = $downloadResponse.GetResponseStream()
            $targetStream = [System.IO.File]::Create($localFilePath)
            $buffer = New-Object byte[] 10240
            while (($read = $sourceStream.Read($buffer, 0, $buffer.Length)) -gt 0)
            {
                $targetStream.Write($buffer, 0, $read);
            }
            $targetStream.Dispose()
            $sourceStream.Dispose()
            $downloadResponse.Dispose()
        }
    }
}
#Use the function like:

#$credentials = New-Object System.Net.NetworkCredential("user", "mypassword") 
$url = "ftp://192.168.1.3:3721/Download/"
DownloadFtpDirectory $url "C:\temp\download"
<#The code is translated from my C# example in C# Download all files and subdirectories through FTP.

Using 3rd party library
If you want to avoid troubles with parsing the server-specific directory listing formats, use a 3rd party library that supports the MLSD command and/or parsing various LIST listing formats. And ideally with a support for downloading all files from a directory or even recursive downloads.

For example with WinSCP .NET assembly you can download whole directory with a single call to Session.GetFiles:

# Load WinSCP .NET assembly
Add-Type -Path "WinSCPnet.dll"

# Setup session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = "ftp.example.com"
    UserName = "user"
    Password = "mypassword"
}

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Download files
    $session.GetFiles("/directory/to/download/*", "C:\target\directory\*").Check()
}
finally
{
    # Disconnect, clean up
    $session.Dispose()
}    #>