#Synopsis
#    Adds a Microsoft .NET Framework type (a class) to a Windows PowerShell session.
#Syntax
#    Add-Type [-TypeDefinition] <String> [-CodeDomProvider <CodeDomProvider>] [-CompilerParameters <CompilerParameters>] [-IgnoreWarnings ] [-Language ] [-OutputAssembly <String>] [-OutputType ] [-PassThru ] [-ReferencedAssemblies <String[]>] [<CommonParameters>]
#    Add-Type [-IgnoreWarnings ] [-PassThru ] -AssemblyName <String[]> [<CommonParameters>]
#    Add-Type [-Name] <String> [-MemberDefinition] <String[]> [-CodeDomProvider <CodeDomProvider>] [-CompilerParameters <CompilerParameters>] [-IgnoreWarnings ] [-Language ] [-Namespace <String>] [-OutputAssembly <String>] [-OutputType ] [-PassThru ] [-ReferencedAssemblies <String[]>] [-UsingNamespace <String[]>] [<CommonParameters>]
#    Add-Type [-CompilerParameters <CompilerParameters>] [-IgnoreWarnings ] [-OutputAssembly <String>] [-OutputType ] [-PassThru ] [-ReferencedAssemblies <String[]>] -LiteralPath <String[]> [<CommonParameters>]
#    Add-Type [-Path] <String[]> [-CompilerParameters <CompilerParameters>] [-IgnoreWarnings ] [-OutputAssembly <String>] [-OutputType ] [-PassThru ] [-ReferencedAssemblies <String[]>] [<CommonParameters>]
#
#Description
#    The Add-Type cmdlet lets you define a .NET Framework class in your Windows PowerShell session. You can then instantiate objects (by using the New-Object cmdlet) and use the objects, just as you would use any .NET Framework object. If you add an Add-Type command to your Windows PowerShell profile, the class is available in all Windows PowerShell sessions.
#    You can specify the type by specifying an existing assembly or source code files, or you can specify the source code inline or saved in a variable. You can even specify only a method and Add-Type will define and generate the class. You can use this feature to make Platform Invoke (P/Invoke) calls to unmanaged functions in Windows PowerShell. If you specify source code, Add-Type compiles the specified source code and generates an in-memory assembly that contains the new .NET Framework types.
#    You can use the parameters of Add-Type to specify an alternate language and compiler (CSharp is the default), compiler options, assembly dependencies, the class namespace, the names of the type, and the resulting assembly.
#
#Inputs
#    None
#    You cannot pipe objects to Add-Type.
#
#Outputs
#    None or System.Type
#    When you use the PassThru parameter, Add-Type returns a System.Type object that represents the new type. Otherwise, this cmdlet does not generate any output.
#
#Notes
#    The types that you add exist only in the current session.  To use the types in all sessions, add them to your Windows PowerShell profile. For more information about the profile, see about_Profiles (http://go.microsoft.com/fwlink/?LinkID=113729).

