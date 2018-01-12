function Invoke-ModuleUpdate {
    <#
    .SYNOPSIS
    Update one, several or all installed modules.
    
    .DESCRIPTION
    Long description
    
    .PARAMETER ParameterName
    Parameter description
    
    .PARAMETER ParameterName
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    param (
        # Switch parameter to update modules
        [Parameter(AttributeValues)]
        [ParameterType]
        $ParameterName,

        # Force update modules
        [Parameter(AttributeValues)]
        [ParameterType]
        $ParameterName
    )
}

$Modules = Get-Module -Name $Name -ListAvailable | Where-Object -FilterScript {
    $_.RepositorySourceLocation -ne $null
} | Group-Object -Property Name

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