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
    Parameter description
    
    .PARAMETER Force
    Parameter description

    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    param (
        # Specifies names or name patterns of modules that this cmdlet gets. Wildcard characters are permitted. 
        [Parameter(AttributeValues)]
        [ParameterType]
        [WildcardPattern()]
        $Name = '*',

        # Force update modules
        [Parameter(AttributeValues)]
        [ParameterType]
        $ParameterName
    )
}

$Modules = Get-Module -Name $Name -ListAvailable | Where-Object -FilterScript {
    $_.RepositorySourceLocation -ne $null
} | Group-Object -Property Name
$Paramet 

$TotalCount = $Modules.Count

foreach ($Group in $Modules) {
    Write-Progress -Activity "Update in progress" -Status "$I% Complete:" -PercentComplete $I;

    if ($Group.Count -gt 1) {
        $Module = (($Group).Group | Sort-Object -Property Version -Descending)[0]
    }
    else {
        $Module = $Group.Group
    }

    $Online = Find-Module -Name $Module.Name
    if ([version]$Online.Version -gt [version]$Module.Version) {
        [PSCustomObject]@{
            Name           = $Module.Name
            CurrentVersion = $Module.Version
            NewVersion     = $Online.Version
        }
    }
}