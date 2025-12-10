Param(
    [Parameter(Mandatory=$True,Position=1)]
    [String] $ConnectionString)

Function TestSQLConnection
{
    Param(
        [Parameter(Mandatory=$True,Position=1)]
        [String] $ConnectionString)
    #Create SQL Connection
    $con = new-object "System.data.sqlclient.SQLconnection"
    Write-Host "Opening SQL connection to $ConnectionString"

    $con.ConnectionString =("$ConnectionString")
    try {
        $con.Open() 
        Write-Host "  Successfully opened connection to the database" -ForegroundColor Green
    }
    catch {
        $error[0]
        Write-Host " Failed to open a connection to the database"
        exit 1
    }
    finally{
        Write-Host "  Closing SQL connection - " -NoNewline
        $con.Close()
        $con.Dispose()
        Write-Host "Connection closed." -ForegroundColor Green
    }
}

If ($ConnectionString -ne $null)
{
    TestSQLConnection -ConnectionString $ConnectionString
}
Else
{
    Write-Host "Please specify the connection string in the folllowing format:"
    Write-Host "  Test-SQLConnection -ConnectionString 'Data Source=<Server>;Initial Catalog=<Catalog>;User ID=<User>;Password=<Password>'"
    Write-Host "    Where:"
    Write-Host "      Server     - Server to connect to"
    Write-Host "      Catalog    - Catalog to connect to"
    Write-Host "      User       - User with sign on permission"
    Write-Host "      Password   - Password for user"
}

