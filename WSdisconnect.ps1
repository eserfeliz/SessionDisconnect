function wait([int]$time)
{
	timeout -t $time;
}

function GetSessionInfo()
{
    $line = @(query session) | ?{$_.contains(">")}
    $raw = -split $line

    $session = New-Object psobject -Property @{"SessionName" = 0; "Username" = 0; "ID" = 0; "State" = 0;};
    $session.SessionName = $raw[0].trim(">")
    $session.Username = $raw[1]
    $session.ID = $raw[2]
    $session.State = $raw[3]
    return $session
}

$disconnected = New-Object psobject -Property @{"Count" = 0;};
$session = GetSessionInfo;
wait 10;
while ($session.Username -ne "Administrator") {
    while ($session.state -ne "Active" -and $session.state -ne "Disc") {
        $session = GetSessionInfo;
        $session
        wait 10;
    }
    while ($session.state -eq "Active") {
        Write-Host "I'm connected..."
        wait 9;
        $session
        $debugger=@(Get-Process | Get-Unique -asstring | Where-Object {($_.processname -eq "windbg") -or ($_.processname -eq "cdb")})
        while ($debugger) {
            Write-Warning "$debugger.name present, pausing script..."
            $x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            $debugger=@(Get-Process | Get-Unique -asstring | Where-Object {($_.processname -eq "windbg") -or ($_.processname -eq "cdb")})
        }
        $session = GetSessionInfo;
        if ($session.state -eq "Active") {
            $disconnected.Count += 1;
            Write-Host "This is disconnect number" $disconnected.Count
            &tsdiscon.exe $env:sessionname /v
            while ($session.state -ne "Disc") {
                wait 1;
                $session = GetSessionInfo;
                $session
            }
            Write-Warning "Disconnected!!!"
        }
    }
    $session = GetSessionInfo;
    while ($session.state -eq "Disc") {
        Write-Warning "I'm disconnected and waiting for a connection"
        $session = GetSessionInfo;
        $session
        wait 2;
    }
}
Write-Warning "The administrator is logged in. Pausing before exit."
$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")