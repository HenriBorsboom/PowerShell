Net User EOHRT 30HP@ssw0rd /Add
net localgroup Administrators EOHRT /Add
Net LocalGroup Users EOHRT /Delete
WMIC USERACCOUNT WHERE "Name='EOHRT'" SET PasswordExpires=FALSE
