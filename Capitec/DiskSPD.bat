@Echo off
REM C:\DiskSpd\diskspd.exe -c1G -d10 -r -w0 -t8 -o8 -b8K -h -L X:\testfile.dat
set diskSpdPath=D:\Apps\Captools\Scripts\DISKSPD\amd64\diskspd.exe
set drivepath=%1
set driveletter=%2

REM Parameter	Description										Notes
REM -c			Size of file used.								Specify the number of bytes or use suffixes like K, M or G (KB, MB, or GB). You should use a large size (all of the disk) for HDDs, since small files will show unrealistically high performance (short stroking).
REM -d			The duration of the test, in seconds.			You can use 10 seconds for a quick test. For any serious work, use at least 60 seconds.
REM -w			Percentage of writes.							0 means all reads, 100 means all writes, 30 means 30% writes and 70% reads. Be careful with using writes on SSDs for a long time, since they can wear out the drive. The default is 0.
REM -r			Random											Random is common for OLTP workloads. Sequential (when –r is not specified) is common for Reporting, Data Warehousing.
REM -b			Size of the IO in KB							Specify the number of bytes or use suffixes like K, M or G (KB, MB, or GB). 8K is the typical IO for OLTP workloads. 512K is common for Reporting, Data Warehousing.
REM -t			Threads per file								For large IOs, just a couple is enough. Sometimes just one. For small IOs, you could need as many as the number of CPU cores.
REM -o			Outstanding IOs or queue depth (per thread)		In RAID, SAN or Storage Spaces setups, a single disk can be made up of multiple physical disks. You can start with twice the number of physical disks used by the volume where the file sits. Using a higher number will increase your latency, but can get you more IOPs and throughput.
REM -L			Capture latency information						Always important to know the average time to complete an IO, end-to-end.
REM -h			Disable hardware and software caching			No hardware or software buffering. Buffering plus a small file size will give you performance of the memory, not the disk.

REM -c1G -d60 -r -w0 -t2 -o2 -b8K -h -L %drivepath%\DiskBenchmark\testfile.dat
md %drivepath%\DiskBenchmark\Results
md \\cbfp01\Temp\Henri\Benchmark\%COMPUTERNAME%

echo ****** RANDOM READ PERFORMANCE TESTING *****
echo ** Single page read **
%diskSpdPath% -c1G -d60 -r -w0 -t2 -o2 -b8K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads8KRandom8Oustanding_SinglePage.txt
timeout /T 3
echo ** Extent read **
%diskSpdPath% -c1G -d60 -r -w0 -t2 -o2 -b64K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads64KRandom8Oustanding_Extent.txt
timeout /T 3
echo ** Read ahead **
%diskSpdPath% -c1G -d60 -r -w0 -t2 -o2 -b512K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads512KRandom8Oustanding_ReadAhead.txt
timeout /T 3

echo ****** RANDOM WRITE PERFORMANCE TESTING *****
echo ** Single page write **
%diskSpdPath% -c1G -d60 -r -w100 -t2 -o2 -b8K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes8KRandom8Outstanding_SignlePage.txt
timeout /T 3
echo ** Extent write **
%diskSpdPath% -c1G -d60 -r -w100 -t2 -o2 -b64K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes64KRandom8Outstanding_Extent.txt
timeout /T 3
echo ** Checkpoint 1 **
%diskSpdPath% -c1G -d60 -r -w100 -t1 -o100 -b256K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes256KRandom100Outstanding_CheckPoint1.txt
timeout /T 3
echo ** Checkpoint 2 **
%diskSpdPath% -c1G -d60 -r -w200 -t1 -o100 -b256K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes256KRandom200Outstanding_CheckPoint2.txt

echo ****** SEQUENTIAL READ PERFORMANCE TESTING *****
echo ** Single page read **
%diskSpdPath% -c1G -d60 -w0 -t2 -o2 -b8K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads8KSequential8Oustanding_SinglePage.txt
timeout /T 3
echo ** Extent read **
%diskSpdPath% -c1G -d60 -w0 -t2 -o2 -b64K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads64KSequential8Oustanding_Extent.txt
timeout /T 3
echo ** Read ahead **
%diskSpdPath% -c1G -d60 -w0 -t2 -o2 -b512K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Reads512KSequential8Oustanding_ReadAhead.txt
timeout /T 3

echo ****** SEQUENTIAL WRITE PERFORMANCE TESTING *****
echo ** Single page write **
%diskSpdPath% -c1G -d60 -w100 -t2 -o2 -b8K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes8KSequential8Outstanding_SinglePage.txt
timeout /T 3
echo ** Extent write **
%diskSpdPath% -c1G -d60 -w100 -t2 -o2 -b64K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes64KSequential8Outstanding_Extent.txt
timeout /T 3
echo ** Checkpoint 1 **
%diskSpdPath% -c1G -d60 -w100 -t1 -o100 -b256K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes256KSequential100Outstanding_CheckPoint1.txt
timeout /T 3
echo ** Checkpoint 2 **
%diskSpdPath% -c1G -d60 -w100 -t1 -o200 -b256K -h -L %drivepath%\DiskBenchmark\testfile.dat > %drivepath%\DiskBenchmark\Results\%driveletter%_Writes256KSequential200Outstanding_CheckPoint2.txt

copy %drivepath%\DiskBenchmark\Results\*.txt \\CBFP01\Temp\Henri\Benchmark\%COMPUTERNAME%