Function Example-1 {
Write-Host "    -------------------------- EXAMPLE 1 --------------------------"
$source = @"
    public class BasicTest
    {
      public static int Add(int a, int b)
        {
            return (a + b);
        }
      public int Multiply(int a, int b)
        {
        return (a * b);
        }
    }
"@
    
Add-Type -TypeDefinition $source
[BasicTest]::Add(4, 3)
$basicTestObject = New-Object BasicTest
$basicTestObject.Multiply(5, 2)
    
#These commands add the BasicTest class to the session by specifying source code that is stored in a variable. The type has a static method called Add and a non-static method called Multiply.
#The first command stores the source code for the class in the $source variable.
#The second command uses the Add-Type cmdlet to add the class to the session. Because it is using inline source code, the command uses the TypeDefinition parameter to specify the code in the $source variable.
#The remaining commands use the new class.
#The third command calls the Add static method of the BasicTest class. It uses the double-colon characters (::) to specify a static member of the class.
#The fourth command uses the New-Object cmdlet to instantiate an instance of the BasicTest class. It saves the new object in the $basicTestObject variable.
#The fifth command uses the Multiply method of $basicTestObject.
}
Function Example-2 {
    Write-Host "    -------------------------- EXAMPLE 2 --------------------------"
    [BasicTest] | Get-Member
    [BasicTest] | Get-Member -Static
    $basicTestObject | Get-Member
    [BasicTest] | Get-Member
    
    #TypeName: System.RuntimeType
    #Name                           MemberType Definition
    #----                           ---------- ----------
    #Clone                          Method     System.ObjectClone(
    #Equals                         Method     System.BooleanEquals
    #FindInterfaces                 Method     System.Type[] FindInt...
    
    [BasicTest] | Get-Member -static
    
    #TypeName: BasicTest
    #Name            MemberType Definition
    #----            ---------- ----------
    #Add             Method     static System.Int32 Add(Int32 a, Int32 b)
    #Equals          Method     static System.Boolean Equals(Object objA,
    #ReferenceEquals Method     static System.Boolean ReferenceEquals(Obj
    
    $basicTestObject | Get-Member
    
    #TypeName: BasicTest
    #Name        MemberType Definition
    #----        ---------- ----------
    #Equals      Method     System.Boolean Equals(Object obj)
    #GetHashCode Method     System.Int32 GetHashCode()
    #GetType     Method     System.Type GetType()
    #Multiply    Method     System.Int32 Multiply(Int32 a, Int32 b)
    #ToString    Method     System.String ToString()
    
#These commands use the Get-Member cmdlet to examine the objects that the Add-Type and New-Object cmdlets created in the previous example.
#The first command uses the Get-Member cmdlet to get the type and members of the BasicTest class that Add-Type added to the session. The Get-Member command reveals that it is a System.RuntimeType object, which is derived from the System.Object class.
#The second command uses the Static parameter of the Get-Member cmdlet to get the static properties and methods of the BasicTest class. The output shows that the Add method is included.
#The third command uses the Get-Member cmdlet to get the members of the object stored in the $BasicTestObject variable. This was the object instance that was created by using the New-Object cmdlet with the $BasicType class.
#The output reveals that the value of the $BasicTestObject variable is an instance of the BasicTest class and that it includes a member called Multiply.
}
Function Example-3 {
Write-Host "    -------------------------- EXAMPLE 3 --------------------------"
    $accType = Add-Type -AssemblyName accessib* -PassThru
    
#This command adds the classes from the Accessibility assembly to the current session. The command uses the AssemblyName parameter to specify the name of the assembly. The wildcard character allows you to get the correct assembly even when you are not sure of the name or its spelling.
#The command uses the PassThru parameter to generate objects that represent the classes that are added to the session, and it saves the objects in the $accType variable.
}
Function Example-4 {
Write-Host "    -------------------------- EXAMPLE 4 --------------------------"
    Add-Type -Path c:\ps-test\Hello.vb[VBFromFile]::SayHello(", World")
    
    # From Hello.vb
    
    #Public Class VBFromFilePublic Shared Function SayHello(sourceName As String) As StringDim myValue As String = "Hello"return myValue + sourceNameEnd FunctionEnd Class
    #[VBFromFile]::SayHello(", World")Hello, World
    
#This example uses the Add-Type cmdlet to add the VBFromFile class that is defined in the Hello.vb file to the current session. The text of the Hello.vb file is shown in the command output.
#The first command uses the Add-Type cmdlet to add the type defined in the Hello.vb file to the current session. The command uses the Path parameter to specify the source file.
#The second command calls the SayHello function as a static method of the VBFromFile class.
}
Function Example-5 {
Write-Host "    -------------------------- EXAMPLE 5 --------------------------"

$signature = @"
    [DllImport("user32.dll")]public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
"@
    $showWindowAsync = Add-Type -MemberDefinition $signature -Name "Win32ShowWindowAsync" -Namespace Win32Functions -PassThru 
    # Minimize the Windows PowerShell console
    $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 2)
    # Restore it
    $showWindowAsync::ShowWindowAsync((Get-Process -Id $pid).MainWindowHandle, 4)
