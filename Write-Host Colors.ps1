$Colors = @(
    "Black", `
    "DarkBlue", `
    "DarkGreen", `
    "DarkCyan", `
    "DarkRed", `
    "DarkMagenta", `
    "DarkYellow", `
    "Gray", `
    "DarkGray", `
    "Blue", `
    "Green", `
    "Cyan", `
    "Red", `
    "Magenta", `
    "Yellow", `
    "White")

ForEach ($Color in $Colors) {
    Write-Host "This color is $Color" -ForegroundColor $Color
}