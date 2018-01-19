function Invoke-ModuleUpdate {
    <#
    .SYNOPSIS
    Update one, several or all installed modules if an update is available.
    
    .DESCRIPTION
    Invoke-ModuleUpdate, installed modules that have a repository location, for example from PowerShell Gallery.    
    The script is based on the "Check-ModuleUpdate.ps1" from Jeffery Hicks* to check for available updates for installed PowerShell modules.

    The switch parameter 'All' can be used to query all installed modules even if a repository isn't specified.
    For instance Pester module is included in Windows 10/2016 by default and does not have repository specified.

    *Credit: http://jdhitsolutions.com/blog/powershell/5441/check-for-module-updates/
    
    .PARAMETER Name
    Specifies names or name patterns of modules that this cmdlet gets. Wildcard characters are permitted.
    
    .PARAMETER Update
    Switch parameter to invoke a 'Update-Module' for targeted modules. Default this is off and the function will only list the current and available versions.

    .PARAMETER All
    Switch parameter to check for all installed modules, regardless of a specified repository or not.
    
    .PARAMETER Force
    # Switch parameter forces the update of each specified module, regardless of the current version of the module installed.

    .EXAMPLE
    Invoke-ModuleUpdate

    .EXAMPLE
    Invoke-ModuleUpdate -Update

    .EXAMPLE
    Invoke-ModuleUpdate -Name 'AzureAD', 'PSScriptAnalyzer' -Update

    .EXAMPLE
    Invoke-ModuleUpdate -All

    .NOTES
    General notes
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

        # Switch parameter to invoke a 'Update-Module' for targeted modules. Default this is off and the function will only list the current and available versions.
        [Parameter(
            Position = 1
        )]
        [switch]$Update,

        # Switch parameter to check for all installed modules, regardless of a specified repository or not.
        [Parameter(
            Position = 2
        )]
        [switch]$All,

        # Switch parameter forces the update of each specified module, regardless of the current version of the module installed.
        [Parameter(
            Position = 3
        )]
        [switch]$Force
    )

    begin {
        try {
            
            [array]$Modules = Get-Module -Name $Name -ListAvailable -ErrorAction Stop
            
            # List all installed modules based on the switch parameter 'All'
            if (-not ($PSBoundParameters.ContainsKey('All'))) {
                [array]$Modules = $Modules.Where( {$null -ne $_.RepositorySourceLocation} )
                $FindModule = @{
                    ErrorAction = 'Stop'
                }
            }

            # Sort the modules using the Length of the 'Name' property (pipeline with PSCustomObject uses the default 8 char length and trims output with dots.)
            # Group all modules to exclude multiple versions.
            [array]$Modules = $Modules | Sort-Object -Property {$_.Name.Length}, Name -Descending | Group-Object -Property Name

            if ($Modules.Count -eq 1) {
                [int]$TotalCount = $Modules.Count
            }
            else {
                [int]$TotalCount = $Modules.Count + 1
            }
            
            # To speed up the 'Find-Module' cmdlet and not query all existing repositories.
            [PSCustomObject]$Repositories = Get-PSRepository -ErrorAction Stop
        
            switch ($Update) {
                True {
                    [string]$Status = 'Updating module'
                }
                Default {
                    [string]$Status = 'Check latest module version for'
                }
            }

            switch ($Force) {
                True {
                    $ForceModule = @{
                        Force       = $true
                        ErrorAction = 'Stop'
                    }
                }
                Default {
                    $ForceModule = @{
                        Force       = $false
                        ErrorAction = 'Stop'
                    }
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
    }
    process {
        foreach ($Group in $Modules) {
            [int]$PercentComplete = '{0:N0}' -f (($Modules.IndexOf($Group) / $TotalCount) * 100)
            Write-Progress -Activity ('{0} {1}' -f $Status, $Group.Group[0].Name) -Status ('{0}% Complete:' -f $PercentComplete) -PercentComplete $PercentComplete
            
            if ($PSCmdlet.ShouldProcess(('{0}' -f $Group.Group[0].Name), $MyInvocation.MyCommand.Name)) {
                if ($Group.Count -gt 1) {
                    [string[]]$MultipleVersions = $Group.Group.Version[1..($Group.Group.Version.Length)]
                    [Management.Automation.PSModuleInfo]$Module = (($Group).Group | Sort-Object -Property Version -Descending)[0]
                }
                else {
                    [bool]$MultipleVersions = $false
                    [Management.Automation.PSModuleInfo]$Module = $Group.Group[0]
                }

                try {
                    if (($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name) {
                        Write-Verbose -Message ($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name
                        $FindModule = @{
                            Repository  = ($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name
                            ErrorAction = 'Stop'
                        }
                        $Repository = 'in repository {0}' -f $Repository
                    }
                    [PSCustomObject]$Online = Find-Module -Name $Module.Name @FindModule
                }
                catch {
                    Write-Warning -Message ('Unable to find module {0}{1}. Error: {2}' -f $Module.Name, $Repository, $_.Exception.Message)
                    continue
                }

                [version]$CurrentVersion = $Module.Version
                if ($PSBoundParameters.ContainsKey('Update')) {
                    if ([version]$Online.Version -gt [version]$Module.Version) {
                        try {
                            Update-Module -Name $Module.Name @Force
                            [version]$CurrentVersion = $Online.Version
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
                
                [PSCustomObject]@{
                    'Name'              = [string]$Module.Name
                    'Current Version'   = $CurrentVersion
                    'Online Version'    = $Online.Version
                    'Multiple Versions' = $MultipleVersions
                }
            }             
        }
    }
}