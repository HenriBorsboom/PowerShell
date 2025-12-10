@echo off
ipconfig /flushdns
echo ---------- Flushed DNS
nbtstat -RR
echo ---------- NetBIOS RR
nbtstat -R
echo ---------- NetBIOS R
ipconfig /registerdns
echo ---------- Registered DNS
pause