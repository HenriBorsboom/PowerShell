FUNCTION GLOBAL:Select-MenuItem {

<#

.NOTES
	Revision: 2012-09-22
	Author:   Al Dunbar
	Identity: http://social.technet.microsoft.com/Profile/Al%20Dunbar

.SYNOPSIS
	Presents a simple menu [A.Dunbar]

.DESCRIPTION
	This function is a wrapper for the PromptForChoice method of the $host.UI
	object. It provides the following interface enhancements:

	- allows whitespace in the menu option definitions
	- can return the selected choice as a text value instead of the numeric value
	- optionally displays the full help menu before prompting for the user's choice
	- provides shortcut definitions for commonly used menus

	The function displays a one-line menu in this format:
	
		[A] Abort  [R] Retry  [I] Ignore  [?] Help (default is "R"):

	At this point the user has four options:

	- enter a question mark to display the full list of options with help text
	- press enter to select the default option, if defined ('R' in this case)
	- enter the 'accelerator' character shown in [brackets], or
	- enter the full keyword shown immediately following the accelerator character.
	
	A note on ambiguity:
	
	Certain combinations of options can result in ambiguity that brings the
	validity of the value returned by the function into question. The function
	makes no attempt to validate the syntax of the -MenuText parameter. In order
	to avoid ambiguity it is recommended that:
	
	- all keywords have at least two characters
	- no two keywords are the same: "&Exit" = "e&Xit"
	- no two accelerators are the same "exi&T = "qui&T"
	- the help text is meaningful to the end user of the script

.LINK
documents the use of the $host.ui.PromptForChoice method
	- http://scriptolog.blogspot.ca/2007/09/make-choice.html
	- http://technet.microsoft.com/en-us/library/ff730939.aspx
MichalGaida: in-line example
	- http://social.technet.microsoft.com/Forums/hr/winserverpowershell/thread/e9849a8b-1a83-4de6-ba8f-61b18af97145
Kazun: in-line example
	- http://social.technet.microsoft.com/Forums/en/winserverpowershell/thread/c81725fe-ae7f-4cbb-9fb3-6cbc65c70bcb
Bilbag: Get-Choice function using PromptForChoice
	- http://gallery.technet.microsoft.com/Get-Choice-b7063b6d
James ONeaill: Select-Item function using PromptForChoice
	- http://blogs.technet.com/b/jamesone/archive/2009/06/24/how-to-get-user-input-more-nicely-in-powershell.aspx


.EXAMPLE
	Select-MenuItem
	
	Demonstration mode: the available menu shortcuts are shown as
	keywords with the corresponding options listed under 'Meaning'
	
	Keyword  - Meaning
	==================================================
	OK       - OK only
	OKC      - OK and Cancel
	ARI      - Abort, Retry and Ignore
	YN       - Yes and No
	YNC      - Yes, No, and Cancel
	RC       - Retry and Cancel
	YANLS    - Yes, Yes to All, No, No to All, Suspend
	==================================================
	
	Demonstration mode: the available menu shortcuts are shown as
	keywords with the corresponding options listed under 'Meaning'
	[O] OK  [C] OKC  [I] ARI  [Y] YN  [N] YNC  [R] RC  [A] YANLS  [?] Help (default is "O"):
	OK
	
	===========
	Description
	This command illiustrates "demonstration mode" whose main purpose
	is to list all of the available menu shortcuts

.EXAMPLE
	Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "a"
	
	the heading
	the prompt
	[A] Abort  [R] Retry  [I] Ignore  [?] Help (default is "A"):
	A
	
	===========
	Description
	This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore)
	and how to return the accelerator key corresponding to the selected item

.EXAMPLE
	Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "retry"
	
	the heading
	the prompt
	[A] Abort  [R] Retry  [I] Ignore  [?] Help (default is "R"):
	Retry
	
	===========
	Description
	This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore)
	and how to return the keyword corresponding to the selected item

.EXAMPLE
	Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default -1
	
	the heading
	the prompt
	[A] Abort  [R] Retry  [I] Ignore  [?] Help: r
	1
	
	===========
	Description
	This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore)
	and how to return the numeric index of the selected item. The -1 value also
	results in no default value being defined.

