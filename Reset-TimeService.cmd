net stop w32time
w32tm /config /syncfromflags:domhier
net start w32time
w32tm /config /update
w32tm /resync /rediscover
w32tm /query /source
