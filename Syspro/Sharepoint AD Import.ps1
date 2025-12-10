Function Temp1 {
$SPProperties = @(
    "AreaOfInterest", 
    "CompName", 
    "Country", 
    "DateCreated", 
    "DateUpdated", 
    "Disclaimer", 
    "Email", 
    "FirstName", 
    "Format", 
    "Fullname", 
    "HasAppStore", 
    "HasCertification", 
    "IsPrimaryContact", 
    "IsSlcOnly", 
    "IsThirdPartyVendor", 
    "JobTitle", 
    "LastAccess", 
    "LastName", 
    "Newsletter", 
    "OrganizationCode", 
    "Pending", 
    "RANotes", 
    "Region", 
    "RegistrationDate", 
    "StateOrProvince", 
    "SupportComp", 
    "SYSPROVersion", 
    "SZLevel", 
    "SZPassword", 
    "Telephone", 
    "UserID", 
    "Username")
$SPUsers = Import-Csv -Delimiter "," -Path C:\temp\SharePoint\InfoZoneDev_Extract.csv

$UniqueList = @()

For ($i = 0; $i -lt $SPProperties.Count; $i ++) {
    $CurrentHeader = $SPProperties[$i]
    Write-Host (($i + 1).ToString() + "/" + $SPProperties.Count.ToString()) -ForegroundColor Cyan -NoNewline; Write-Host " - Processing " -NoNewline; Write-Host $CurrentHeader -NoNewline -ForegroundColor Yellow; Write-Host " - " -NoNewline
    $Uniques = $SPUsers.$CurrentHeader | Select -Unique
    $List = New-Object PSObject -Property @{
        Header = $CurrentHeader
        Items  = $Uniques
        Count  = $Uniques.Count
    }
    $UniqueList = $UniqueList + $List
    Write-Host "Complete" -ForegroundColor Green
}
$UniqueList | Select Header, Count, Items
}
Function Temp2 {
$ADUserDetails = New-Object PSObject -Property @{ 
    City           = $ADUsers[$Index].Region
    Company        = $ADUsers[$Index].CompName
    Country        = $ADUsers[$Index].Country
    ADCountry      = $ADCountry
    Description    = ""
    DisplayName    = $ADUsers[$Index].Fullname
    EmailAddress   = $ADUsers[$Index].Email
    HomePhone      = $ADUsers[$Index].Telephone
    Name           = ($ADUsers[$Index].FirstName + " " + $ADUsers[$Index].LastName)
    Password       = $ADUsers[$Index].SZPassword
    SecurePassword = $ADSecurePassword
    Surname        = $ADUsers[$Index].LastName
    Title          = $ADUsers[$Index].JobTitle
    MemberOf       = $ADUsers[$Index].SZLevel
    Enabled        = $Enabled
    Pending        = $ADUsers[$Index].Pending
    ADPath         = $ADPath
    Group          = $ADMemberOf
    SAMAccount     = $ADUsers[$Index].UserID
}
<#
AreaOfInterest     - AreaOfInterest        - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.1
DateCreated        - SPPP_DateCreated      - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.2
DateUpdated        - SPPP_DateUpdated      - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.3
Disclaimer         - Disclaimer            - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.4
Format             - Format                - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.5
HasAppStore        - HasAppStore           - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.6
HasCertification   - HasCertification      - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.7
IsPrimaryContact   - IsPrimaryContact      - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.8
IsSlcOnly          - SPPP_IsSlcOnly        - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.9
IsThirdPartyVendor - IsThirdPartyVendor    - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.10
LastAccess         - SPPP_LastAccess       - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.11
Newsletter         - Newsletter            - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.12
OrganizationCode   - OrganizationCode      - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.13
Pending            - Pending               - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.14
RANotes            - RANotes               - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.15
RegistrationDate   - SPPP_RegistrationDate - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.16
SupportComp        - SupportComp           - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.17
SYSPROVersion      - SYSPROVersion         - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.18
UserID             - SPPP_UserID           - 1.2.840.113556.1.8000.2554.38346.1093.40221.17934.32999.93130.10080694.19
#>
}
Function Create-ADStructure {
    Param ($Action)

    Function Create-OUStructure {
        New-ADOrganizationalUnit -Name "SharePoint Partner Portal" -DisplayName "SharePoint Partner Portal" -Path "DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "Africa" -DisplayName "Africa" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users"  -DisplayName "Users"  -Path "OU=Africa,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=Africa,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "Asia Pacific" -DisplayName "Asia Pacific" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users"  -DisplayName "Users"  -Path "OU=Asia Pacific,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=Asia Pacific,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "Canada" -DisplayName "Canada" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users"  -DisplayName "Users"  -Path "OU=Canada,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=Canada,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "Europe" -DisplayName "Europe" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users"  -DisplayName "Users"  -Path "OU=Europe,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=Europe,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "United States" -DisplayName "United States" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users"  -DisplayName "Users"  -Path "OU=United States,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=United States,OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    
        New-ADOrganizationalUnit -Name "Groups" -DisplayName "Groups" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
        New-ADOrganizationalUnit -Name "Users" -DisplayName "Users" -Path "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Verbose
    }
    Function Create-SecurityGroups {
        $AfricaCN = "OU=Groups,OU=Africa,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $AfricaGroups = @(
        "Africa Superusers",
        "Africa SYSPRO",
        "Africa Users",
        "Africa VARs")

        $AsiaCN = "OU=Groups,OU=Asia Pacific,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $AsiaGroups = @(
        "Asia Pacific Superusers",
        "Asia Pacific SYSPRO",
        "Asia Pacific Users",
        "Asia Pacific VARs")

        $CanadaCN = "OU=Groups,OU=Canada,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $CanadaGroups = @(
        "Canada Superusers", 
        "Canada SYSPRO", 
        "Canada Users", 
        "Canada VARs")

        $EuropeCN = "OU=Groups,OU=Europe,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $EuropeGroups = @(
        "Europe Superusers", 
        "Europe SYSPRO", 
        "Europe Users", 
        "Europe VARs")

        $USACN = "OU=Groups,OU=United States,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $USAGroups = @(
        "United States Superusers",
        "United States SYSPRO",
        "United States Users",
        "United States VARs")

        $SPCN = "OU=Groups,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
        $SPGroups = @(
        "SLC",
        "POS Support", 
        "Customer Search", 
        "Unknown")

        For ($i = 0; $i -lt $AfricaGroups.Count; $i ++) {
            New-ADGroup -Name $AfricaGroups[$i] -DisplayName $AfricaGroups[$i] -Path $AfricaCN -GroupScope Global -GroupCategory Security  -Verbose
        }
        For ($i = 0; $i -lt $AsiaGroups.Count; $i ++) {
            New-ADGroup -Name $AsiaGroups[$i] -DisplayName $AsiaGroups[$i] -Path $AsiaCN -GroupScope Global -GroupCategory Security -Verbose
        }
        For ($i = 0; $i -lt $CanadaGroups.Count; $i ++) {
            New-ADGroup -Name $CanadaGroups[$i] -DisplayName $CanadaGroups[$i] -Path $CanadaCN -GroupScope Global -GroupCategory Security -Verbose
        }
        For ($i = 0; $i -lt $EuropeGroups.Count; $i ++) {
            New-ADGroup -Name $EuropeGroups[$i] -DisplayName $EuropeGroups[$i] -Path $EuropeCN -GroupScope Global -GroupCategory Security -Verbose
        }
        For ($i = 0; $i -lt $USAGroups.Count; $i ++) {
            New-ADGroup -Name $USAGroups[$i] -DisplayName $USAGroups[$i] -Path $USACN -GroupScope Global -GroupCategory Security -Verbose
        }
        For ($i = 0; $i -lt $SPGroups.Count; $i ++) {
            New-ADGroup -Name $SPGroups[$i] -DisplayName $SPGroups[$i] -Path $SPCN -GroupScope Global -GroupCategory Security -Verbose
        }
    }
    Function Remove-AccidentalDeletion {
        $OUs = @(
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Africa,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Africa,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Asia Pacific,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Asia Pacific,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Canada,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Canada,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Europe,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=Europe,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=United States,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=United States,OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net"
            "OU=SharePoint Partner Portal,DC=sysproza,DC=net")

        For ($OUIndex = 0; $OUIndex -lt $OUs.Count; $OUIndex ++) {
            Try {
                Write-Host (($OUIndex + 1).ToString() + "/" + $OUs.Count.ToString()) -ForegroundColor Cyan -NoNewline ;Write-Host " - Removing Accidental Deletion from " -NoNewline; Write-Host $OUs[$OUIndex] -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
                Set-ADOrganizationalUnit -ProtectedFromAccidentalDeletion:$false -Identity $Ous[$OUIndex]
                Write-Host "Complete" -ForegroundColor Green
            }
            Catch {
                Write-Host "Failed" -ForegroundColor Red
            }
        }
    }
    Function Delete-OUs {
        Try {
            Write-Host "Deleting " -NoNewline; Write-Host "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -ForegroundColor Yellow -NoNewline; Write-Host " recursively - " -NoNewline
            Remove-ADOrganizationalUnit -Identity "OU=SharePoint Partner Portal,DC=sysproza,DC=net" -Recursive -Confirm:$false
            Write-Host "Complete" -ForegroundColor Green
        }
        Catch {
            Write-Host "Failed" -ForegroundColor Red
        }
    }

    Switch ($Action) {
        "Create" {
            Create-OUStructure
            Create-SecurityGroups
        }
        "Delete" {
            Remove-AccidentalDeletion
            Delete-OUs
        }
    }
}
Function Create-User {
    Param ($ADUserDetails)
    Function User {
        Param ($ADUserDetails)

        Try {
            Write-Host "Creating " -NoNewline; Write-Host $ADUserDetails.Name -NoNewline -ForegroundColor Yellow; Write-Host " - " -NoNewline
            New-ADUser `
                -City $ADUserDetails.City `
                -Company $ADUserDetails.Company `
                -Country $ADUserDetails.ADCountry `
                -Description $ADUserDetails.Description `
                -DisplayName $ADUserDetails.DisplayName `
                -EmailAddress $ADUserDetails.EmailAddress `
                -HomePhone $ADUserDetails.HomePhone `
                -GivenName $ADUserDetails.Name `
                -Name $ADUserDetails.Name `
                -AccountPassword $ADUserDetails.SecurePassword `
                -Surname $ADUserDetails.Surname `
                -Title $ADUserDetails.Title `
                -Enabled $ADUserDetails.Enabled `
                -Path $ADUserDetails.ADPath `
                -SAMAccount $ADUserDetails.SAMAccount `
                -State $ADUserDetails.State
            Write-Host "Complete" -ForegroundColor Green -NoNewline; Write-Host " - " -NoNewline
            Return $True
        }
        Catch {
            Write-Host "$_" -ForegroundColor Red -NoNewline; Write-Host " - " -NoNewline
            Return $_
        }
    }
    Function Properties {
        Param ($ADUserDetails)

        Try {
            Write-Host "Setting Properties - " -NoNewline; 
                Set-ADUser -Identity $ADUserDetails.SAMAccount -Add @{`
                    AreaOfInterest        = $ADUserDetails.Properties.AreaOfInterest
                    Disclaimer            = $ADUserDetails.Properties.Disclaimer
                    Format                = $ADUserDetails.Properties.Format
                    HasAppStore           = $ADUserDetails.Properties.HasAppStore
                    HasCertification      = $ADUserDetails.Properties.HasCertification
                    IsPrimaryContact      = $ADUserDetails.Properties.IsPrimaryContact
                    IsThirdPartyVendor    = $ADUserDetails.Properties.IsThirdPartyVendor
                    Newsletter            = $ADUserDetails.Properties.Newsletter
                    OrganizationCode      = $ADUserDetails.Properties.OrganizationCode
                    Pending               = $ADUserDetails.Properties.Pending
                    RANotes               = $ADUserDetails.Properties.RANotes
                    sPPPDateCreated       = $ADUserDetails.Properties.SPPP_DateCreated
                    sPPPDateUpdated       = $ADUserDetails.Properties.SPPP_DateUpdated
                    sPPPIsSlcOnly         = $ADUserDetails.Properties.SPPP_IsSlcOnly
                    sPPPLastAccess        = $ADUserDetails.Properties.SPPP_LastAccess
                    sPPPRegistrationDate  = $ADUserDetails.Properties.SPPP_RegistrationDate
                    SPPPUserID            = $ADUserDetails.Properties.SPPP_UserID
                    SupportComp           = $ADUserDetails.Properties.SupportComp
                    SYSPROVersion         = $ADUserDetails.Properties.SYSPROVersion
                }
            Write-Host "Complete" -ForegroundColor Green -NoNewline; Write-Host " - " -NoNewline
            Return $True
        }
        Catch {
            Write-Host "$_" -ForegroundColor Red -NoNewline; Write-Host " - " -NoNewline
            Return $_
        }
    }
    Function GroupMember {
        Param ($ADUserDetails)

        Try {
            Write-Host "Adding to group - " -NoNewline;
            Add-ADGroupMember -Identity $ADUserDetails.Group -Members $ADUserDetails.SAMAccount
            Write-Host "Complete" -ForegroundColor Green
            Return $True
        }
        Catch {
            Write-Host "$_" -ForegroundColor Red
            Return $_
        }

    }

    $Success = $false
    $UserSuccess        = User -ADUserDetails $ADUserDetails
    $PropertiesSuccess  = Properties -ADUserDetails $ADUserDetails
    $GroupMemberSuccess = GroupMember -ADUserDetails $ADUserDetails
    If ($UserSuccess -ne $true -or $PropertiesSuccess -ne $true -or $GroupMemberSuccess -ne $true) { $Failure = $true } Else {$Failure = $false}
    $Success = New-Object PSObject -Property @{
        User        = $UserSuccess
        Properties  = $PropertiesSuccess
        GroupMember = $GroupMemberSuccess
        Failure     = $Failure
    }
    Return $Success
}
Function Process-Users {
    $File = "C:\temp\SharePoint\InfoZoneDev_Extract.csv"
    $FailedUsers = @()
    $ADCountries = @(
        "Afghanistan"
        "Åland Islands"
        "Albania"
        "Algeria"
        "American Samoa"
        "Andorra"
        "Angola"
        "Anguilla"
        "Antarctica"
        "Antigua and Barbuda"
        "Argentina"
        "Armenia"
        "Aruba"
        "Australia"
        "Austria"
        "Azerbaijan"
        "Bahamas (the)"
        "Bahrain"
        "Bangladesh"
        "Barbados"
        "Belarus"
        "Belgium"
        "Belize"
        "Benin"
        "Bermuda"
        "Bhutan"
        "Bolivia (Plurinational State of)"
        "Bonaire, Sint Eustatius and Saba"
        "Bosnia and Herzegovina"
        "Botswana"
        "Bouvet Island"
        "Brazil"
        "British Indian Ocean Territory (the)"
        "Brunei Darussalam"
        "Bulgaria"
        "Burkina Faso"
        "Burundi"
        "Cabo Verde"
        "Cambodia"
        "Cameroon"
        "Canada"
        "Cayman Islands (the)"
        "Central African Republic (the)"
        "Chad"
        "Chile"
        "China"
        "Christmas Island"
        "Cocos (Keeling) Islands (the)"
        "Colombia"
        "Comoros (the)"
        "Congo (the Democratic Republic of the)"
        "Congo (the)"
        "Cook Islands (the)"
        "Costa Rica"
        "Côte d’Ivoire"
        "Croatia"
        "Cuba"
        "Curaçao"
        "Cyprus"
        "Czech Republic (the)"
        "Denmark"
        "Djibouti"
        "Dominica"
        "Dominican Republic (the)"
        "Ecuador"
        "Egypt"
        "El Salvador"
        "Equatorial Guinea"
        "Eritrea"
        "Estonia"
        "Ethiopia"
        "Falkland Islands (the) [Malvinas]"
        "Faroe Islands (the)"
        "Fiji"
        "Finland"
        "France"
        "French Guiana"
        "French Polynesia"
        "French Southern Territories (the)"
        "Gabon"
        "Gambia (the)"
        "Georgia"
        "Germany"
        "Ghana"
        "Gibraltar"
        "Greece"
        "Greenland"
        "Grenada"
        "Guadeloupe"
        "Guam"
        "Guatemala"
        "Guernsey"
        "Guinea"
        "Guinea-Bissau"
        "Guyana"
        "Haiti"
        "Heard Island and McDonald Islands"
        "Holy See (the)"
        "Honduras"
        "Hong Kong"
        "Hungary"
        "Iceland"
        "India"
        "Indonesia"
        "Iran (Islamic Republic of)"
        "Iraq"
        "Ireland"
        "Isle of Man"
        "Israel"
        "Italy"
        "Jamaica"
        "Japan"
        "Jersey"
        "Jordan"
        "Kazakhstan"
        "Kenya"
        "Kiribati"
        "Korea (the Democratic People’s Republic of)"
        "Korea (the Republic of)"
        "Kuwait"
        "Kyrgyzstan"
        "Lao People’s Democratic Republic (the)"
        "Latvia"
        "Lebanon"
        "Lesotho"
        "Liberia"
        "Libya"
        "Liechtenstein"
        "Lithuania"
        "Luxembourg"
        "Macao"
        "Macedonia (the former Yugoslav Republic of)"
        "Madagascar"
        "Malawi"
        "Malaysia"
        "Maldives"
        "Mali"
        "Malta"
        "Marshall Islands (the)"
        "Martinique"
        "Mauritania"
        "Mauritius"
        "Mayotte"
        "Mexico"
        "Micronesia (Federated States of)"
        "Moldova (the Republic of)"
        "Monaco"
        "Mongolia"
        "Montenegro"
        "Montserrat"
        "Morocco"
        "Mozambique"
        "Myanmar"
        "Namibia"
        "Nauru"
        "Nepal"
        "Netherlands (the)"
        "New Caledonia"
        "New Zealand"
        "Nicaragua"
        "Niger (the)"
        "Nigeria"
        "Niue"
        "Norfolk Island"
        "Northern Mariana Islands (the)"
        "Norway"
        "Oman"
        "Pakistan"
        "Palau"
        "Palestine, State of"
        "Panama"
        "Papua New Guinea"
        "Paraguay"
        "Peru"
        "Philippines (the)"
        "Pitcairn"
        "Poland"
        "Portugal"
        "Puerto Rico"
        "Qatar"
        "Réunion"
        "Romania"
        "Russian Federation (the)"
        "Rwanda"
        "Saint Barthélemy"
        "Saint Helena, Ascension and Tristan da Cunha"
        "Saint Kitts and Nevis"
        "Saint Lucia"
        "Saint Martin (French part)"
        "Saint Pierre and Miquelon"
        "Saint Vincent and the Grenadines"
        "Samoa"
        "San Marino"
        "Sao Tome and Principe"
        "Saudi Arabia"
        "Senegal"
        "Serbia"
        "Seychelles"
        "Sierra Leone"
        "Singapore"
        "Sint Maarten (Dutch part)"
        "Slovakia"
        "Slovenia"
        "Solomon Islands"
        "Somalia"
        "South Africa"
        "South Georgia and the South Sandwich Islands"
        "South Sudan"
        "Spain"
        "Sri Lanka"
        "Sudan (the)"
        "Suriname"
        "Svalbard and Jan Mayen"
        "Swaziland"
        "Sweden"
        "Switzerland"
        "Syrian Arab Republic"
        "Taiwan (Province of China)"
        "Tajikistan"
        "Tanzania, United Republic of"
        "Thailand"
        "Timor-Leste"
        "Togo"
        "Tokelau"
        "Tonga"
        "Trinidad and Tobago"
        "Tunisia"
        "Turkey"
        "Turkmenistan"
        "Turks and Caicos Islands (the)"
        "Tuvalu"
        "Uganda"
        "Ukraine"
        "United Arab Emirates (the)"
        "United Kingdom of Great Britain and Northern Ireland (the)"
        "United States Minor Outlying Islands (the)"
        "United States of America (the)"
        "Uruguay"
        "Uzbekistan"
        "Vanuatu"
        "Venezuela (Bolivarian Republic of)"
        "Viet Nam"
        "Virgin Islands (British)"
        "Virgin Islands (U.S.)"
        "Wallis and Futuna"
        "Western Sahara*"
        "Yemen"
        "Zambia"
        "Zimbabwe")
    Write-Host "Getting contents of " -NoNewline; Write-Host $File -ForegroundColor Yellow -NoNewline; Write-Host " - " -NoNewline
    $ADUsers = Import-Csv -Delimiter "," -Path $File
    Write-Host "Complete" -ForegroundColor Green
    For ($Index = 0; $Index -lt $ADUsers.Count; $Index ++) {

        #region Validate Details
        ##Country
        If ($ADCountries.Contains($ADUsers[$Index].Country)) { $ADCountry = $ADUsers[$Index].Country }
        Else { $ADCountry = "" }
        ##Enabled
        If ($ADUsers[$Index].Pending -like "*no") { $Enabled = $True }
        Else { $Enabled = $false }
        ##SecuredPassword
        If ($ADUsers[$Index].SZPassword -ne "") { $ADSecurePassword = ConvertTo-SecureString -String $ADUsers[$Index].SZPassword -AsPlainText -Force }
        ##Groups
        Switch ($ADUsers[$Index].Region) {
            "South Africa" {
                $ADPath = "OU=Users,OU=Africa,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "Africa Users"
                    }
                    "super_user" {
                        $ADMemberOf = "Africa Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "Africa SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "Africa VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            "Canada" {
                $ADPath = "OU=Users,OU=Canada,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "Canada Users"
                    }
                    "super_user" {
                        $ADMemberOf = "Canada Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "Canada SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "Canada VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            "United States" {
                $ADPath = "OU=United States,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "United States Users"
                    }
                    "super_user" {
                        $ADMemberOf = "United States Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "United States SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "United States VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            "Europe" {
                $ADPath = "OU=Users,OU=Europe,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "Europe Users"
                    }
                    "super_user" {
                        $ADMemberOf = "Europe Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "Europe SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "Europe VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            "Australasia" {
                $ADPath = "OU=Users,OU=Asia Pacific,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "Asia Pacific Users"
                    }
                    "super_user" {
                        $ADMemberOf = "Asia Pacific Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "Asia Pacific SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "Asia Pacific VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            "Gauteng-ZA" {
                $ADPath = "OU=Users,OU=Africa,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                Switch ($ADUsers[$Index].SZLevel) {
                    "user" {
                        $ADMemberOf = "Africa Users"
                    }
                    "super_user" {
                        $ADMemberOf = "Africa Superusers"
                    }
                    "distributor" {
                        $ADMemberOf = "Africa SYSPRO"
                    }
                    "dealer" {
                        $ADMemberOf = "Africa VARS"
                    }
                    Default {
                        $ADMemberOf = "Unknown"
                    }
                }
            }
            Default {
                $ADPath = "OU=Users,OU=Sharepoint Partner Portal,DC=sysproza,DC=net"
                $ADMemberOf = "Unknown"
            }
        }
        
        ##Properties
        If ($ADUsers[$Index].AreaOfInterest -eq "") { $ADUsers[$Index].AreaOfInterest = "NULL" }
        If ($ADUsers[$Index].DateCreated -eq "") { $ADUsers[$Index].DateCreated = "NULL" }
        If ($ADUsers[$Index].DateUpdated -eq "") { $ADUsers[$Index].DateUpdated = "NULL" }
        If ($ADUsers[$Index].Disclaimer -eq "") { $ADUsers[$Index].Disclaimer = "NULL" }
        If ($ADUsers[$Index].Format -eq "") { $ADUsers[$Index].Format = "NULL" }
        If ($ADUsers[$Index].HasAppStore -eq "") { $ADUsers[$Index].HasAppStore = "NULL" }
        If ($ADUsers[$Index].HasCertification -eq "") { $ADUsers[$Index].HasCertification = "NULL" }
        If ($ADUsers[$Index].IsPrimaryContact -eq "") { $ADUsers[$Index].IsPrimaryContact = "NULL" }
        If ($ADUsers[$Index].IsSlcOnly -eq "") { $ADUsers[$Index].IsSlcOnly = "NULL" }
        If ($ADUsers[$Index].IsThirdPartyVendor -eq "") { $ADUsers[$Index].IsThirdPartyVendor = "NULL" }
        If ($ADUsers[$Index].LastAccess -eq "") { $ADUsers[$Index].LastAccess = "NULL" }
        If ($ADUsers[$Index].Newsletter -eq "") { $ADUsers[$Index].Newsletter = "NULL" }
        If ($ADUsers[$Index].OrganizationCode -eq "") { $ADUsers[$Index].OrganizationCode = "NULL" }
        If ($ADUsers[$Index].Pending -eq "") { $ADUsers[$Index].Pending = "NULL" }
        If ($ADUsers[$Index].RANotes -eq "") { $ADUsers[$Index].RANotes = "NULL" }
        If ($ADUsers[$Index].RegistrationDate -eq "") { $ADUsers[$Index].RegistrationDate = "NULL" }
        If ($ADUsers[$Index].SupportComp -eq "") { $ADUsers[$Index].SupportComp = "NULL" }
        If ($ADUsers[$Index].SYSPROVersion -eq "") { $ADUsers[$Index].SYSPROVersion = "NULL" }
        If ($ADUsers[$Index].UserID -eq "") { $ADUsers[$Index].UserID = "NULL" }
        
        #endregion
        $ADUserProperties = New-Object PSObject -Property @{
            AreaOfInterest        = $ADUsers[$Index].AreaOfInterest
            SPPP_DateCreated      = $ADUsers[$Index].DateCreated
            SPPP_DateUpdated      = $ADUsers[$Index].DateUpdated
            Disclaimer            = $ADUsers[$Index].Disclaimer
            Format                = $ADUsers[$Index].Format
            HasAppStore           = $ADUsers[$Index].HasAppStore
            HasCertification      = $ADUsers[$Index].HasCertification
            IsPrimaryContact      = $ADUsers[$Index].IsPrimaryContact
            SPPP_IsSlcOnly        = $ADUsers[$Index].IsSlcOnly
            IsThirdPartyVendor    = $ADUsers[$Index].IsThirdPartyVendor
            SPPP_LastAccess       = $ADUsers[$Index].LastAccess
            Newsletter            = $ADUsers[$Index].Newsletter
            OrganizationCode      = $ADUsers[$Index].OrganizationCode
            Pending               = $ADUsers[$Index].Pending
            RANotes               = $ADUsers[$Index].RANotes
            SPPP_RegistrationDate = $ADUsers[$Index].RegistrationDate
            SupportComp           = $ADUsers[$Index].SupportComp
            SYSPROVersion         = $ADUsers[$Index].SYSPROVersion
            SPPP_UserID           = $ADUsers[$Index].UserID
        }
        $ADUserDetails = New-Object PSObject -Property @{ 
            City           = $ADUsers[$Index].Region
            Company        = $ADUsers[$Index].CompName
            Country        = $ADUsers[$Index].Country
            ADCountry      = $ADCountry
            Description    = ""
            DisplayName    = $ADUsers[$Index].Fullname
            EmailAddress   = $ADUsers[$Index].Email
            HomePhone      = $ADUsers[$Index].Telephone
            Name           = ($ADUsers[$Index].FirstName + " " + $ADUsers[$Index].LastName)
            Password       = $ADUsers[$Index].SZPassword
            SecurePassword = $ADSecurePassword
            Surname        = $ADUsers[$Index].LastName
            Title          = $ADUsers[$Index].JobTitle
            MemberOf       = $ADUsers[$Index].SZLevel
            Enabled        = $Enabled
            Pending        = $ADUsers[$Index].Pending
            ADPath         = $ADPath
            Group          = $ADMemberOf
            SAMAccount     = $ADUsers[$Index].UserID
            State          = $ADUsers[$Index].StateOrProvince
            Properties     = $ADUserProperties
        }
        Write-Host (($Index + 1).ToString() + "/" + $ADUsers.Count.ToString()) -ForegroundColor Cyan -NoNewline; Write-Host " - " -NoNewline
        $ADCreationResult = Create-User -ADUserDetails $ADUserDetails
        If ($ADCreationResult.Failure -ne $False) {
            $FailedObject = New-Object PSObject -Property @{
                City                  = $ADUserDetails.City
                Company               = $ADUserDetails.Company
                Country               = $ADUserDetails.Country
                ADCountry             = $ADCountry
                Description           = ""
                DisplayName           = $ADUserDetails.DisplayName
                EmailAddress          = $ADUserDetails.EmailAddress
                HomePhone             = $ADUserDetails.HomePhone
                Name                  = $ADUserDetails.Name
                Password              = $ADUserDetails.Password
                SecurePassword        = $ADSecurePassword
                Surname               = $ADUserDetails.Surname
                Title                 = $ADUserDetails.Title
                MemberOf              = $ADUserDetails.MemberOf
                Enabled               = $Enabled
                Pending               = $ADUserDetails.Pending
                ADPath                = $ADPath
                Group                 = $ADMemberOf
                SAMAccount            = $ADUserDetails.SAMAccount
                AreaOfInterest        = $ADUserProperties.AreaOfInterest
                SPPP_DateCreated      = $ADUserProperties.DateCreated
                SPPP_DateUpdated      = $ADUserProperties.DateUpdated
                Disclaimer            = $ADUserProperties.Disclaimer
                Format                = $ADUserProperties.Format
                HasAppStore           = $ADUserProperties.HasAppStore
                HasCertification      = $ADUserProperties.HasCertification
                IsPrimaryContact      = $ADUserProperties.IsPrimaryContact
                SPPP_IsSlcOnly        = $ADUserProperties.IsSlcOnly
                IsThirdPartyVendor    = $ADUserProperties.IsThirdPartyVendor
                SPPP_LastAccess       = $ADUserProperties.LastAccess
                Newsletter            = $ADUserProperties.Newsletter
                OrganizationCode      = $ADUserProperties.OrganizationCode
                PendingProperty       = $ADUserProperties.Pending
                RANotes               = $ADUserProperties.RANotes
                SPPP_RegistrationDate = $ADUserProperties.RegistrationDate
                SupportComp           = $ADUserProperties.SupportComp
                SYSPROVersion         = $ADUserProperties.SYSPROVersion
                SPPP_UserID           = $ADUserProperties.UserID
                Error                 = $ADCreationResult
                ArrayIndex            = $Index
                CSVIndex              = ($Index + 2)
            }
            $FailedUsers = $FailedUsers + $FailedObject
        }
    }
    Return $FailedUsers
}

$ErrorActionPreference = "Stop"
$WarningPreference = "SilentlyContinue"

Clear-Host
$Properties = @(
    "Error"
    "ArrayIndex"
    "CSVIndex"
    "ADCountry"
    "ADPath"
    "AreaOfInterest"
    "City"
    "Company"
    "Country"
    "Description"
    "Disclaimer"
    "DisplayName"
    "EmailAddress"
    "Enabled"
    "Format"
    "Group"
    "HasAppStore"
    "HasCertification"
    "HomePhone"
    "IsPrimaryContact"
    "IsThirdPartyVendor"
    "MemberOf"
    "Name"
    "Newsletter"
    "OrganizationCode"
    "Password"
    "Pending"
    "PendingProperty"
    "RANotes"
    "SAMAccount"
    "SecurePassword"
    "SPPP_DateCreated"
    "SPPP_DateUpdated"
    "SPPP_IsSlcOnly"
    "SPPP_LastAccess"
    "SPPP_RegistrationDate"
    "SPPP_UserID"
    "SupportComp"
    "Surname"
    "SYSPROVersion"
    "Title")
# Create-ADStructure -Action "Create"
# Create-ADStructure -Action "Delete"
$Failures = Process-Users
##$Failures | Select -ExpandProperty Error | Where Properties -ne "True" | Fl
$Failures | Export-Csv -Path C:\temp\SharePoint\FailedCreation.csv -NoClobber -Force -Delimiter "," -NoTypeInformation
$Failures | Out-File C:\Temp\SharePoint\FailedUsers.txt -Encoding ascii -Force -NoClobber
$Failures | Select $Properties | Format-Table -AutoSize