.EXAMPLE
	Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir"
	
	Response required:
	Enter your selection from the menu shown below:
	[Y] Yup  [N] Nope  [?] Help (default is "Y"):
	0
	
	===========
	Description
	This command shows the use of an alternate menu item delimiter character

.EXAMPLE
	Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir" -showmenu
	
	Response required:
	Enter your selection from the menu shown below:
	
	Keyword  - Meaning
	==================================================
	Yup      - yessir
	Nope     - nosir
	==================================================
	
	Response required:
	Enter your selection from the menu shown below:
	[Y] Yup  [N] Nope  [?] Help (default is "Y"):
	0
	
	===========
	Description
	This command shows the use of an alternate menu item delimiter character and the
	-showmenu parameter


.EXAMPLE
	# use in-line here-string
	Select-MenuItem -default "L" -menuText @"
        	&First   = first choice
        	&Second  = second choice
        	&Last    = last choice
	"@
	
	Response required:
	Enter your selection from the menu shown below:
	[F] First  [S] Second  [L] Last  [?] Help (default is "L"):
	L
	
	===========
	Description
	This command shows how to use a here-string inline for the -menuText parameter


#> <#-------------------------------------------------------------------------#>

[CMDLETBINDING()]

PARAM
(

	# a text message that will appear above the prompt string
	[string]
	$heading = "Response required:"
	,
	# a string with which the user will be prompted for input
	[string]
	$Prompt = "Enter your selection from the menu shown below:"
	,
	<#
		the default choice, given in the form in which the chosen item will be returned.
		if no -default parameter is specified, the default is the first item, item zero.
		-1:
			default choice:   - none
			function returns: - the numeric value of the chosen item
		2:
			default choice:   - the third item
			function returns: - the numeric value of the chosen item
		'R':
			default choice:   - the item with 'R' as the accelerator
			function returns: - the accelerator of the chosen item
		'Retry':
			default choice:   - the item with 'Retry' as the keyword
			function returns: - the keyword of the chosen item
	#>
	$Default = 0
	,
	<#
		defines the menu choices available in one of two ways:
			a) menu of options in this format:
				"&Delete = delete file `n &Rename = rename file `n e&Xit = stop":
				==> [D] Delete  [R] Rename  [X] eXit  [?] Help (default is "D"):
			b) or one of these menu shortcuts
				"OK"    ==> [O] Ok  [?] Help
				"OKC"   ==> [O] Ok  [C] Cancel  [?] Help
				"ARI"   ==> [A] Abort  [R] Retry  [I] Ignore  [?] Help
				"YN"    ==> [Y] Yes  [N] No  [?] Help
				"YNC"   ==> [Y] Yes  [N] No  [C] Cancel  [?] Help
				"RC"    ==> [R] Retry  [C] Cancel  [?] Help
				"YANLS" ==> [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help"
	#>
	[string]
	$MenuText = ""
	,
	<#
		menu option delimiter character. The default is the newline character,
		allowing the use of a here-string with one option per line
	#>
	[string]
	$Delimiter = "`n"
	,
	# optionally display the menu with help text before prompting for the user's choice
	[switch]
	$showMenu

)

	# expand an option menu shortcut to a full option menu
	switch ( $MenuText ) {

		"Ok"    { $MenuText = "&Ok = acknowledge the above information" }

		"OkC"   { $MenuText = "&Ok = perform the suggested action $Delimiter "+`
		                      "&Cancel = cancel the current operation" }

		"ARI"   { $MenuText = "&Abort = abort the current operation $Delimiter "+`
		                      "&Retry = retry the action that failed $Delimiter "+`
		                      "&Ignore = ignore the error and continue" }

		"YN"    { $MenuText = "&Yes = perform the suggested action $Delimiter "+`
		                      "&No = do not perform the suggested action" }

		"YNC"   { $MenuText = "&Yes = perform the suggested action $Delimiter "+`
		                      "&No = do not perform the suggested action $Delimiter "+`
		                      "&Cancel = cancel the current operation altogether" }

		"RC"    { $MenuText = "&Retry = retry the action that failed $Delimiter "+`
		                      "&Cancel = cancel the current operation altogether" }

		"YANLS" { $MenuText = "&Yes = Continue with only the next step of the operation. $Delimiter"+`
							  "Yes to &All  = Continue with all the steps of the operation. $Delimiter"+`
							  "&No          = Skip this operation and proceed with the next operation. $Delimiter"+`
							  "No to A&ll   = Skip this operation and all subsequent operations. $Delimiter"+`
							  "&Suspend     = Pause the current pipeline and return to the command prompt. Type 'exit' to resume the pipeline." }

		""     {

			# Special case, an empty -MenuText value shows all available shortcuts
			$Heading   = "Demonstration mode: the available menu shortcuts are shown as"
			$Prompt    = "keywords with the corresponding options listed under 'Meaning'"
			$Default   = "OK"
			$showMenu  = $true 
			$MenuText  = @"
				&OK    = OK only
				OK&C   = OK and Cancel
				AR&I   = Abort, Retry and Ignore
				&YN    = Yes and No
				Y&NC   = Yes, No, and Cancel
				&RC    = Retry and Cancel
				Y&ANLS = Yes, Yes to All, No, No to All, Suspend
"@
		}
	}
	
	# set return format and default value to use assuming a numeric -default value
	$returnFormat = "number"
	$useAsDefault = $default

	# create arrays for accumulating various values for each menu option:
	$choices      = @() # ChoiceDescription object
	$accelerators = @() # accelerator characters
	$keyWords     = @() # keyword
	$menushow     = @() # menu option representation for -showMenu switch

	# process the menu of options
	foreach ( $item in $MenuText.split( $Delimiter ) ) {

		# get the current menu item index
		$itemNo = $choices.count

		# extract menu item components
		$keyword,$phrase = $item.split("=")
		$keyword         = $keyword.trim()
		$phrase          = $phrase.trim()
		$word            = $keyword.replace("&","")
		$before,$after   = $keyword.split("&")

		# extract the accelerator
		TRY {$accelerator = $after[0]} CATCH {$accelerator = "$itemNo"}
		
		# set the return format and numeric default value to use on a match of the accelerator or keyword
		if ( $accelerator -eq $default ) {
			# accelerator mode
			$returnFormat = "keyChar"
			$useAsDefault = $itemNo
		} elseif ( $word -eq $default ) {
			# word mode
			$returnFormat = "keyWord"
			$useAsDefault = $itemNo
		}

		# accumulate assorted data onto arrays
		$choices      += New-Object System.Management.Automation.Host.ChoiceDescription $keyword, $phrase
		$accelerators += $accelerator
		$keyWords     += $word
		$menushow     += "$word`t - $phrase"

	}

	# build an options object from the accumulated choices	
	$options = [System.Management.Automation.Host.ChoiceDescription[]]( $choices )

	# optionally display the menu first
	if ( $showMenu ) {
		write-host "`n$Heading`n$Prompt`n`nKeyword`t - Meaning"
		write-host '=================================================='
		$menushow | foreach {write-host $_}
		write-host '=================================================='
	}

	TRY
	{
		# invoke the PromptForChoice method with indictated parameters
		$result = $host.ui.PromptForChoice( $heading, $Prompt, $options, $useAsDefault )
	}
	CATCH
	{
		# assume failure resulted from an invalid default parameter, and retry with no default
		$result = $host.ui.PromptForChoice( $heading, $Prompt, $options, -1 )
	} 
	
	# substitute return value of a different type if indicated by the default parameter
	switch ( $returnFormat ) {
		"keychar" { $result = $accelerators[$result] }
		"keyword" { $result = $keyWords[$result] }
	}

	# return the result to the function caller
	return $result

}	#====================================================================================================
Select-MenuItem # Example 1
<#
-------------------------- EXAMPLE 1 -------------------------- 
     
    C:\PS>Select-MenuItem 
     
    Demonstration mode: the available menu shortcuts are shown as 
    keywords with the corresponding options listed under 'Meaning' 
     
    Keyword  - Meaning 
    ================================================== 
    OK       - OK only 
    OKC      - OK and Cancel 
    ARI      - Abort, Retry and Ignore 
    YN       - Yes and No 
    YNC      - Yes, No, and Cancel 
    RC       - Retry and Cancel 
    YANLS    - Yes, Yes to All, No, No to All, Suspend 
    ================================================== 
     
    Demonstration mode: the available menu shortcuts are shown as 
    keywords with the corresponding options listed under 'Meaning' 
    [O] OK  [C] OKC  [I] ARI  [Y] YN  [N] YNC  [R] RC  [A] YANLS  [?] Help (default is "O"): 
    OK 
     
    =========== 
    Description 
    This command illiustrates "demonstration mode" whose main purpose 
    is to list all of the available menu shortcuts 
     
     
     
     
