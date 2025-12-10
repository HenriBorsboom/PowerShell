Clear-Host

Add-Type -AssemblyName System.Windows.Forms

$PlusOrMinus = 10

While ($True) {
    $p = [System.Windows.Forms.Cursor]::Position
    
    $x = $p.X + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    
    $y = $p.Y + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y + $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5

    $x = $p.X - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $x = $p.X - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5

    $y = $p.Y - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y - $PlusOrMinus
    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    start-sleep -Milliseconds 5
    $y = $p.Y - $PlusOrMinus
    start-sleep -Milliseconds 5

    [System.Windows.Forms.Cursor]::Position = New-Object System.Drawing.Point($x, $y)
    Write-Host ("X: " + $x.tostring())
    Write-Host ("Y: " + $y.tostring())
    For ($i = 0; $i -lt 5; $i ++) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
    }
    Write-Host ""
    $PlusOrMinus *= 1
}