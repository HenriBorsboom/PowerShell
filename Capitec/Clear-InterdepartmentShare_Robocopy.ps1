robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-10' 'C:\temp1\2023-08-10'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-11' 'C:\temp1\2023-08-11'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-15' 'C:\temp1\2023-08-15'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-16' 'C:\temp1\2023-08-16'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-17' 'C:\temp1\2023-08-17'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-18' 'C:\temp1\2023-08-18'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-21' 'C:\temp1\2023-08-21'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-22' 'C:\temp1\2023-08-22'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-24' 'C:\temp1\2023-08-24'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-28' 'C:\temp1\2023-08-28'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-29' 'C:\temp1\2023-08-29'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-30' 'C:\temp1\2023-08-30'

robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-11' 'C:\temp1\2023-08-10\2023-08-11'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-15' 'C:\temp1\2023-08-10\2023-08-15'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-17' 'C:\temp1\2023-08-10\2023-08-17'

robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-11' 'C:\temp1\2023-08-15\2023-08-11'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-15' 'C:\temp1\2023-08-15\2023-08-15'
robocopy /e /zb /copyall /r:0 /w:0 'C:\Users\CP364327\OneDrive - Capitec Bank Ltd\Pictures\Screenshots\2023-08-17' 'C:\temp1\2023-08-15\2023-08-17'

$MyTime = Get-Item 'C:\temp1\2023-08-10'
$MyTime.LastWriteTime = (Get-Date).AddDays(-7)
$MyTime = Get-Item 'C:\temp1\2023-08-15'
$MyTime.LastWriteTime = (Get-Date).AddDays(-7)