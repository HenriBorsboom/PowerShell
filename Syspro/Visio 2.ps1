## create visio document
$visio = New-Object -ComObject Visio.Application
#$visio.Visible = $false
$docs = $visio.Documents

## use basic template
$doc = $docs.Add("Basic Diagram.vst")

## set active page
$pages = $visio.ActiveDocument.Pages
$page = $pages.Item(1)

## Add a stencil
$mysten = 'C:\Program Files\Microsoft Office\root\Office16\Visio Content\1033\ADO_M.VSSX'
$stencil = $visio.Documents.Add($mysten)

## Add objects
$RootFolder = $stencil.Masters.Item("Domain")
$Folder = $stencil.Masters.Item("Container")
$File = $stencil.Masters.Item("User")
$connector = $Visio.ConnectorToolDataObject

$TestPath = 'C:\temp\azure'
$TestPathItem = Get-ChildItem -Path $TestPath
[Double] $x = 1
[double] $y = 7

$Root = $page.drop($RootFolder, 1, 7.5)

ForEach ($Item in $TestPathItem) {
    If ($Item.Attributes -eq "Directory") { 
        $Shape = $page.drop($Folder, $x, $y)
        $Shape.AutoConnect($Root,0, $connector)
        $y = ($y - 0.5)
    }
    Else {
        $Shape = $page.drop($File, $x, $y)
        $Shape.AutoConnect($Root,0, $connector)
        $y = ($y - 0.5)
    }
} 


<#
$shape1 = $page.Drop($server, 2, 2)
$shape2 = $page.Drop($workstn, 5, 5)

## Resize Objects
$shape1.Resize(1, 5, 70)
$shape2.Resize(1, 5, 70)

## Connect Objects
$connect = $page.Drop($page.Application.ConnectorToolDataObject,0,0)
$start = $connect.CellsU("BeginX").GlueTo($shape1.CellsU("PinX"))
$end = $connect.CellsU("EndX").GlueTo($shape2.CellsU("PinX"))
#>
#$visio.Visible = $true

$doc.SaveAs("c:\Temp\Visio\draw1.vsd")
#$visio.Quit() 
