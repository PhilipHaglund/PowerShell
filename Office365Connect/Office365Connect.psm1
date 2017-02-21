#region Connect-Office365
#region AzureAD Credentials

function Test-AzureADCredential
{
    [cmdletbinding()]
    param ()
    $script:invokecredential = 
    {
        $script:PHAzureADcredential = Get-Credential -Message 'UserPrincipalName in Azure AD to access Office 365.'
    }

    if ($Script:PHAzureADcredential.UserName -notmatch "[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
    {
        try
        {
            & $script:invokecredential
            return $true
        }
        catch
        {
            return $false
        }
    }
    else
    {
        return $true
    }
}
function Remove-AzureADCredential
{
    [cmdletbinding()]
    param ()
    Remove-Variable -Name invokecredential -Scope Script -ErrorAction SilentlyContinue
    Remove-Variable -Name PHAzureADcredential -Scope Script -ErrorAction SilentlyContinue           
}
#endregion Credentials
#region Microsoft Online
function Connect-MsolServiceOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return
    }

    $module = Get-Module -Name MSOnline -ListAvailable
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
            Write-Warning -Message "Unable to Import-Module 'MSOnline' - $($_.Exception.Message)"
            return
        }

        try
        {
            Connect-MsolService -Credential $script:o365usercredential -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to connect to MSOnline - $($_.Exception.Message)"
            return
        }
    }
}
#endregion Microsoft Online
#region AzureAD
function Connect-AzureADOnline
{
    [cmdletbinding()]
    param ()
    if ((Test-O365Credential) -eq $false)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return
    }

    $module = Get-Module -Name AzureAD -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'AzureAD' to Connect to AzureAD"
        Write-Verbose -Message 'Download from: https://www.powershellgallery.com/packages/AzureAD/ or Install-Module -Name AzureAD' -Verbose
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
            Write-Warning -Message "Unable to Import-Module 'AzureAD' - $($_.Exception.Message)"
            return
        }

        try
        {
            Connect-AzureAD -Credential $script:PHAzureADcredential -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to connect to AzureAD - $($_.Exception.Message)"
            return
        }
    }
}
#endregion AzureAD
#region Compliance Center Online 
function Connect-CCOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect to Compliance Center, please provide the correct credentials.'
        return
    }

    if ($null -ne (Get-CCOnlineSession))
    {
        Write-Verbose -Message 'CCO PowerShell session already existis.'
        return
    }
    try
    {
        $null = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://ps.compliance.protection.outlook.com/powershell-liveid/' -Credential $script:PHAzureADcredential -Authentication Basic -AllowRedirection -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message "Unable to create PSSession to Compliance Center - $($_.Exception.Message)"
        return
    }
    try
    {
        $null = Import-PSSession -Session (Get-CCOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message "Unable to load PSSession for Compliance Center - $($_.Exception.Message)"
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
        Write-Warning -Message "Unable to get active Compliance Center online PSSession - $($_.Exception.Message)"
    }
    if ($null -eq $session)
    {
        return $null
    }
    else
    {
        return $true
    }
}
function Disconnect-CCOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq (Get-CCOnlineSession))
    {
        Write-Verbose -Message 'The Compliance Center online PSSession does not exist.' -Verbose
    }
    else 
    {
        try
        {
            Remove-PSSession -Session (Get-CCOnlineSession) -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message "Unable to remove PSSession for Compliance Center - $($_.Exception.Message)"
            return
        }

        Write-Verbose -Message 'The Compliance Center online session is now closed.' -Verbose
    }    
}
#endregion Compliance Center Online
#region Exchange Online
function Connect-ExchangeOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return
    }
    if ($null -ne (Get-ExchangeOnlineSession))
    {
        Write-Verbose -Message 'Exchange Online PowerShell session already existis.'
        return
    }
    try
    {
        $null = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri 'https://outlook.office365.com/powershell-liveid/' -Credential $script:PHAzureADcredential -Authentication Basic -AllowRedirection -WarningAction SilentlyContinue -ErrorAction Stop
    }
    catch
    {
        Write-Warning -Message "Unable to create PSSession to Exchange Online - $($_.Exception.Message)"
        return
    }
    try
    {
        $null = Import-PSSession -Session (Get-ExchangeOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue
    }
    catch
    {
        Write-Warning -Message "Unable to load PSSession for Exchange Online - $($_.Exception.Message)"
        return
    }    
}
function Disconnect-ExchangeOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq (Get-ExchangeOnlineSession))
    {
        Write-Verbose -Message 'The Exchange Online PSSession does not exist.' -Verbose
    }
    else 
    {
        try
        {
            Remove-PSSession -Session (Get-ExchangeOnlineSession) -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message "Unable to remove PSSession for Exchange Online - $($_.Exception.Message)"
            return
        }
        
        Write-Verbose -Message 'The Exchange Online PSSession is now closed.' -Verbose
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
        Write-Warning -Message "Unable to get active Compliance Center online PSSession - $($_.Exception.Message)"
    }
    if ($null -eq $session)
    {
        return $null
    }
    else
    {
        return $true
    }
}
#endregion Exchange Online
#region SharePoint Online
function Connect-SPOnline
{
    [cmdletbinding()]
    param (
        [Parameter(
            Mandatory = $true
        )]
        [Alias('Domain','DomainHost','Customer')]
        [string]$SharepointDomain
    )

    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return
    }

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
            Write-Warning -Message "Unable to Import-Module 'Microsoft.Online.SharePoint.PowerShell' - $($_.Exception.Message)"
            return
        }

        try
        {
            Connect-SPOService -Url "https://$($SharepointDomain)-admin.sharepoint.com" -Credential $script:PHAzureADcredential -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to Connect to Sharepoint Online - $($_.Exception.Message)"
            return
        }
    }
}
function Get-SPOnlineSession
{
    [cmdletbinding()]
    param ()

    try
    {
        $spotenant = Get-SPOTenant -ErrorAction Stop
    }
    catch [Management.Automation.CommandNotFoundException]
    {
        Write-Warning -Message 'The cmdlet Get-SPOTenant is unavailable. Is the module "Microsoft.Online.SharePoint.PowerShell" available?'
        return
    }
    if ($null -eq $spotenant)
    {        
        return $null
    }
    else
    {
        return $true
    }
}
function Disconnect-SPOnline
{
    [cmdletbinding()]
    param ()

    if ($null -eq (Get-SPOnlineSession))
    {
        Write-Verbose -Message 'No Sharepoint Online PSSession is active' -Verbose
        return
    }
    else 
    {
        try
        {
            Disconnect-SPOService -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message "Unable to disconnect Sharepoint Online PSSession - $($_.Exception.Message)"
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
    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return
    }

    $module = Get-Module -Name 'LyncOnlineConnector' -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'LyncOnlineConnector'"
        Write-Verbose -Message 'Download from: https://www.microsoft.com/en-us/download/details.aspx?id=39366' -Verbose
        return
    }
    else
    {
        if ($null -ne (Get-SfBOnlineSession))
        {
            Write-Verbose -Message 'Skype for Business Online PowerShell session already existis.'
            return
        }
        try
        {
            Import-Module -Name 'LyncOnlineConnector' -DisableNameChecking -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to Import-Module 'LyncOnlineConnector' - $($_.Exception.Message)"
            return
        }

        try
        {
            $null = New-CsOnlineSession -Credential $script:PHAzureADcredential -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to create PSSession for Skype for Business Online - $($_.Exception.Message)"
            return
        }
        try
        {
            $null = Import-PSSession -Session (Get-SfBOnlineSession) -DisableNameChecking -AllowClobber -ErrorAction Stop -WarningAction SilentlyContinue
        }
        catch
        {
            Write-Warning -Message "Unable to load PSSession for Skype for Business Online - $($_.Exception.Message)"
            return
        }
    }
}

