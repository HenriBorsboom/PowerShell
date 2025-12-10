Function Part1 {
# https://powershellstation.com/2016/01/20/powershell-and-visio-1/

Import-Module myvisio -Force
New-VisioApplication                                                                         New-VisioDocument   | out-null                                                             
New-VisioContainer "My new container"  {
    New-VisioRectangle 1 1 5 5 
    New-VisioRectangle 5.5 5.5 6 6
    New-VisioContainer "Inner Container" {
        New-VisioRectangle 1 7 8 8
    } 
} | out-null
}
Function Part2 {
#https://powershellstation.com/2016/02/04/powershell-and-visio-part-2-first-steps/
New-Object -ComObject Visio.Application
$Visio=New-Object -ComObject Visio.Application
$doc=$Visio.Documents.Add(‘c:\temp\SampleVisio.vsdx’)
$doc.Pages | select-object –property Name
$page.Shapes | select-object –Property Name,Text
$x=$shape.Cells(‘PinX’).ResultIU 
$y=$shape.Cells(‘PinY’).ResultIU
}
Function Part3 {
#https://powershellstation.com/2016/03/10/powershell-and-visio-part-3-drawing-shapes/
$Visio= New-Object -ComObject Visio.Application
$Doc=$Visio.Documents.Add('')
$Page=$Visio.ActivePage
#Or
#$Page=$Doc.Pages(1)
#$Page=$Doc.Pages('Page-1')
$Page | get-member Draw*
$Page.DrawRectangle(1,1,5,5)
$Page.DrawOval(6,6,8,8)
$stencilPath='C:\Program Files (x86)\Microsoft Office\Office15\Visio Content\1033\SERVER_U.VSSX'
$stencil=$Visio.Documents.OpenEx($stencilPath,64)
$Master=$stencil.Masters('FTP Server')
$Page.Drop($Master,4,4)
}
Function Part4 {
# https://powershellstation.com/2016/03/11/powershell-and-visio-part-4-interlude/

$Visio = New-Object -ComObject Visio.Application
$Doc=$Visio.Documents.Open('c:\temp\ServerDiagram.vsdx')
$Page=$Visio.ActivePage
 
foreach($shape in $page.Shapes){
    if(!$shape.Text.Contains("`n")){
        $address=Resolve-DnsName $shape.text 
        $address=$address| where-object {$_.IP4Address } | select-object -First 1
        $newLabel="{0}`n{1}" -f $shape.text,$address.IP4Address
        $Shape.Text=$newLabel
    }
}
}
Function Part5 {
# https://powershellstation.com/2016/04/02/powershell-and-visio-part-5-connections/

$visio=New-Object -ComObject Visio.Application
$Document=$Visio.Documents.Add('')
$rect1=$Visio.ActivePage.DrawRectangle(1,1,2,2)
$rect2=$Visio.ActivePage.DrawRectangle(4,4,5,5)
$rect1.AutoConnect($rect2,0)
$Visio.ActivePage.Shapes | Select-Object Name
$connector = $Visio.ActivePage.Shapes['Dynamic connector'] | select -Last 1
$Shape.CellsSRC($section,$row,$column) 
$Shape.Cells('CellName')
$connector.Cells('EndArrow')=4
$connector.Cells('BeginArrow')=4
$connector.CellsSRC(1,23,10) = 16
$connector.CellsSRC(1,23,19) = 1 
##VBA Application.ActiveWindow.Page.Shapes.ItemFromID(3).CellsSRC(visSectionObject, visRowShapeLayout, visSLOLineRouteExt).FormulaU = "1"
##VBA Application.ActiveWindow.Page.Shapes.ItemFromID(3).CellsSRC(visSectionObject, visRowShapeLayout, visSLORouteStyle).FormulaU = "16"
}

Function Working_Connectors {
## create visio document
$visio = New-Object -ComObject Visio.Application
$docs = $visio.Documents

## use basic template
$doc = $docs.Add("Basic Diagram.vst")

## set active page
$pages = $visio.ActiveDocument.Pages
$page = $pages.Item(1)

## Add a stencil
#$mysten = "C:\Program Files\Microsoft Office\Office14\Visio Content\1033\EntApp_M.vss"
$mysten = 'C:\Program Files (x86)\Microsoft Office\Office15\Visio Content\1033\SERVER_U.VSSX'
$stencil = $visio.Documents.Add($mysten)

## Add objects
$server = $stencil.Masters.Item("Server")
$workstn = $stencil.Masters.Item("Database server")

$shape1 = $page.Drop($server, 2, 2)
$shape2 = $page.Drop($workstn, 5, 5)

## Resize Objects
$shape1.Resize(1, 5, 70)
$shape2.Resize(1, 5, 70)

## Connect Objects
$connect = $page.Drop($page.Application.ConnectorToolDataObject,0,0)
$start = $connect.CellsU("BeginX").GlueTo($shape1.CellsU("PinX"))
$end = $connect.CellsU("EndX").GlueTo($shape2.CellsU("PinX"))

$doc.SaveAs("c:\Temp\Visio\draw1.vsd")
$visio.Quit() 
}



