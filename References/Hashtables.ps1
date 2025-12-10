$test1 = @{
    "service1" = "auto";
    "Service2" = "manual";
    "Service3" = "disable";
}

Foreach ($Object in $Test1.GetEnumerator()) {
    Write-Host $Object.Key
    Write-Host $Object.Value
    Sleep 1
}