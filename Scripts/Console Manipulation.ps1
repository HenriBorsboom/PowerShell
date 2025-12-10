#Clear-Host
function WriteTo-Pos (
        [string] $str, [int] $x = 0, [int] $y = 0,
        [string] $bgc = [console]::BackgroundColor,
        [string] $fgc = [Console]::ForegroundColor)
{
      if($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and
            $y -le [Console]::WindowHeight)
      {
            $saveY = [console]::CursorTop
            $offY = [console]::WindowTop       
            [console]::setcursorposition($x,$offY+$y)
            Write-Host -Object $str -BackgroundColor $bgc `
                  -ForegroundColor $fgc -NoNewline
            [console]::setcursorposition(0,$saveY)
      }
}

function WriteTo-Pos2 (
        [string] $str, [int] $x = 0, [int] $y = 0,
        [string] $bgc = [console]::BackgroundColor,
        [string] $fgc = [Console]::ForegroundColor)
{
      if($x -ge 0 -and $y -ge 0 -and $x -le [Console]::WindowWidth -and
            $y -le [Console]::WindowHeight)
      {
            $saveY = [console]::CursorTop
            $offY = [console]::WindowTop       
            [console]::setcursorposition($x,$y)
            Write-Host -Object $str -NoNewline
            [console]::setcursorposition(0,$saveY)
      }
}

Write-Host "Hello World! ..." -NoNewline
[console]::setcursorposition(1,1)
Write-Host "."