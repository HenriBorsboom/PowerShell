Function ExportTo-Excel {    
    $ExcelObject = New-Object -ComObject Excel.Application  
    $ExcelObject.Visible = $true 
    $ExcelObject.DisplayAlerts =$false
    $Date= Get-Date -Format "dd-MM-yyyy"
    $strPath1="C:\Users\username\Documents\BCX\Azure\CI\CI Template2.xlsx" 
    If (Test-Path $strPath1) {  
        #Open the document  
        $ActiveWorkbook = $ExcelObject.WorkBooks.Open($d)  
        $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  
    } 
    Else {  
        # Create Excel file  
        $ActiveWorkbook = $ExcelObject.Workbooks.Add()  
        $ActiveWorksheet = $ActiveWorkbook.Worksheets.Item(1)  

        #Add Headers to excel file
        $ActiveWorksheet.Cells.Item(1,1) = "User_Id"  
        $ActiveWorksheet.cells.item(1,2) = "User_Name" 
        $ActiveWorksheet.cells.item(1,3) = "CostCenter"
        $ActiveWorksheet.cells.item(1,4) = "Approving Manager"
        $format = $ActiveWorksheet.UsedRange
        $format.Interior.ColorIndex = 19
        $format.Font.ColorIndex = 11
        $format.Font.Bold = "True"
    } 
    #Loop through the Array and add data into the excel file created.
    #foreach ($line in $Activeusers){
    #     ($user_id,$user_name,$Costcntr,$ApprMgr) = $line.split('|')
    #      $introw = $ActiveWorksheet.UsedRange.Rows.Count + 1  
    #      $ActiveWorksheet.cells.item($introw, 1) = $user_id  
    #      $ActiveWorksheet.cells.item($introw, 2) = $user_name
    #      $ActiveWorksheet.cells.item($introw, 3) = $Costcntr
    #      $ActiveWorksheet.cells.item($introw, 4) = $ApprMgr 
    #      $ActiveWorksheet.UsedRange.EntireColumn.AutoFit();
    #}
    $ActiveWorkbook.SaveAs($strPath1)

    $ExcelObject.Quit()
}