#>
Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "a" # Example 2
<#
    -------------------------- EXAMPLE 2 -------------------------- 
     
    C:\PS>Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "a" 
     
    the heading 
    the prompt 
    [A] Abort  [R] Retry  [I] Ignore  [?] Help (default is "A"): 
    A 
     
    =========== 
    Description 
    This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore) 
    and how to return the accelerator key corresponding to the selected item 
     
     
     
     
#>
Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "retry" # Example 3
<#
    -------------------------- EXAMPLE 3 -------------------------- 
     
    C:\PS>Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default "retry" 
     
    the heading 
    the prompt 
    [A] Abort  [R] Retry  [I] Ignore  [?] Help (default is "R"): 
    Retry 
     
    =========== 
    Description 
    This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore) 
    and how to return the keyword corresponding to the selected item 
     
     
     
     
#>
Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default -1 # EXAMPLE 4
<#
    -------------------------- EXAMPLE 4 -------------------------- 
     
    C:\PS>Select-MenuItem -heading "the heading" -prompt "the prompt" -menutext "ari" -default -1 
     
    the heading 
    the prompt 
    [A] Abort  [R] Retry  [I] Ignore  [?] Help: r 
    1 
     
    =========== 
    Description 
    This command demonstrates the 'ARI' menu shortcut (Abort, Retry, Ignore) 
    and how to return the numeric index of the selected item. The -1 value also 
    results in no default value being defined. 
     
     
     
     
