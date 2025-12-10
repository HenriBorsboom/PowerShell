C:\Scripts\Set-DnsTtlA.ps1 -Zone 'bank.local' -Name 'mydummyhost' -TTL 10 
C:\Scripts\Set-DnsTtlCNAME.ps1 -Zone 'bank' -Name 'dummyalias.ext' -TTL 10 -NewTarget 'mydummyhost1.bank.local.'
C:\Scripts\Set-DnsTtlCNAME.ps1 -Zone 'bank' -Name 'dummyalias.int' -TTL 10 
