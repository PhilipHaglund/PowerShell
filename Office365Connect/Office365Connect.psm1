#region AzureAD Credentials
$Script:AzureADCredentials = $false
function Get-AzureADCredential
{
    [cmdletbinding()]
    param ()
        
    try
    {
        if ($Script:AzureADCredentials -eq $false)
        {           
            $counter = 0
            do
            {
                $Script:AzureADCredentials = Get-Credential -Message 'UserPrincipalName in Azure AD to access Office 365.'                
                if ($counter -gt 0 -and $counter -lt 3)
                {
                    Write-Verbose -Message 'Credentials does not match a valid UserPrincipalName in AzureAD, please provide a corrent UserPrincipalName.' -Verbose
                }
                elseif ($counter -gt 2)
                {
                    Write-Error -Message 'Credentials does not match a UserPrincipalName in AzureAD' -Exception 'System.Management.Automation.SetValueException' -Category InvalidResult -ErrorAction Stop
                    break
                }
                $counter++
            }
            while ($Script:AzureADCredentials.UserName -notmatch "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")            
        }
    }
    catch
    {
        return
    }

    return
}
#endregion Credentials
#region Microsoft Online
function Connect-MsolServiceOnline
{
    [cmdletbinding()]
    param ()

    $module = Get-Module -Name 'MSOnline' -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'MSOnline' to Connect to MsolService"
        Write-Verbose -Message 'Download from: http://go.microsoft.com/fwlink/?linkid=236297' -Verbose
        return
    }
    else
    {
        try
        {
            Import-Module -Name 'MSOnline' -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to Import-Module "MSOnline" - {0}' -f $_.Exception.Message)
            return
        }

        try
        {            
            Connect-MsolService -Credential $Script:AzureADCredentials -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to connect to MSOnline - {0}' -f $_.Exception.Message)
            return
        }
    }
}
function Disconnect-MsolServiceOnline
{
    [cmdletbinding()]
    param ()
    try
    {
        if (Get-Module -Name 'MSOnline')
        {
            Remove-Module -Name 'MSOnline' -ErrorAction Stop -WarningAction SilentlyContinue
            Write-Verbose -Message 'MsolService Module is now closed.' -Verbose
        }
    }
    catch
    {
        Write-Warning -Message ('Unable to remove MsolService Module - {0}' -f $_.Exception.Message)
        return
    }    
}
#endregion Microsoft Online
#region AzureAD
function Connect-AzureADOnline
{
    [cmdletbinding()]
    param ()

    $module = Get-Module -Name AzureAD -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'AzureAD' to Connect to AzureAD"
        Write-Verbose -Message 'Download from: https://www.powershellgallery.com/packages/AzureAD/ or cmdlet "Install-Module -Name AzureAD"' -Verbose
        return
    }
    else
    {
        try
        {
            Import-Module -Name 'AzureAD' -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to Import-Module "AzureAD" - {0}' -f $_.Exception.Message)
            return
        }

        try
        {            
            $null = Connect-AzureAD -Credential $Script:AzureADCredentials -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to connect to AzureAD - {0}' -f $_.Exception.Message)
            return
        }
    }
}
function Disconnect-AzureADOnline
{
    [cmdletbinding()]
    param ()
    try
    {        
        Disconnect-AzureAD -ErrorAction Stop
        Remove-Module -Name AzureAD -Force -ErrorAction Stop
        Write-Verbose -Message 'Azure AD Session is now closed.' -Verbose
    }
    catch
    {
        Write-Warning -Message ('Unable to remove AzureAD Session - {0}' -f $_.Exception.Message)
        return
    }    
}
#endregion AzureAD
#region Compliance Center Online
function Connect-CCOnline
{
    [cmdletbinding()]
    param ()

    if ($null -ne (Get-CCOnlineSession))
    {
        if (Get-Command -Name 'Get-ComplianceSearch')
        {
            Write-Verbose -Message 'Compliance Center PowerShell session already existis.' -Verbose
            return
        }
    }
    try
    {
        $null = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://ps.compliance.protection.outlook.com/powershell-liveid/' -Credential $Script:AzureADCredentials -Authentication Basic -AllowRedirection -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message ('Unable to create PSSession to Compliance Center - {0}' -f $_.Exception.Message)
        return
    }
    try
    {        
        $null = Import-Module (Import-PSSession -Session (Get-CCOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue) -DisableNameChecking -Global -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message ('Unable to load PSSession for Compliance Center - {0}' -f $_.Exception.Message)
        return
    }
}
function Disconnect-CCOnline
{
    [cmdletbinding()]
    param ()

    try
    {
        if ($null -ne ($ccsession = Get-CCOnlineSession))
        {
            Remove-PSSession -Session ($ccsession) -ErrorAction Stop
            Write-Verbose -Message 'The Compliance Center Online PSSession is now closed.' -Verbose
        }        
    }
    catch
    {
        Write-Warning -Message ('Unable to remove PSSession for Compliance Center - {0}' -f $_.Exception.Message)
        return
    }          
}
function Get-CCOnlineSession
{
    [cmdletbinding()]
    param ()

    try
    {
        $session = Get-PSSession -ErrorAction Stop | Where-Object -FilterScript {$_.ComputerName -match 'Compliance' -and $_.ConfigurationName -eq 'Microsoft.Exchange'}
    }
    catch
    {
        Write-Warning -Message ('Unable to get active Compliance Center Online PSSession - {0}' -f $_.Exception.Message)
        return $null
    }
    
    return $session
}
#endregion Compliance Center Online
#region Exchange Online
function Connect-ExchangeOnline
{
    [cmdletbinding()]
    param ()

    if ($null -ne (Get-ExchangeOnlineSession))
    {        
        if (Get-Command -Name 'Get-Mailbox')
        {
            Write-Verbose -Message 'Exchange Online PowerShell session already existis.' -Verbose
            return
        }
    }
    try
    {
        $null = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $Script:AzureADCredentials -Authentication Basic -AllowRedirection -WarningAction SilentlyContinue -ErrorAction Stop
    }
    catch
    {
        Write-Warning -Message ('Unable to create PSSession to Exchange Online - {0}' -f $_.Exception.Message)
        return
    }
    try
    {
        $null = Import-Module (Import-PSSession -Session (Get-ExchangeOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue) -DisableNameChecking -Global -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message ('Unable to load PSSession for Exchange Online - {0}' -f $_.Exception.Message)
        return
    }
}
function Disconnect-ExchangeOnline
{
    [cmdletbinding()]
    param ()

    try
    {
        if ($null -ne ($exonline = Get-ExchangeOnlineSession))
        {
            Remove-PSSession -Session ($exonline) -ErrorAction Stop
            Write-Verbose -Message 'The Exchange Online PSSession is now closed.' -Verbose
        }
    }
    catch
    {
        Write-Warning -Message ('Unable to remove PSSession for Exchange Online - {0}' -f $_.Exception.Message)
        return
    }       
}
function Get-ExchangeOnlineSession
{
    [cmdletbinding()]
    param ()

    try
    {
        $session = Get-PSSession -ErrorAction Stop | Where-Object -FilterScript {$_.ComputerName -match 'outlook.office365.com' -and $_.ConfigurationName -eq 'Microsoft.Exchange'}
    }
    catch
    {
        Write-Warning -Message ('Unable to get active Exchange Online PSSession - {0}' -f $_.Exception.Message)
        return $null
    }

    return $session
}
#endregion Exchange Online
#region SharePoint Online
function Connect-SPOnline
{
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory = $true,
            HelpMessage = 'Enter a valid Sharepoint Online Domain. Example: "Contoso"'
        )]
        [Alias('Domain','DomainHost','Customer')]
        [string]$SharepointDomain
    )

    $module = Get-Module -Name 'Microsoft.Online.SharePoint.PowerShell' -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'Microsoft.Online.SharePoint.PowerShell' for connection to Sharepoint Online"
        Write-Verbose -Message 'Download from: https://www.microsoft.com/en-us/download/details.aspx?id=35588' -Verbose
        return
    }
    else
    {
        try
        {
            Import-Module -Name 'Microsoft.Online.SharePoint.PowerShell' -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to Import-Module "Microsoft.Online.SharePoint.PowerShell" - {0}' -f $_.Exception.Message)
            return
        }

        try
        {            
            Connect-SPOService -Url ('https://{0}-admin.sharepoint.com' -f ($SharepointDomain)) -Credential $Script:AzureADCredentials -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to Connect to Sharepoint Online Session - {0}' -f $_.Exception.Message)
            return
        }
    }
}
function Disconnect-SPOnline
{
    [cmdletbinding()]
    param ()

    try
    {
        $null = Disconnect-SPOService -ErrorAction Stop
        Remove-Module -Name 'Microsoft.Online.SharePoint.PowerShell' -Force -ErrorAction Stop
        Write-Verbose -Message 'The Sharepoint Online Session is now closed.' -Verbose
    }
    catch
    {
        if ($_.Exception.Message -notmatch 'There is no service currently connected')
        {
            Write-Warning -Message ('Unable to disconnect Sharepoint Online Session - {0}' -f $_.Exception.Message)
            return
        }
    }
}
#endregion SharePoint Online
#region Skype for Business Online
function Connect-SfBOnline
{
    [cmdletbinding()]
    param ()

    $module = Get-Module -Name 'SkypeOnlineConnector' -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'SkypeOnlineConnector'"
        Write-Verbose -Message 'Download from: https://www.microsoft.com/en-us/download/details.aspx?id=39366' -Verbose
        return
    }
    else
    {
        if ($null -ne (Get-SfBOnlineSession))
        {
            Write-Verbose -Message 'Skype for Business Online PowerShell PSSession already existis.'
            return
        }
        try
        {
            Import-Module -Name 'SkypeOnlineConnector' -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to Import-Module "LyncOnlineConnector" - {0}' -f $_.Exception.Message)
            return
        }

        try
        {
            $null = New-CsOnlineSession -Credential $Script:AzureADCredentials -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to create PSSession for Skype for Business Online - {0}' -f $_.Exception.Message)
            return
        }
        try
        {            
            $null = Import-PSSession -Session (Get-SfBOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message ('Unable to load PSSession for Skype for Business Online - {0}' -f $_.Exception.Message)
            return
        }
    }
}
function Disconnect-SfBOnline
{
    [cmdletbinding()]
    param ()

    try
    {
        if ($null -ne ($sbfosession = Get-SfBOnlineSession))
        {
            Remove-PSSession -Session ($sbfosession) -ErrorAction Stop
            Remove-Module -Name 'SkypeOnlineConnector' -Force -ErrorAction Stop
            Write-Verbose -Message 'The Skype for Business Online PSSession is now closed.' -Verbose
        }
    }
    catch
    {
        Write-Warning -Message ('Unable to remove PSSession for Skype for Business Online - {0}' -f $_.Exception.Message)
        return
    }
}
function Get-SfBOnlineSession
{
    [cmdletbinding()]
    param ()

    try
    {
        $session = Get-PSSession -ErrorAction Stop | Where-Object -FilterScript {$_.ComputerName -match 'online.lync.com' -and $_.ConfigurationName -eq 'Microsoft.PowerShell'}
    }
    catch
    {
        Write-Warning -Message ('Unable to get active Exchange Online PSSession - {0}' -f $_.Exception.Message)
        return $null
    }

    return $session
}
#endregion Skype for Business Online
#region Office 365 Sessions
function Connect-PHOffice365
{
    <#
        .SYNOPSIS
        Connect to one or more Office 365 services using Powershell.
        
        .DESCRIPTION
        Connect to one or more Office 365 (AzureAD) services using Powershell. Some services requires the installation of separate PowerShell modules or binaries.
        AzureAD requires a separate module - https://www.powershellgallery.com/packages/AzureAD/ or cmdlet "Install-Module -Name AzureAD"
        MsolService requires a separate module - http://go.microsoft.com/fwlink/?linkid=236297
        Sharepoint Online requires a separate module - https://www.microsoft.com/en-us/download/details.aspx?id=35588
        Skype for Business Online requires a separate module - https://www.microsoft.com/en-us/download/details.aspx?id=39366

        DYNAMIC PARAMETERS
        -SharepointDomain <String>
            Parameter available when the Service parameter contains AllService or SharepointOnline.
            The SharepointDomain parameter is necessary when connecting to Sharepoint Online sessions ('https://{0}-admin.sharepoint.com' -f $SharepointDomain).
            Example for SharepointDomain can be 'Contoso'.

        .EXAMPLE
        Connect-PHOffice365
        

        VERBOSE: Conncting to AzureAD.
        VERBOSE: Conncting to MSolService.

        This command connects to AzureAD and MsolService service sessions using the credentials provided when prompted.
        AzureAD and MsolService are the default parameter values for the parameter Services.

        .EXAMPLE
        Connect-PHOffice365 -Service ComplianceCenter, ExchangeOnline, AzureAD


        VERBOSE: Conncting to AzureAD.
        VERBOSE: Conncting to Compliance Center.
        VERBOSE: Conncting to Exchange Online.

        This command connects to AzureAD, ComplianceCenter and ExchageOnline service sessions using the credentials provided when prompted.

        .EXAMPLE
        Connect-PHOffice365 -Service AzureAD, SharepointOnline


        cmdlet Connect-PHOffice365 at command pipeline position 1
        Supply values for the following parameters:
        (Type !? for Help.)
        SharepointDomain: Contoso

        VERBOSE: Conncting to AzureAD.
        VERBOSE: Conncting to Sharepoint Online.

        This command connect to AzureAD and SharepointOnline.
        SharepointOnline session requires a specified URI when connecting. In this example, Contoso, is provided at the mandatory prompt parameter, SharepointDomain.

        .EXAMPLE
        Connect-PHOffice365 -Service AllServices -SharepointDomain Contoso


        VERBOSE: Connecting to all Office 365 Services.

        This command connects to all Office 365 service sessions using the credentials provided when prompted.
        The parameter SharepointDomain is explicit provided to avoid the mandatory parameter prompt.


        .NOTES
        Created on:     2017-02-23 14:56
        Created by:     Philip Haglund
        Organization:   Gonjer.com        
        Version:        1.0.1.0
        Requirements:   Powershell 3.0

        .LINK
        https://github.com/PhilipHaglund/PowerShell/tree/master/Office365Connect
        https://www.gonjer.com
    #>
    [cmdletbinding(
        SupportsShouldProcess = $true
    )]    
    param (
        # Provide one or more Office 365 services to connect to.
        # Valid values are:
        # 'AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'MSOnline', 'SharepointOnline' ,'SkypeforBusinessOnline'
        [Parameter(
            ValueFromPipeline = $true,
            Position = 0
        )]
        [ValidateSet('AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'MSOnline', 'SharepointOnline' ,'SkypeforBusinessOnline')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = @('AzureAD','MSOnline')
    )

    DynamicParam
    {
        if ($Service -match 'AllServices|SharepointOnline')
        {      
            # Create a ParameterAttribute Object
            $domainattrib = New-Object -TypeName System.Management.Automation.ParameterAttribute
            $domainattrib.Position = 1
            $domainattrib.Mandatory = $true            
            $domainattrib.HelpMessage = 'Enter a valid Sharepoint Online Domain. Example: "Contoso"'
            
            # Create an AliasAttribute Object for the parameter
            $domainalias = New-Object -TypeName System.Management.Automation.AliasAttribute -ArgumentList @('Domain','DomainHost','Customer')

            # Create an AttributeCollection Object
            $attribcol = New-Object -TypeName System.Collections.ObjectModel.Collection[System.Attribute]
                       
            # Add the attributes to the AttributeCollection
            $attribcol.Add($domainattrib)
            $attribcol.Add($domainalias)
            
            # Add the SharepointDomain paramater to the "Runtime"
            $domainparam = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameter -ArgumentList ('SharepointDomain', [string], $attribcol)
            
            # Expose the paramete
            $paramDictionary = New-Object -TypeName System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add('SharepointDomain', $domainparam)
            return $paramDictionary
        }
    }
    begin
    {
        if (($service = $Service | Sort-Object -Unique).Count -gt 5 -or $Service -eq 'All')
        {
            $Service = 'AllServices'
        }        
    }
    process
    {
        foreach ($s in $Service)
        {
            if ($PSCmdlet.ShouldProcess('Establishing a PowerShell session to {0} - Office 365.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name))
            {
                $null = Get-AzureADCredential

                if ($Script:AzureADCredentials -eq $false)
                {
                        Write-Warning -Message 'Need valid credentials to connect, please provide the correct credentials.'
                        break
                }

                switch ($s)
                {
                    'AzureAD'
                    {
                        Write-Verbose -Message 'Conncting to AzureAD.' -Verbose
                        Connect-AzureADOnline
                    }
                    'MSOnline'
                    {
                        Write-Verbose -Message 'Conncting to MSolService.' -Verbose
                        Connect-MsolServiceOnline
                    }
                    'ComplianceCenter'
                    {
                        Write-Verbose -Message 'Conncting to Compliance Center.' -Verbose
                        Connect-CCOnline
                    }
                    'ExchangeOnline'
                    {
                        Write-Verbose -Message 'Conncting to Exchange Online.' -Verbose
                        Connect-ExchangeOnline
                    }
                    'SharepointOnline'
                    {
                        Write-Verbose -Message 'Conncting to Sharepoint Online.' -Verbose
                        Connect-SPOnline -SharepointDomain $PSBoundParameters['SharepointDomain']
                    }
                    'SkypeforBusinessOnline'
                    {
                        Write-Verbose -Message 'Conncting to Skype for Business Online.' -Verbose
                        Connect-SfBOnline
                    }
                    Default
                    {
                        Write-Verbose -Message 'Connecting to all Office 365 Services.' -Verbose
                        Connect-AzureADOnline
                        Connect-MsolServiceOnline
                        Connect-CCOnline
                        Connect-ExchangeOnline
                        Connect-SPOnline -SharepointDomain $PSBoundParameters['SharepointDomain']
                        Connect-SfBOnline
                    }
                }
            }
        }
    }
    end
    {
        Set-Variable -Name AzureADCredentials -Scope Script -Value $false -ErrorAction SilentlyContinue
    }
}
function Disconnect-PHOffice365 
{
    <#
        .SYNOPSIS
        Disconnect from one or more Office 365 services using Powershell.
        
        .DESCRIPTION
        Disconnect from one or more Office 365 (AzureAD) services using Powershell. Some services requires the installation of separate PowerShell modules or binaires.
        AzureAD requires a separate module - https://www.powershellgallery.com/packages/AzureAD/ or cmdlet "Install-Module -Name AzureAD"
        MsolService requraes a seprate module - http://go.microsoft.com/fwlink/?linkid=236297
        Sharepoint Online requires a separate module - https://www.microsoft.com/en-us/download/details.aspx?id=35588
        Skype for Business Online requires a separate module - https://www.microsoft.com/en-us/download/details.aspx?id=39366

        .EXAMPLE
        Disconnect-PHOffice365
        

        VERBOSE: Disconnecting from all Office 365 Services.
        VERBOSE: Azure AD Session is now closed.
        VERBOSE: MsolService Module is now closed.
        VERBOSE: The Compliance Center Online PSSession is now closed.
        VERBOSE: The Exchange Online PSSession is now closed.
        VERBOSE: The Sharepoint Online Session is now closed.
        VERBOSE: The Skype for Business Online PSSession is now closed.

        This command disconnects from all Office 365 service sessions that are available and running.

        .EXAMPLE
        Disconnect-PHOffice365 -Service ComplianceCenter, ExchangeOnline, AzureAD


        VERBOSE: Disconnecting from AzureAD.
        VERBOSE: Disconnecting from Compliance Center.
        VERBOSE: Disconnecting from Exchange Online.

        This command disconnects from AzureAD, Compliance and Exchange Online service sessions that are available and running.

        .NOTES
        Created on:     2017-02-23 14:56
        Created by:     Philip Haglund
        Organization:   Gonjer.com        
        Version:        1.0.1.0
        Requirements:   Powershell 3.0       

        .LINK
        https://github.com/PhilipHaglund/PowerShell/tree/master/Office365Connect
        https://www.gonjer.com
    #>
    [cmdletbinding(
        SupportsShouldProcess = $true
    )]
    param (
        # Provide one or more Office 365 services to disconnect from.
        # Valid values are:
        # 'AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'MSOnline', 'SharepointOnline', 'SkypeforBusinessOnline'
        [Parameter(
            ValueFromPipeline = $true            
        )]
        [ValidateSet('AllServices', 'AzureAD', 'ComplianceCenter', 'ExchangeOnline', 'MSOnline', 'SharepointOnline' ,'SkypeforBusinessOnline')]
        [ValidateNotNullOrEmpty()]
        [string[]]$Service = @('AllServices')
    )
    begin
    {
        if (($service = $Service | Sort-Object -Unique).Count -gt 5)
        {
            $Service = 'AllServices'
        }
    }
    process
    {
        foreach ($s in $Service)
        {
            if ($PSCmdlet.ShouldProcess('End the PowerShell session for {0} - Office 365.' -f ('{0}' -f $s), $MyInvocation.MyCommand.Name))
            {
                switch ($s)
                {
                    'AzureAD'
                    {
                        Write-Verbose -Message 'Disconnecting from AzureAD.' -Verbose
                        Disconnect-AzureADOnline
                    }
                    'MSOnline'
                    {
                        Write-Verbose -Message 'Disconnecting from MsolService.' -Verbose
                        Disconnect-MsolServiceOnline
                    }
                    'ComplianceCenter'
                    {
                        Write-Verbose -Message 'Disconnecting from Compliance Center.' -Verbose
                        Disconnect-CCOnline
                    }
                    'ExchangeOnline'
                    {
                        Write-Verbose -Message 'Disconnecting from Exchange Online.' -Verbose
                        Disconnect-ExchangeOnline
                    }
                    'SharepointOnline'
                    {
                        Write-Verbose -Message 'Disconnecting from Sharepoint Online.' -Verbose
                        Disconnect-SPOnline
                    }
                    'SkypeforBusinessOnline'
                    {
                        Write-Verbose -Message 'Disconnecting from Skype for Business Online.' -Verbose
                        Disconnect-SfBOnline
                    }
                    Default
                    {
                        Write-Verbose -Message 'Disconnecting from all Office 365 Services.' -Verbose
                        Disconnect-AzureADOnline
                        Disconnect-MsolServiceOnline
                        Disconnect-CCOnline
                        Disconnect-ExchangeOnline
                        Disconnect-SPOnline
                        Disconnect-SfBOnline
                    }
                }
                
            }
        }
    }
    end
    {
        # If the saved credentials variables for some reason is not removed we remove them again.
        Set-Variable -Name AzureADCredentials -Scope Script -Value $false -ErrorAction SilentlyContinue
    }
}
#endregion Office 365 Sessions