#>
Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir" # EXAMPLE 5
<#
    -------------------------- EXAMPLE 5 -------------------------- 
     
    C:\PS>Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir" 
     
    Response required: 
    Enter your selection from the menu shown below: 
    [Y] Yup  [N] Nope  [?] Help (default is "Y"): 
    0 
     
    =========== 
    Description 
    This command shows the use of an alternate menu item delimiter character 
     
     
     
#>
Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir" -showmenu  # Example 6
<#
    
    -------------------------- EXAMPLE 6 -------------------------- 
     
    C:\PS>Select-MenuItem -delimiter "|" -menutext "&Yup = yessir | &Nope = nosir" -showmenu 
     
    Response required: 
    Enter your selection from the menu shown below: 
     
    Keyword  - Meaning 
    ================================================== 
    Yup      - yessir 
    Nope     - nosir 
    ================================================== 
     
    Response required: 
    Enter your selection from the menu shown below: 
    [Y] Yup  [N] Nope  [?] Help (default is "Y"): 
    0 
     
    =========== 
    Description 
    This command shows the use of an alternate menu item delimiter character and the 
    -showmenu parameter 
     
     
     
#>
<#
    -------------------------- EXAMPLE 7 -------------------------- 
     
    C:\PS># use in-line here-string 
     
    Select-MenuItem -default "L" -menuText @" 
               &First   = first choice 
               &Second  = second choice 
               &Last    = last choice 
    "@ 
     
    Response required: 
    Enter your selection from the menu shown below: 
    [F] First  [S] Second  [L] Last  [?] Help (default is "L"): 
    L 
     
    =========== 
    Description 
    This command shows how to use a here-string inline for the -menuText parameter 
     
     
     
    ------------------------------------------------------------------------- 
#>