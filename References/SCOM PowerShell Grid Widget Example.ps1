Param($globalSelectedItems)
 
$i = 1
ForEach ($globalSelectedItem in $globalSelectedItems) {
    $dataObject = $ScriptContext.CreateInstance("xsd://foo!bar/baz")
    $dataObject["Id"]=$i.ToString()
    $dataObject["Object ID"]=$globalSelectedItem["Name"]
    #$dataObject["Type"]=$globalSelectedItem.gettype().Tostring()
    $ScriptContext.ReturnCollection.Add($dataObject)
    $i++
} 
