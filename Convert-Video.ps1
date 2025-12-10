Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceFolder, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Extension)

Function Convert-Video {
    Param (
        [Parameter(Mandatory=$True, Position=1)]
        [String] $SourceFolder, `
        [Parameter(Mandatory=$True, Position=2)]
        [String] $Extension)

    $Filter = ("*." + $Extension)
    
    $FileList = Get-ChildItem $SourceFolder -Filter $Filter -Recurse
 
    $Num       = $FileList | measure
    $FileCount = $Num.Count
 
    $i = 0
    
    ForEach ($File in $FileList) {
        $i++
        $OldFile = $File.DirectoryName + "\" + $File.BaseName + $File.Extension;
        $NewFile = $File.DirectoryName + "\" + $File.BaseName + ".mp4";
      
        $Progress = ($i / $FileCount) * 100
        $Progress = [Math]::Round($Progress, 2)
 
        
        Write-Host "-------------------------------------------------------------------------------"
        Write-Host "                            Handbrake Batch Encoding"
        Write-Host "Processing - $OldFile"
        Write-Host "File $i of $FileCount - $Progress%"
        Write-Host "-------------------------------------------------------------------------------"
     
        Start-Process "C:\Program Files\HandBrake\HandBrakeCLI.exe" -ArgumentList "-i `"$oldfile`" -t 1 --angle 1 -c 1 -o `"$newfile`" -f mp4  -O  --decomb --modulus 16 -e x264 -q 32 --vfr -a 1 -E lame -6 dpl2 -R Auto -B 48 -D 0 --gain 0 --audio-fallback ffac3 --x264-preset=veryslow  --x264-profile=high  --x264-tune=`"animation`"  --h264-level=`"4.1`"  --verbose=0" -Wait
    }
}
Clear-Host
Convert-Video -SourceFolder $SourceFolder -Extension $Extension
