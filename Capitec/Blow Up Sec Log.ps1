For ($i = 1; $i -lt 1000000000; $i ++) {
    Write-Output ('Writing File ' + $i.Tostring())
    "Hello World" | Out-File ('J:\File' + $i.ToString() + '.txt') -Encoding ascii
    Start-Sleep -Milliseconds 10
}