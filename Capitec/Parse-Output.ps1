    Param (
        $Output
    )
    # Parse the output
    $lines = $output -split "`n"

    # Define sections
    $appliedGPOs = @()
    $filteredGPOs = @()
    $securityGroups = @()

    # Flag to determine current section
    $currentSection = ""

    foreach ($line in $lines) {
        if ($line -match "Applied Group Policy Objects") {
            $currentSection = "Applied"
            continue
        }
        elseif ($line -match "The following GPOs were not applied because they were filtered out") {
            $currentSection = "Filtered"
            continue
        }
        elseif ($line -match "The computer is a part of the following security groups") {
            $currentSection = "SecurityGroups"
            continue
        }

        # Process lines based on the current section
        switch ($currentSection) {
            "Applied" {
                if ($line.Trim() -ne "") {
                    $appliedGPOs += $line.Trim()
                }
            }
            "Filtered" {
                if ($line.Trim() -match "Filtering:") {
                    $filteredGPOs += $line.Trim()
                }
                elseif ($line.Trim() -ne "") {
                    $filteredGPOs += $line.Trim() + " (Filtered)"
                }
            }
            "SecurityGroups" {
                if ($line.Trim() -ne "") {
                    $securityGroups += $line.Trim()
                }
            }
        }
    }

    # Create a table for applied GPOs
    $AppliedGPOs = $appliedGPOs | ForEach-Object { [PSCustomObject]@{ AppliedGPO = $_ } }
    $ReturnAppliedGPOs = $appliedGPOs | Where AppliedGPO -like '*wsus*'
    # Create a table for filtered GPOs
    $FilteredGPOs = $filteredGPOs | ForEach-Object { [PSCustomObject]@{ FilteredGPO = $_ } }
    $ReturnFilteredGPOs = $filteredGPOs | Where FilteredGPO -like '*wsus*'
    # Create a table for security groups
    #$securityGroups | ForEach-Object { [PSCustomObject]@{ Group = $_ } }
    Return $ReturnAppliedGPOs, $ReturnFilteredGPOs