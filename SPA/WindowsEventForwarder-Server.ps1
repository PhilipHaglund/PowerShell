# https://github.com/iadgov/Event-Forwarding-Guidance

function Set-EventLogPath { 
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [string]$LogName,

        [Parameter(
            Mandatory = $true
        )]
        [string]$NewLogPath,

        [string]$Computername = $env:COMPUTERNAME
    )
    try {
        $EventLogSession = New-Object -TypeName System.Diagnostics.Eventing.Reader.EventLogSession -ArgumentList $Computername -ErrorAction Stop
        $EventLogConfig = New-Object -TypeName System.Diagnostics.Eventing.Reader.EventLogConfiguration -ArgumentList $LogName, $Eventlogsession -ErrorAction Stop

        $LogFilePath = $EventLogConfig.LogFilePath
        $LogFile = Split-Path -Path $LogFilePath -Leaf 
        $NewLogFilePath = ('{0}\{1}' -f $NewLogPath, $LogFile)
        $EventLogConfig.LogFilePath = $NewLogFilePath 
        $EventLogConfig.SaveChanges() 
    }
    catch {
        $Ex = New-Object -TypeName System.Exception -ArgumentList ('{0}' -f $_.Exception.Message)
        $Category = [System.Management.Automation.ErrorCategory]::InvalidData
        $ErrRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Ex, 'InvalidEventLog', $Category, $_.InvocationInfo
        $PSCmdLet.WriteError($ErrRecord)
        return
    }
    
} 

$Subscriptions = & "wecutil" es

foreach ($Item in $Subscriptions) {
    $LogName = 'WEF-{0}' -f $Item
    New-EventLog -LogName $Item -Source $Item
    Limit-EventLog -LogName $Item -MaximumSize 1GB

    Set-EventLogPath -LogName $Item -NewLogPath "%SystemDrive%\Logs"
}