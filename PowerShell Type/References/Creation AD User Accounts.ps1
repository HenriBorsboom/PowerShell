##Generate Preferred Name
$FirstName = ""
$LastName  = ""
$proposedUserName = "$FirstName.$LastName"

##Get Existing Matched Usernames
$FilterString = $proposedUserName + "*"
$SAMAccountNames = (Get-ADUser -Filter {SamAccountName -like $FilterString}).SAMAccountName

## Determine Alternative Names
# Get the preferred/desired name and the existing variants in use
$desiredName   = $proposedUserName
$existingNames = $SAMAccountNames

# Parse the existing names and extract a list of indexes in use, e.g. 1,2,3
$existingIndexList = $existingNames -split "," | ForEach-Object {$_.trim() -replace $desiredName,"" } | Where-Object {$_ -match "^\d+$"} | ForEach-Object {[int]$_}

# Determine the highest index in use by sorting
$lastIndex = $existingIndexList | Sort-Object | Select-Object -Last 1

# Increment to get next index and use this to create a proposed unique username
$availableIndex = $lastIndex + 1
$proposedName = $desiredName + $availableIndex