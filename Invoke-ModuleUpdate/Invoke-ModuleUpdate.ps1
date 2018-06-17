function Invoke-ModuleUpdate {
    <#
    .SYNOPSIS
    Update one, several or all installed modules if an update is available.
    
    .DESCRIPTION
    Invoke-ModuleUpdate for installed modules that have a repository location for example from PowerShell Gallery.
    The script is based on the "Check-ModuleUpdate.ps1" from Jeffery Hicks* to check for available updates for installed PowerShell modules.

    *Credit: http://jdhitsolutions.com/blog/powershell/5441/check-for-module-updates/
    
    .PARAMETER Name
    Specifies names or name patterns of modules that this cmdlet gets. Wildcard characters are permitted.
    
    .PARAMETER Update
    Switch parameter to invoke a 'Update-Module' for targeted modules. The default behavior without this switch is that the function will only list the current and available versions.
    
    .PARAMETER Force
    Switch parameter forces the update of each specified module, regardless of the current version of the module installed.

    .EXAMPLE
    Invoke-ModuleUpdate

    Name                                                             Current Version  Online Version   Multiple Versions
    ----                                                             ---------------  --------------   -----------------
    SpeculationControl                                               1.0.0            1.0.8            False
    AzureAD                                                          2.0.0.131        2.0.1.10         {2.0.0.115}
    AzureADPreview                                                   2.0.0.154        2.0.1.11         {2.0.0.137}
    ISESteroids                                                      2.7.1.7          2.7.1.7          {2.6.3.30}
    MicrosoftTeams                                                   0.9.1            0.9.3            False
    NTFSSecurity                                                     4.2.3            4.2.3            False
    Office365Connect                                                 1.5.0            1.5.0            False
    ...                                                              ...              ...              ...

    This example returns the current and the latest version available for all installed modules that have a repository location.

    .EXAMPLE
    Invoke-ModuleUpdate -Update

    Name                                                             Current Version  Online Version   Multiple Versions
    ----                                                             ---------------  --------------   -----------------
    SpeculationControl                                               1.0.8            1.0.8            {1.0.0}
    AzureAD                                                          2.0.1.10         2.0.1.10         {2.0.0.131, 2.0.0.115}
    AzureADPreview                                                   2.0.1.11         2.0.1.11         {2.0.0.137, 2.0.0.154}
    ISESteroids                                                      2.7.1.7          2.7.1.7          {2.6.3.30}
    MicrosoftTeams                                                   0.9.3            0.9.3            {0.9.1}
    NTFSSecurity                                                     4.2.3            4.2.3            False
    Office365Connect                                                 1.5.0            1.5.0            False
    ...                                                              ...              ...              ...

    This example installs the latest version available for all installed modules that have a repository location.

    .EXAMPLE
    Invoke-ModuleUpdate -Name 'AzureAD', 'PSScriptAnalyzer' -Update

    Name                                                             Current Version  Online Version   Multiple Versions
    ----                                                             ---------------  --------------   -----------------
    SpeculationControl                                               1.0.8            1.0.8            {1.0.0}
    AzureAD                                                          2.0.1.10         2.0.1.10         {2.0.0.131, 2.0.0.115}
    PSScriptAnalyzer                                                 1.17.1           1.17.1           {1.17.0}

    .NOTES
    Requires PowerShell 4.0
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (
        # Specifies names or name patterns of modules that this cmdlet gets. Wildcard characters are permitted.
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Name = '*',

        # Switch parameter to invoke a 'Update-Module' for targeted modules. The default behavior without this switch is that the function will only list the current and available versions.
        [Parameter(
            Position = 1
        )]
        [switch]$Update,

        # Switch parameter forces the update of each specified module, regardless of the current version of the module installed.
        [Parameter(
            Position = 3
        )]
        [switch]$Force
    )

    begin {
        try {            
            [array]$Modules = (Get-Module -Name $Name -ListAvailable -ErrorAction Stop).Where( {$null -ne $_.RepositorySourceLocation} )
            
            # Sort the modules using the Length of the 'Name' property (pipeline with PSCustomObject uses the default 8 char length and trims output with dots.)
            # Group all modules to exclude multiple versions.
            [array]$Modules = $Modules | Group-Object -Property Name

            if ($Modules.Count -lt 1) {
                [int]$TotalCount = $Modules.Count + 1
            }
            else {
                [int]$TotalCount = $Modules.Count
            }
            
            # To speed up the 'Find-Module' cmdlet and not query all existing repositories, save all existing repositories.
            [PSCustomObject]$Repositories = Get-PSRepository -ErrorAction Stop
        
            switch ($Update) {
                $true {
                    [string]$Status = 'Updating module'
                }
                Default {
                    [string]$Status = 'Looking for the latest version for module'
                }
            }
        }
        catch {
            [Exception]$Ex = New-Object -TypeName System.Exception -ArgumentList ('{0}{1}' -f 'Unable to get module information. Error: ', $_.Exception.Message)
            [Management.Automation.ErrorCategory]$Category = [System.Management.Automation.ErrorCategory]::InvalidResult
            [Management.Automation.ErrorRecord]$ErrRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList $Ex, 'ModuleError', $Category, $_.InvocationInfo
            $PSCmdLet.WriteError($ErrRecord)
            break
        }
        try {
            Update-FormatData -PrependPath $PSScriptRoot\Invoke-ModuleUpdate.format.ps1xml -ErrorAction Stop
        }
        catch {
            Write-Warning -Message ('Unable to Update-FormatData. Error {0}' -f $_.Exception.Message)
        }
    }
    process {
        foreach ($Group in $Modules) {
            [int]$PercentComplete = '{0:N0}' -f (($Modules.IndexOf($Group) / $TotalCount) * 100)
            Write-Progress -Activity ('{0} {1}' -f $Status, $Group.Group[0].Name) -Status ('{0}% Complete:' -f $PercentComplete) -PercentComplete $PercentComplete
            
            if ($PSCmdlet.ShouldProcess(('{0}' -f $Group.Group[0].Name), $MyInvocation.MyCommand.Name)) {
                switch ($Group.Count) {
                    ( {$PSITem -gt 1}) {
                        [string[]]$MultipleVersions = $Group.Group.Version[1..($Group.Group.Version.Length)]
                        [Management.Automation.PSModuleInfo]$Module = (($Group).Group | Sort-Object -Property Version -Descending)[0]
                    }
                    Default {
                        [bool]$MultipleVersions = $false
                        [Management.Automation.PSModuleInfo]$Module = $Group.Group[0]
                    }
                }
                try {
                    if ($Repository = ($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name) {
                        Write-Verbose -Message ($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name
                        $FindModule = @{
                            Repository  = $Repository
                            ErrorAction = 'Stop'
                        }
                    }
                    else {
                        $FindModule = @{
                            ErrorAction = 'Stop'
                        }
                    }
                    [PSCustomObject]$Online = Find-Module -Name $Module.Name @FindModule
                }
                catch {
                    Write-Warning -Message ('Unable to find module {0}. Error: {1}' -f $Module.Name, $_.Exception.Message)
                    continue
                }

                [version]$CurrentVersion = $Module.Version
                if ($PSBoundParameters.ContainsKey('Update')) {
                    if ([version]$Online.Version -gt [version]$Module.Version) {
                        try {
                            Update-Module -Name $Module.Name -Force:$PSBoundParameters['Force'] -ErrorAction Stop
                            [version]$CurrentVersion = $Online.Version
                            $MultipleVersions += $Module.Version 
                        }
                        catch {
                            Write-Warning -Message ('Unable to update module. Error: {0}' -f $_.Exception.Message)
                            [version]$CurrentVersion = $Module.Version
                        }
                    }
                    else {
                        [version]$CurrentVersion = $Online.Version
                    }
                }
                
                $PSObject = [PSCustomObject]@{
                    'Name'              = [string]$Module.Name
                    'Current Version'   = $CurrentVersion
                    'Online Version'    = $Online.Version
                    'Multiple Versions' = $MultipleVersions
                }
                
                $PSObject.PSObject.TypeNames.Insert(0, 'Omnicit.Invoke.ModuleUpdate')
                $PSObject
            }             
        }
    }
}