function Connect-SfBOnlineSession
{
    [cmdletbinding()]
    param ()
    if ($null -eq $Script:PHAzureADcredential)
    {
        Write-Warning -Message 'Need credentials to connect, please provide the correct credentials.'
        return $null
    }

    $module = Get-Module -Name 'LyncOnlineConnector' -ListAvailable
    if ($null -eq $module)
    {
        Write-Warning -Message "Requires the module 'LyncOnlineConnector'"
        Write-Verbose -Message 'Download from: https://www.microsoft.com/en-us/download/details.aspx?id=39366' -Verbose
        return $null
    }


}

function Disconnect-SfBOnline
{
    [cmdletbinding()]
    param ()
    if ($null -eq (Get-SfBOnlineSession))
    {
        Write-Verbose -Message 'The Skype for Business Online PSSession does not exist.' -Verbose
    }
    else 
    {
        try
        {
            Remove-PSSession -Session (Get-SfBOnlineSession) -ErrorAction Stop
        }
        catch
        {
            Write-Warning -Message "Unable to remove PSSession for Skype for Business Online - $($_.Exception.Message)"
            return
        }        
        
        Write-Verbose -Message 'The Skype for Business Online PSSession is now closed.' -Verbose
    }    
}
#endregion Skype for Business Online
#region Office 365 Sessions
function Connect-PHOffice365
{
    [cmdletbinding()]
    param ()
    Connect-MsolOnline
    Connect-CCO
    Connect-ExchangeOnline
    Connect-SPO
    Connect-SfBO     
}
function Disconnect-PHOffice365 
{
    [cmdletbinding()]
    param ()
    Disconnect-CCO
    Disconnect-ExchangeOnline
    Disconnect-SPO
    Disconnect-SfBO

    Remove-O365Credential
}
#endregion Office 365 Sessions
#endregion Connect-Office365