param ($widgets = $(throw "Widgets are required."),$top = -1,$left = -1, $background = "silver", 
$caption = "Form Gen by El Condor", $title = "")
function formGen {
	$global:list = new-object 'System.Collections.Generic.List[object]'
	$w = $widgets  -split ";"
	# control and normalisation
	$global:widgetRef = @{}
	$global:mapValues = @{}	# 	combo/radio key = fieldname & visualizedValue, value = key
	$global:fg_data = @{"fg_button" = "Cancel"}
	$widgetWidth = 0
	$convertType = @{"TEXT" = "T"; "PSW" = "P"; "LIST" = "L"}
	$types = ("T","P","L","F","CHK","CMB")
	for ($i = 0;$i -lt $w.length; $i++) {
		$f =  ($w[$i]+",,,,,,").split(",")
		$f[0] = $f[0].ToUpper()						# Upper type
		if ($convertType.contains($f[0]) -eq $true) {$f[0] = $convertType[$f[0]]}
		if ($f[1] -eq "") {$f[1] = "fg_field$i"}	# if not name generate name
		if ($f[2] -eq "") {$f[2] = $f[1]}			# if not label take the fieldname
		if ($f[3] -match "^\s*$") {$f[3] = 20}		# if not length 20
		if ($f[4].length -gt $f[3]) {$f[3] = $f[4].length}
		if ($types -contains $f[0]) {
			$list.Add($f)
			if ($widgetWidth -lt [int]$f[3]) {$widgetWidth = [int]$f[3]}
		}
	}
	[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
	$objForm = New-Object System.Windows.Forms.Form
	$objForm.Text = $caption
	$objForm.Opacity = 0.9
	$deltaY = 25		# space betweeen controls
	$left = 15
	$topOrig = 22
	$typeForm = ""		# typeForm: T = text, B = buttons, L = combo box or RadioButtons
	$finalButtons = "Cancel:Cancel,"
#	$objForm.Size = New-Object System.Drawing.Size(300,200)
	$objForm.BackColor = $background
	if ($title -ne "") {$topOrig += 10}
	# create labels
	$labelWidth = 0
	$objLabel = New-Object System.Windows.Forms.Label
	$objLabel.Location = New-Object System.Drawing.Size(0,0) 
	$objLabel.Text = "wai"
	$charWidth = [math]::ceiling($objLabel.preferredWidth/3)
	$top = $topOrig
	foreach($f in $list) {
		$objLabel = New-Object System.Windows.Forms.Label
		$objLabel.Location = New-Object System.Drawing.Size($left,$top) 
		$objLabel.Text = $f[2]
		$objLabel.Size = New-Object System.Drawing.Size($objLabel.preferredWidth,20) 
		if ($labelWidth -lt $objLabel.preferredWidth) {$labelWidth = $objLabel.preferredWidth}
		$objForm.Controls.Add($objLabel)
		$top = $top + $deltaY #+ $deltaY * 0.5*(Ceiling(($aEl[2])/$editSize)-1)	; for textarea
		$widgetRef.Add($f[1], (0,$f[0],$objLabel,$f))
	}
	$formWidth = 2 * $left + $labelWidth + $widgetWidth*$charWidth		# calculated form width
	$top = $topOrig
	foreach($f in $list) {
		if ("T","P" -contains $f[0]) {		# *************** Texts fields *******************
			$typeForm += "T"
			$objTextBox = New-Object System.Windows.Forms.TextBox
			$objTextBox.Location = New-Object System.Drawing.Size(($left+$labelWidth),$top) 
			$objTextBox.Size = New-Object System.Drawing.Size(($charWidth * $f[3]),($deltaY-10))
			if ("P" -eq $f[0]) {$objTextBox.PasswordChar = "*"}
			$objForm.Controls.Add($objTextBox)
			insertHandle $f[1] $objTextBox
		} elseif ("CMB","L" -contains $f[0]) {		# *************** Combos fields ******************* 
			$aValues = splitKeyValue $f[1] $f[5]	#	mapValues combo/radio key = fieldname & visualizedValue, value = key
			$objCombo = New-Object System.Windows.Forms.ComboBox
			$objCombo.Location = New-Object System.Drawing.Point(($left+$labelWidth),$top)
			$objCombo.Size = New-Object System.Drawing.Size(100,($deltaY-10))
			if ($aValues -notcontains $f[4]) {
				$f[4] = searchKey $aValues $f[1] $f[4]		# my be default is key?
			}
			$objCombo.Items.AddRange($aValues)
			$objCombo.add_SelectedIndexChanged({eventsHandler $f[0] $f[1]})
			if ($f[0] -eq "L") {	
				$typeForm += "L"
				$objCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;
			} else {
				$typeForm += "T"
				$objCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDown;
			}
			$objForm.Controls.Add($objCombo)
			insertHandle $f[1] $objCombo
		} elseif ("CHK" -contains $f[0]) {		# *************** Check box *******************
			$typeForm += "T"
			$objChk = New-Object System.Windows.Forms.CheckBox
			$objChk.Location = New-Object System.Drawing.Point(($left+$labelWidth),$top)
			$objChk.Size = New-Object System.Drawing.Size(100,($deltaY-10))
			$objForm.Controls.Add($objChk)
			insertHandle $f[1] $objChk		
		}
		$top = $top + $deltaY #+ $deltaY * 0.5*(Ceiling(($aEl[2])/$editSize)-1)	; for textarea
	}
	# buttons	
	if ($typeForm -ne "L") {			# if no only list type widget
		If ($typeForm.IndexOf("T") -gt -1) {$finalButtons = $finalButtons + "Reset:Reset,"}
		If ($typeForm.IndexOf("T") -gt -1) {$finalButtons = $finalButtons + "Ok:Ok,"}
	} else {$finalButtons = ""}
	$btnWidth = 65
	$btns = $finalButtons.Split(",")
	$offsetBtn = $left +($objForm.Width - $left*2 - $btns.Length*($btnWidth)) * 0.5
	for ($i = 0;$i -lt $btns.Length-1;$i++) {
		$btn = New-Object System.Windows.Forms.Button
		$btn.Location = New-Object System.Drawing.Size(($offsetBtn+$i*$btnWidth),($top+6))
		$btn.Size = New-Object System.Drawing.Size($btnWidth,($deltaY-1))
		$btn.Font = New-Object System.Drawing.Font("",9)
		$k = $btns[$i].Split(":")
		$btn.Text = $k[0]
		$btn.Tag = $k[1]
		if ($k[1] -eq "Cancel") {$btn.Add_Click({$objForm.Close()})}
		elseif ($k[1] -eq "Reset") {$btn.Add_Click({setDefaults})}
		else {$btn.Add_Click({exitForm($k[1])})}
		$objForm.Controls.Add($btn)
	}	
	# title
	if ($title -ne "") { 
		$objTitle = New-Object System.Windows.Forms.Label
		$objTitle.Font = New-Object System.Drawing.Font("",10)
		$objTitle.Text = $title
		$objTitle.Location = New-Object System.Drawing.Size((($objForm.width-$objTitle.preferredWidth)/2),($topOrig-20))
		$objTitle.Size = New-Object System.Drawing.Size($objTitle.preferredWidth,20) 
		$objForm.Controls.Add($objTitle)
	}
	setDefaults
	$objForm.Size = New-Object System.Drawing.Size($formWidth,($top+100))
	$objForm.StartPosition = "CenterScreen"	# CenterScreen, Manual, WindowsDefaultLocation, WindowsDefaultBounds, CenterParent
	$objForm.Topmost = $True
	$objForm.Add_Shown({$objForm.Activate()})
	[void] $objForm.ShowDialog()
}
function eventsHandler($type,$name) {		# events handler
	if ($type -eq "L") { 
		if ($typeForm -eq "L") {exitForm("")}
	}
}
function insertHandle($name,$handle) {		# inser label handle
	$a = $widgetRef[$name]
	$a[0] = $handle
	$widgetRef[$name]= $a
}
function splitKeyValue($name,$values) {		# create dictionary of key values fields
	$aValues = $values.split("|")
	for ($i =0;$i -lt $aValues.length;$i++) {
		$aV = ($aValues[$i]+":"+$aValues[$i]).split(":")
		$mapValues.Add($name+$aV[1],$aV[0])
		$aValues[$i] = $aV[1]
	}
	return $aValues
}
function searchKey($aValues, $name, $value) {
	foreach ($v in $aValues) {
		if ($mapValues[$name+$v] -eq $value) {return $v}
	}
	return ""
}
function setDefaults {
	foreach($f in $list) {setValue $f[1] $f[4]}
}
function setValue($name,$value) {
	if ("T","P" -contains $widgetRef[$name][1]) {$widgetRef[$name][0].text = $value}
	elseif ("CMB","L" -contains $widgetRef[$name][1]) {$widgetRef[$name][0].text = if($value -ne "") {$value} else {$widgetRef[$name][0].selectedIndex=-1}}
	elseif ("CHK" -contains $widgetRef[$name][1]) {$widgetRef[$f[1]][0].checked = if ("on","checked" -contains $value.toLower()) {$True} else {$False}}
}
function exitForm($btn) {
	$fg_data["fg_button"] = $btn
	foreach($f in $list) {
		if ("T","P" -contains $f[0]) {$fg_data[$f[1]] = $widgetRef[$f[1]][0].text}
		elseif ("CMB","L" -contains $f[0]) {$fg_data[$f[1]] = $mapValues[$f[1]+$widgetRef[$f[1]][0].text]}
		elseif ("CHK" -contains $f[0]) {$fg_data[$f[1]] = if ($widgetRef[$f[1]][0].checked -eq $true) {"On"} else {"Off"}}
	}
	$objForm.Close()
}
formGen $widgets