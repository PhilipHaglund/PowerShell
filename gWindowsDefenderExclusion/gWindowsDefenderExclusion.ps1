enum Ensure 
{
    Absent
    Present
}
enum ExclusionExtension
{
    Correct
    Wrong
}
enum ExclusionPath
{
    Correct
    Wrong
}
enum ExclusionProcess
{
    Correct
    False
}


[DscResource()]
class gWindowsDefenderExclusion
{
    [DscProperty(
        Mandatory = $true,
        Key = $true
    )]
    [Ensure]$Ensure

    [DscProperty()]
    [string[]]$ExclusionExtension

    [DscProperty()]
    [string[]]$ExclusionPath

    [DscProperty()]
    [string[]]$ExclusionProcess


    [gWindowsDefenderExclusion]Get()
    {
        Write-Verbose -Message ('{0} - Getting Windows Defender Exclusion' -f $MyInvocation.MyCommand)

        $this.ExclusionExtension = $this.GetExclusion().Properties.ExclusionExtension
        $this.ExclusionPath = $this.GetExclusion().Properties.ExclusionPath
        $this.ExclusionProcess  = $this.GetExclusion().Properties.ExclusionProcess        
        
        return $this
    }

    [bool]Test()
    {
        Write-Verbose -Message ('{0} - Testing Windows Defender Exclusion' -f $MyInvocation.MyCommand)

        if ($this.ExclusionExtension -notmatch $this.GetExclusion().Properties.ExclusionExtension)
        {
            [ExclusionExtension]::Wrong
        }
        else
        {
            [ExclusionExtension]::Correct
        }
        
        if ($this.ExclusionPath -notmatch $this.GetExclusion().Properties.ExclusionPath)
        {
            [ExclusionPath]::Wrong
        }
        else
        {
            [ExclusionPath]::Correct
        }

        if ($this.ExclusionProcess -notmatch $this.GetExclusion().Properties.ExclusionProcess)
        {
            [ExclusionProcess]::Wrong
        }
        else
        {
            [ExclusionProcess]::Correct
        }

        return $true
    }

    [void]Set()
    {
        Write-Verbose -Message ('{0} - Setting Windows Defender Exclusion' -f $MyInvocation.MyCommand)
    }

    [PSCustomObject]GetExclusion()
    {
        try
        {
            $CurrentExclusionProcess = Get-MpPreference -ErrorAction Stop
            return $CurrentExclusionProcess
        }
        catch
        {
            return $false
        }

      
    }
}