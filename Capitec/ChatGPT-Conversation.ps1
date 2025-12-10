# AIzaSyDlVr014uE34kCCYT6eIhlAQhIk4Zf2D48
Function Gemini {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $Request
    )
   $Result = curl https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=AIzaSyDlVr014uE34kCCYT6eIhlAQhIk4Zf2D48 -H 'Content-Type: application/json' -X POST -d ('{"contents": [{"parts":[{"text": "' + $Request + '"}]}]}')
   If (($Result | ConvertFrom-Json).candidates.Content.parts.text -eq $null -or ($Result | ConvertFrom-Json).candidates.Content.parts.text -eq '') {
        Write-Warning 'Something went wrong'
        $Result
   }
   Else {
    ($Result | ConvertFrom-Json).candidates.Content.parts.text
   }
}