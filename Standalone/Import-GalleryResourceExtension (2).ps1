#Param(
#    [Parameter(Mandatory=$true,Position=1)]
#    [String] $GalleryResourceExtensionPath)

Function Import-GalleryResourceExtension {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [String] $GalleryResourceExtensionPath)

    $libraryShare = Get-SCLibraryShare | Where-Object {$_.Name -eq 'MSSCVMMLibrary'} 
    $resextpkg = $GalleryResourceExtensionPath
    Import-CloudResourceExtension –ResourceExtensionPath $resextpkg -SharePath $libraryShare #-AllowUnencryptedTransfer
    #Remove-CloudResourceExtension -ResourceExtension $resextpkg
}

Import-GalleryResourceExtension -GalleryResourceExtensionPath "C:\Gallery Resources\VM Role\Windows Gateway Server\Windows Gateway Server.resextpkg"