#The commands in this example demonstrate how to call native Windows APIs in Windows PowerShell. Add-Type uses the Platform Invoke (P/Invoke) mechanism to call a function in User32.dll from Windows PowerShell.
#The first command stores the C# signature of the ShowWindowAsync function in the $signature variable. (For more information, see "ShowWindowAsync Function" in the MSDN library at http://go.microsoft.com/fwlink/?LinkId=143643.) To ensure that the resulting method will be visible in a Windows PowerShell session, the "public" keyword has been added to the standard signature.
#The second command uses the Add-Type cmdlet to add the ShowWindowAsync function to the Windows PowerShell session as a static method of a class that Add-Type creates. The command uses the MemberDefinition parameter to specify the method definition saved in the $signature variable.
#The command uses the Name and Namespace parameters to specify a name and namespace for the class. It uses the PassThru parameter to generate an object that represents the types, and it saves the object in the $showWindowAsync variable.
#The third and fourth commands use the new ShowWindowAsync static method. The method takes two parameters, the window handle, and an integer specifies how the window is to be shown.
#The third command calls ShowWindowAsync. It uses the Get-Process cmdlet with the $pid automatic variable to get the process that is hosting the current Windows PowerShell session. Then it uses the MainWindowHandle property of the current process and a value of "2", which represents the SW_MINIMIZE value.
#To restore the window, the fourth command use a value of "4" for the window position, which represents the SW_RESTORE value. (SW_MAXIMIZE is 3.)
}
Function Example-6 {
Write-Host "    -------------------------- EXAMPLE 6 --------------------------"
Add-Type -MemberDefinition $jsMethod -Name "PrintInfo" -Language JScript
    
#This command uses the Add-Type cmdlet to add a method from inline JScript code to the Windows PowerShell session. It uses the MemberDefinition parameter to submit source code stored in the $jsMethod variable. It uses the Name parameter to specify a name for the class that Add-Type creates for the method and the Language parameter to specify the JScript language.
}
Function Example-7 {
Write-Host "    -------------------------- EXAMPLE 7 --------------------------"
Add-Type -Path FSharp.Compiler.CodeDom.dll
Add-Type -Path FSharp.Compiler.CodeDom.dll
$Provider = New-Object Microsoft.FSharp.Compiler.CodeDom.FSharpCodeProvider
$fSharpCode = @"
    let rec loop n =if n <= 0 then () else beginprint_endline (string_of_int n);loop (n-1)end
"@
$fsharpType = Add-Type -TypeDefinition $fSharpCode -CodeDomProvider $Provider -PassThru | where { $_.IsPublic }
#$fsharpType::loop(4)4321
    
#This example shows how to use the Add-Type cmdlet to add an FSharp code compiler to your Windows PowerShell session. To run this example in Windows PowerShell, you must have the FSharp.Compiler.CodeDom.dll that is installed with the FSharp language.
#The first command in the example uses the Add-Type cmdlet with the Path parameter to specify an assembly. Add-Type gets the types in the assembly.
#The second command uses the New-Object cmdlet to create an instance of the FSharp code provider and saves the result in the $Provider variable.
#The third command saves the FSharp code that defines the Loop method in the $FSharpCode variable.
#The fourth command uses the Add-Type cmdlet to save the public types defined in $fSharpCode in the $fSharpType variable. The TypeDefinition parameter specifies the source code that defines the types. The CodeDomProvider parameter specifies the source code compiler.
#The PassThru parameter directs Add-Type to return a Runtime object that represents the types and a pipeline operator (|) sends the Runtime object to the Where-Object cmdlet, which returns only the public types. The Where-Object cmdlet is used because the FSharp provider generates non-public types to support the resulting public type.
#The fifth command calls the Loop method as a static method of the type stored in the $fSharpType variable.
}
#RelatedLinks
#    Online Version: http://go.microsoft.com/fwlink/p/?linkid=293943
#    Add-Member
#    New-Object