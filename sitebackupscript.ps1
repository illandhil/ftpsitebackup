# Load WinSCP .NET assembly from Location Defined
[Reflection.Assembly]::LoadFrom("C:\Program Files (x86)\WinSCP\WinSCPnet.dll") | Out-Null
 
# Session.FileTransferred event handler
 
function FileTransferred
{
    Param($e)
 
    if ($e.Error -eq $Null)
    {
        Write-Host ("Upload of {0} succeeded" -f $e.FileName)
    }
    else
    {
        Write-Host ("Upload of {0} failed: {1}" -f $e.FileName, $e.Error)
    }
 
    if ($e.Chmod -ne $Null)
    {
        if ($e.Chmod.Error -eq $Null)
        {
            Write-Host ("Permisions of {0} set to {1}" -f $e.Chmod.FileName, $e.Chmod.FilePermissions)
        }
        else
        {
            Write-Host ("Setting permissions of {0} failed: {1}" -f $e.Chmod.FileName, $e.Chmod.Error)
        }
 
    }
    else
    {
        Write-Host ("Permissions of {0} kept with their defaults" -f $e.Destination)
    }
 
    if ($e.Touch -ne $Null)
    {
        if ($e.Touch.Error -eq $Null)
        {
            Write-Host ("Timestamp of {0} set to {1}" -f $e.Touch.FileName, $e.Touch.LastWriteTime)
        }
        else
        {
            Write-Host ("Setting timestamp of {0} failed: {1}" -f $e.Touch.FileName, $e.Touch.Error)
        }
 
    }
    else
    {
        # This should never happen with Session.SynchronizeDirectories
        Write-Host ("Timestamp of {0} kept with its default (current time)" -f $e.Destination)
    }
}
 
# Main script
 
try
{
    $sessionOptions = New-Object WinSCP.SessionOptions
    $sessionOptions.Protocol = [WinSCP.Protocol]::Sftp
    $sessionOptions.HostName = "website.com"
    $sessionOptions.UserName = "username"
    $sessionOptions.Password = "password"
    # $sessionOptions.SshHostKeyFingerprint = "ssh-rsa 2048 xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx"
 
    $session = New-Object WinSCP.Session
    try
    {
        # Will continuously report progress of synchronization
        $session.add_FileTransferred( { FileTransferred($_) } )
 
        # Connect
        $session.Open($sessionOptions)
 
        # Synchronize files
        $synchronizationResult = $session.SynchronizeDirectories(
            [WinSCP.SynchronizationMode]::Local, "C:\Yourlocaldirectory", "/RemoteDirectoryofSite", $False)
 
        # Throw on any error
        $synchronizationResult.Check()
    }
    finally
    {
        # Disconnect, clean up
        $session.Dispose()
    }

    exit 0
}
catch [Exception]
{
    # Output Error Message to Log File Defined by User
    Write-Host $_.Exception.Message | Out-File "C:\ScriptsLogs\FTPBackupErrors.log" -Append
    exit 1
}
