







Try {
    $t = 100/0
}
Catch {
    $e = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    $msg = $e.Message 

    Write-Host -ForegroundColor Red "caught exception: $e at $line"
}