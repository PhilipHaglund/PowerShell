function Compare-ADUserGroup
{
    <#
        .SYNOPSIS
        Compare ADGroups between two Active Directory Users.

        .DESCRIPTION
        A longer description for the function...

        .EXAMPLE
        Compare-ADUserGroup -ReferenceUser User1 -DifferenceUser User2
        
        Group                        Missing from User GroupSID                                      WholeObject                                                                     
        -----                        ----------------- --------                                      -----------                                                                     
        res-group1                   User2             S-1-5-21-1281181470-3279712345-539654562-1118 CN=res-group1,OU=Resources,OU=IT-Administration,DC=contoso,DC=com 
        res-group2                   User1             S-1-5-21-1281181470-3279712345-539654562-1114 CN=res-group2,OU=Resources,OU=IT-Administration,DC=contoso,DC=com
        res-group3                   User1             S-1-5-21-1281181470-3279712345-539654562-1162 CN=res-group3,OU=Resources,OU=IT-Administration,DC=contoso,DC=com  
        res-group4                   User1             S-1-5-21-1281181470-3279712345-539654562-2103 CN=res-group4,OU=Resources,OU=IT-Administration,DC=contoso,DC=com
        res-group5                   User1             S-1-5-21-1281181470-3279712345-539654562-2109 CN=res-group5,OU=Resources,OU=IT-Administration,DC=contoso,DC=com      
        res-group6                   User1             S-1-5-21-1281181470-3279712345-539654562-5606 CN=res-group6,OU=Resources,OU=IT-Administration,DC=contoso,DC=com           
        res-group7                   User1             S-1-5-21-1281181470-3279712345-539654562-5104 CN=res-group7,OU=Resources,OU=IT-Administration,DC=contoso,DC=com     

        .INPUTS
        System.String

        .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
    [Alias('cag')]
    param (
        # A reference ADUser.
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter a reference ADUser.'
        )]
        [Alias('R')]
        [string]$ReferenceUser,

        # A difference ADUser.
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter a difference ADUser.'
        )]
        [Alias('D')]
        [string]$DifferenceUser
    )

    try
    {
        $Ref = Get-ADPrincipalGroupMembership -Identity $ReferenceUser -ErrorAction Stop
    }
    catch
    {
        Write-Warning -Message ('No reference ADUser found with UserName {0} - {1}' -f $ReferenceUser, $_.Exception.Message)
        # If no diffrence user was found an warning will be presented to the user and break the function.
        break
    }

    try
    {
        $Dif = Get-ADPrincipalGroupMembership -Identity $DifferenceUser -ErrorAction Stop
    }
    catch
    {
        Write-Warning -Message ('No difference ADUser found with UserName {0} - {1}' -f $ReferenceUser, $_.Exception.Message)
        # If no diffrence user was found an warning will be presented to the user and break the function.
        break
    }

    $Compare = Compare-Object -ReferenceObject $ref -DifferenceObject $dif -Property Name -PassThru

    foreach ($c in $Compare)
    {
        if ($c.SideIndicator -eq '<=')
        {
            $User = $DifferenceUser
        }
        elseif ($c.SideIndicator -eq '=>')
        {
            $User = $ReferenceUser
        }
        else
        {
            $User = 'Unknown User'
        }
        [pscustomobject]@{
            Group               = $c.Name
            'Missing from User' = $User
            GroupSID            = $c.SID
            Object              = $c
        }
    }
}