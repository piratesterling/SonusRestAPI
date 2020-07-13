Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser;
Enum Level {    
    fatal = 1
    error = 2
    warn  = 3
    info  = 4
    debug = 5
    trace = 6
}

Enum Appender {
    File   = 1
    Screen = 2
}

Class AltiLog {
    [String]$file
    [Level]$level
    [Appender]$appender
    

    fatal($msg) {
        Write-Host $this.level.value__
        if ($this.level.value__ -ge '1') {
            $msgLevel = "FATAL";
            $this.write($msg, $msgLevel);
        }
    }

    error($msg) {
        if ($this.level.value__ -ge '2') {
            $msgLevel = "ERROR";
            $this.write($msg, $msgLevel);
        }
    }

    warn($msg) {
        if ($this.level.value__ -ge '3') {
            $msgLevel = "WARN ";
            $this.write($msg, $msgLevel);
        }
    }

    info($msg) {
        if ($this.level.value__ -ge '4') {
            $msgLevel = "INFO ";
            $this.write($msg, $msgLevel);
        }
    }

    debug($msg) {
        if ($this.level.value__ -ge '5') {
            $msgLevel = "DEBUG";
            $this.write($msg, $msgLevel);
        }
    }

    trace($msg) {
        if ($this.level.value__ -ge '6') {
            $msgLevel = "TRACE";
            $this.write($msg, $msgLevel);
        }
    }

    write($msg, $msgLevel) {
        $Computer = "[$env:COMPUTERNAME]";
        $timestamp = Get-Date -UFormat "%D %T";
        $msgLevel = "[$msgLevel]";
        $msg = "$Computer $timestamp $msgLevel - $msg";
        if ( $this.appender -contains 'File' ){
            Add-Content -Path $this.file -Value $msg
        }
        elseif( $this.appender -eq 'Screen' ){
            Write-Host $msg
        }
    }
}

#$log = New-Object Log -Property @{file="c:\Logging.txt";level="info"}
