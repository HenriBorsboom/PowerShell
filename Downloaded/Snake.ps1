#requires -version 2
<#
#
# Powershell Snake Game
# Author : Kurt Jaegers
#
#>
<#
# Draws the snake to the screen, including cleaning up the last segment of the tail
#>
Function DrawTheSnake {
    # Erase the tail segment that is disappearing
    $rui.cursorposition = $tail[0]
    Write-Host -ForegroundColor White -BackgroundColor Black -NoNewline " " 
 
    # Shift all of the tail segments down one
    For ($i=0; $i -lt ($tailLength - 1); $i++) {
        $tail[$i].x = $tail[$i+1].x
        $tail[$i].y = $tail[$i+1].y
    }
 
    # Set the last segment of the tail to the current position
    $tail[-1].x = $coord.x
    $tail[-1].y = $coord.y
  
    # Draw all segments of the snake  
    For ($i=0; $i -lt $tailLength; $i++) {
        $rui.cursorposition = $tail[$i]
        write-host -foregroundcolor white -backgroundcolor white -NoNewline " "
    }
}
<#
# Generate a random location for the apple, making sure it isnt inside the snake
#>
Function MoveTheApple { 
    $ok = $true;
    Do {
        $script:apple.x = Get-Random -Minimum 2 -Maximum ($rui.WindowSize.width - 2)
        $script:apple.y = Get-Random -Minimum 2 -Maximum ($rui.WindowSize.height - 2)
        $ok=$true
        For ($i=0; $i -lt $tailLength; $i++) {
            If (($tail[$i].x -eq $apple.x) -and ($tail[$i].y -eq $apple.y)) {
                $ok=$false;
            }
        }
    } 
    While (!$ok)
}
<#
# Draw the apple to the screen
#>
Function DrawTheApple {
    $rui.CursorPosition = $apple
    Write-Host -ForegroundColor Red -BackgroundColor Black "@"
}
<#
# Check to see if the snake hits the apple
#>
Function CheckAppleHit {
    # if the x/y of the head matches the x/y of the apple, we hit the apple
    If (($tail[-1].x -eq $apple.x) -and ($tail[-1].y -eq $apple.y)) {
        # relocate the apple
        MoveTheApple
    
        $score += 500
    
        # Add to the snake's length
        $script:tailLength++
        $script:tail += New-Object System.Management.Automation.Host.Coordinates
        $script:tail[-1].x = $coord.x
        $script:tail[-1].y = $coord.y
    }
}
<#
# Check to see if the snake's head hits the walls of the screen
#>
Function CheckWallHits {
    If (($coord.x -eq 0) -or ($coord.y -eq 0) -or ($coord.x -eq $host.ui.rawui.windowsize.width-1) -or ($coord.y -eq $host.ui.rawui.windowsize.height-1)) {
        Clear-Host
        Write-Host -ForegroundColor Red "You lost! Score was $score"
        exit
    }
}
<#
# Draw a fence around the edges of the screen
#>
Function DrawScreenBorders {
    $cur = New-Object System.Management.Automation.Host.Coordinates
    $cur.x=0
    $cur.y=0
  
    For ($x=0; $x -lt $host.ui.rawui.windowsize.width; $x++) {
        $cur.x=$x
        $cur.y=0
        $host.ui.rawui.cursorposition = $cur
        Write-Host -ForegroundColor Black -BackgroundColor White -NoNewline "#"

        $cur.y=$host.ui.rawui.windowsize.height-1
        $host.ui.rawui.cursorposition = $cur
        Write-Host -ForegroundColor Black -BackgroundColor White -NoNewline "#"
    }
  
    For ($y=0; $y -lt $host.ui.rawui.windowsize.height-1; $y++) {
        $cur.y=$y
        $cur.x=0
        $host.ui.rawui.cursorposition = $cur
        Write-Host -ForegroundColor Black -BackgroundColor White -NoNewline "#"

        $cur.x=$host.ui.rawui.windowsize.width-1
        $host.ui.rawui.cursorposition = $cur
        Write-Host -ForegroundColor Black -BackgroundColor White -NoNewline "#"
    }  
}
Function CheckSnakeBodyHits {
    For ($i=0; $i -lt $tailLength -1; $i++) {
        If (($tail[$i].x -eq $coord.x) -and ($tail[$i].y -eq $coord.y)) {
            Clear-Host
            Write-Host -ForegroundColor Red "You lost! Score was $score"
            Exit
        }
    }
}
#Function Main {
    # ---------------------------------
    # ---------------------------------
    # Main script block starts here
    # ---------------------------------
    # ---------------------------------

    If ($host.name -ne "ConsoleHost") {
      Write-Host "This script should only be run in a ConsoleHost window (outside of the ISE)"
      Exit
      $done=$true
    } 

    # Grab UI objects and set some colors
    $ui=(Get-Host).ui
    $rui=$ui.rawui
    $rui.BackgroundColor="Black"
    $rui.ForegroundColor="Red"
    Clear-Host

    # write out lines to make sure the buffer is big enough to cover the screen
    For ($i=0; $i -lt $rui.screensize.height; $i++) {
        write-host "" 
    }
    $coord = $rui.CursorPosition
    $save = $coord
    $cs = $rui.cursorsize
    $rui.cursorsize=0
    $score = 0

    $done = $false

    $before = 0
    $after  = 15
    $dir = 0

    $coord.X = $rui.screensize.width/2
    $coord.y = $rui.screensize.height/2

    $coord.x = 80
    $coord.Y = 15
    $apple = New-Object System.Management.Automation.Host.Coordinates
    DrawScreenBorders;
    MoveTheApple;

    $tail = @()
    $tailLength = 5

    For ($i=0; $i -lt $tailLength; $i++) {
      $tail += New-Object System.Management.Automation.Host.Coordinates
      $tail[$i].x = $coord.x
      $tail[$i].y = $coord.y
    }

    While (!$done) {
        If ($rui.KeyAvailable) {
            $key = $rui.ReadKey()
            If ($key.virtualkeycode -eq -27) { $done=$true }
            If ($key.keydown) { 
                If ($key.virtualkeycode -eq 37) { $dir=0 } # Left
                If ($key.virtualkeycode -eq 38) { $dir=1 } # Up
                If ($key.virtualkeycode -eq 39) { $dir=2 } # Right
                If ($key.virtualkeycode -eq 40) { $dir=3 } # Down
            }
        }
        If ($dir -eq 0) { $coord.x--; }
        If ($dir -eq 1) { $coord.y--; }
        If ($dir -eq 2) { $coord.x++; }
        If ($dir -eq 3) { $coord.y++; }
        DrawTheApple;
        DrawTheSnake;
        CheckWallHits;
        CheckSnakeBodyHits;
        CheckAppleHit;
    
        Start-Sleep -Milliseconds 100
  
        $score += $tailLength;
    }

    $rui.cursorsize=$cs
#}
#Main