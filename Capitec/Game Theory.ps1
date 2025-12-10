# Function for Player 1's choice
Function Player1 {
    Param (
        [string]$Choice # "Agree" or "Disagree"
    )
    return $Choice
}

# Function for Player 2's choice
Function Player2 {
    Param (
        [string]$Choice # "Agree" or "Disagree"
    )
    return $Choice
}

# Function to calculate points based on choices
Function CalculatePoints {
    Param (
        [string]$Player1Choice,
        [string]$Player2Choice
    )

    # Initialize points
    $Player1Points = 0
    $Player2Points = 0

    # Apply game rules
    if ($Player1Choice -eq "Agree" -and $Player2Choice -eq "Agree") {
        $Player1Points = 5
        $Player2Points = 5
    }
    elseif ($Player1Choice -eq "Disagree" -and $Player2Choice -eq "Disagree") {
        $Player1Points = 1
        $Player2Points = 1
    }
    elseif ($Player1Choice -eq "Agree" -and $Player2Choice -eq "Disagree") {
        $Player1Points = 0
        $Player2Points = 5
    }
    elseif ($Player1Choice -eq "Disagree" -and $Player2Choice -eq "Agree") {
        $Player1Points = 5
        $Player2Points = 0
    }

    # Return points as a hashtable
    return @{
        Player1 = $Player1Points
        Player2 = $Player2Points
    }
}

# Main game logic
Function PlayGame {
    # Prompt players for their choices
    $Player1Choice = Read-Host "Player 1, enter your choice (Agree/Disagree)"
    $Player2Choice = Read-Host "Player 2, enter your choice (Agree/Disagree)"

    # Validate input
    if (($Player1Choice -notin @("Agree", "Disagree")) -or ($Player2Choice -notin @("Agree", "Disagree"))) {
        Write-Host "Invalid input. Please enter 'Agree' or 'Disagree'." -ForegroundColor Red
        return
    }

    # Calculate points
    $Points = CalculatePoints -Player1Choice $Player1Choice -Player2Choice $Player2Choice

    # Display results
    Write-Host "Player 1 chose: $Player1Choice"
    Write-Host "Player 2 chose: $Player2Choice"
    Write-Host "Player 1 points: $($Points.Player1)"
    Write-Host "Player 2 points: $($Points.Player2)"
}

# Start the game
PlayGame