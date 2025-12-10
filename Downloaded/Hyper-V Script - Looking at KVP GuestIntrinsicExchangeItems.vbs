Option Explicit
 
Dim HyperVServer
Dim VMName
Dim WMIService
Dim VM
Dim KVP
Dim xmlDoc
Dim DisplayString
Dim exchangeDataItem 
Dim xpath
Dim node
 
'Prompt for the Hyper-V Server to use
HyperVServer = InputBox("Specify the Hyper-V Server to use:") 
 
'Get name for the virtual machine
VMName = InputBox("Specify the name of the virtual machine:") 
 
'Get an instance of the WMI Service in the virtualization namespace.
Set WMIService = GetObject("winmgmts:\\" & HyperVServer & "\root\virtualization")
 
'Get the VM object that we want
Set VM = (WMIService.ExecQuery("SELECT * FROM Msvm_ComputerSystem WHERE ElementName='" & VMName & "'")).ItemIndex(0)
 
'Get the KVP Object for the virtual machine
Set KVP = (VM.Associators_("Msvm_SystemDevice", "Msvm_KvpExchangeComponent")).ItemIndex(0) 
 
'Create an XML object to parse the data
Set xmlDoc = CreateObject("Microsoft.XMLDOM")
xmlDoc.async = "false"
 
'Iterate over GuestIntrinsicExchangeItems
for each exchangeDataItem in KVP.GuestIntrinsicExchangeItems
 
   'Load single exchange data item
   xmlDoc.loadXML(exchangeDataItem) 
 
   'Get the value for node name
   xpath = "/INSTANCE/PROPERTY[@NAME='Name']/VALUE/child:text()"
   set node = xmlDoc.selectSingleNode(xpath)
   DisplayString = DisplayString & node.Text & " : "
 
   'Get the data associated with the VM
   xpath = "/INSTANCE/PROPERTY[@NAME='Data']/VALUE/child:text()"
   set node = xmlDoc.selectSingleNode(xpath)
   DisplayString = DisplayString & node.Text & chr(13)
 
next
 
wscript.echo "Guest OS information for " & VMName & chr(10) & chr(10) & DisplayString 
