function Invoke-ModuleUpdate {
    <#
    .SYNOPSIS
    Update one, several or all installed modules.
    
    .DESCRIPTION
    Invoke-ModuleUpdate, find or update installed modules that have a repository location, for example from PowerShell Gallery.    
    The script is based on the "Check-ModuleUpdate.ps1" from Jeffery Hicks* to check for available updates for installed PowerShell modules.

    *Credit: http://jdhitsolutions.com/blog/powershell/5441/check-for-module-updates/
    
    .PARAMETER Name
    Specifies names or name patterns of modules that this cmdlet gets. Wildcard characters are permitted. 
    
    .PARAMETER Update
    Switch parameter to update modules specified.
    
    .PARAMETER Force
    # Switch parameter forces the update of each specified module, regardless of the current version of the module installed.

    .EXAMPLE
    An example
    
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
        [Parameter(
            ParameterSetName = 'Update',
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Name = '*',

        # Switch parameter to update modules specified.
        [Parameter(
            Position = 1,
            ParameterSetName = 'Update'
        )]
        [switch]$Update,

        # Switch parameter to list/update all modules.
        [Parameter(
            ValueFromPipeline = $true,
            Position = 2
        )]
        [Parameter(
            Position = 2,
            ParameterSetName = 'Update'
        )]
        [switch]$All,

        # Switch parameter forces the update of each specified module, regardless of the current version of the module installed.
        [Parameter(
            Position = 3,
            ParameterSetName = 'Update'
        )]
        [switch]$Force
    )

    begin {
        try {
            [array]$Modules = (Get-Module -Name $Name -ListAvailable -ErrorAction Stop).Where( {$null -ne $_.RepositorySourceLocation}) | Group-Object -Property Name

            if ($Modules.Count -eq 1) {
                [int]$TotalCount = $Modules.Count
            }
            else {
                [int]$TotalCount = $Modules.Count + 1
            }
            
            # To speed up 'Find-Module' cmdlet and not query all existing repositories.
            $Repositories = Get-PSRepository -ErrorAction Stop
        
            switch ($Update) {
                'True' {
                    $Status = 'Updating module'
                }
                Default {
                    $Status = 'Check latest module version for'
                }
            }
        }
        catch {
            
        }
    }
    process {
        foreach ($Group in $Modules) {
            $PercentComplete = '{0:N0}' -f (($Modules.IndexOf($Group) / $TotalCount) * 100)
            Write-Progress -Activity ('{0} {1}' -f $Status, $Group.Group[0].Name) -Status ('{0}% Complete:' -f $PercentComplete) -PercentComplete $PercentComplete

            if ($Group.Count -gt 1) {
                $Module = (($Group).Group | Sort-Object -Property Version -Descending)[0]
            }
            else {
                $Module = $Group.Group[0]
            }

            try {
                $Repository = ($Repositories.Where{[string]$_.SourceLocation -eq [string]$Module.RepositorySourceLocation}).Name
                $Online = Find-Module -Name $Module.Name -Repository $Repository -ErrorAction Stop
            }
            catch {
                Write-Warning -Message ('Unable to find module {0} at repository {1}. Error: {2}' -f $Module.Name, $Repository, $_.Exception.Message)
                continue
            }
            if ([version]$Online.Version -gt [version]$Module.Version) {
                [PSCustomObject]@{
                    Name           = $Module.Name
                    CurrentVersion = $Module.Version
                    NewVersion     = $Online.Version
                }
            }
        }
    }
}