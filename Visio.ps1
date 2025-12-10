# https://blogs.technet.microsoft.com/heyscriptingguy/2010/01/11/hey-scripting-guy-is-it-possible-to-automate-microsoft-visio/
Clear-Host

$application = New-Object -ComObject Visio.Application 
$documents = $application.Documents 
$document = $documents.Add("") 
$document = $documents.Add("Basic Diagram.vst") 
$pages = $application.ActiveDocument.Pages 
$page = $pages.Item(1)
$stencil = $application.Documents.Add("Basic Shapes.vss")
$item = $stencil.Masters.Item("Square") 
$shape = $page.Drop($item, 1.0, 10.6) 
$shape.Text = "This is some text." 
$document.SaveAs("C:\Temp\fsoMyDrawing.vsd") 
$application.Quit() 

















