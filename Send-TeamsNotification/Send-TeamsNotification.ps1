function Send-TeamsNotification
{
    <# 
        .SYNOPSIS
        Send a notification message to a Microsoft Teams channel using Webhooks.
        
        .DESCRIPTION
        Send a notification message to a Microsoft Teams using Webhooks. Before one can send a Webhook to a channel the Webhooks connector needs to be enabled.
        Make sure that 'Sideloading of external bots & tabs' setting is enabled on your Office 365 tenant.
        
        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message'

        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message' -Title 'Notification' -ThemeColor 'E81123'

        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message' -Title 'Notification' -ThemeColor 'FF8000' -ButtonType ViewAction -ButtonName 'Click Here' -ButtonTarget 'https://contoso.com'

        .NOTES
        Created on:     2017-04-25 15:26
        Created by:     Philip Haglund
        Organization:   Gonjer.com
        Filename:       Send-TeamsNotification.ps1
        Requirements:   Powershell 3.0
        
        .INPUTS
        System.String
        System.Uri
        
        .LINK
        https://gonjer.com
    #>

    [CmdletBinding(
        SupportsShouldProcess = $true
    )]
    param (
        
        [Parameter(
            ParameterSetName = 'Text',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [uri]$Uri,

        [Parameter(
            ParameterSetName = 'Text',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [string]$Text,

        [Parameter(
            ParameterSetName = 'Text'
        )]
        [Parameter(
            ParameterSetName = 'Extended'
        )]
        [string]$Title = 'Title',

        [Parameter(
            ParameterSetName = 'Text'
        )]
        [Parameter(
            ParameterSetName = 'Extended'
        )]
        [string]$ThemeColor = 'E81123',

        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [ValidateSet('ViewAction')]
        [string]$ButtonType,

        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [string]$ButtonName,

        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [uri]$ButtonTarget,

        [Parameter(
            ValueFromPipeline = $true,
            ParameterSetName = 'Pipeline',
            Mandatory = $true
        )]
        [PSObject]$InputObject
    )

    begin
    {
        $Inr = @{
            Method      = 'Post'
            Uri         = $Uri
            ContentType = 'application/json'
            ErrorAction = 'Stop'
        }
    }
    process
    {
        foreach ($global:Param in $PSBoundParameters.GetEnumerator())
        {
            Write-Verbose -Message ('Parameter "{0}"; Value: "{1}"' -f $Param.Key,$Param.Value)
        }
        
        Write-Verbose -Message ('ParameterSetName: {0}' -f $PSCmdlet.ParameterSetName)

        if ($PSCmdlet.ShouldProcess($text,$MyInvocation.MyCommand.Name))
        {
            # Pipeline parameter set is not tested
            if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
            {
                $Hash = $InputObject
            }
            
            else
            {
                $Hash = [ordered]@{
                        Text = $Text
                }
                if ($PSBoundParameters.ContainsKey('Title'))
                {
                    $Hash.Add('Title',$PSBoundParameters['Title'])
                }
                if ($PSBoundParameters.ContainsKey('Title'))
                {
                    $Hash.Add('ThemeColor',$PSBoundParameters['ThemeColor'])
                }
                
                if ($PSCmdlet.ParameterSetName -eq 'Extended')
                {
                    $PotentialAction = [Object[]]@{}
                    $PotentialAction.Add('@context','https://schema.org')
                    $PotentialAction.Add('@type',$PSBoundParameters['ButtonType'])
                    $PotentialAction.Add('name',$PSBoundParameters['ButtonName'])
                    $PotentialAction.Add('target',[Object[]]$PSBoundParameters['target'])
                }
            }
                          
            try
            {
                $Json = ConvertTo-Json -InputObject $Hash -Compress -ErrorAction Stop
                Write-Verbose -Message $Json
            }
            catch
            {
                Write-Error -Message ('Unable to convert input to JSON - {0}' -f $_.Exception.Message)
                return
            }
            
            try
            {
                $StatusCode = Invoke-RestMethod @Inr -Body ([Text.Encoding]::UTF8.GetBytes($Json))
                Write-Verbose -Message ('Status message from Invoke-RestMethod: {0}' -f $StatusCode)
            }
            catch
            {
                Write-Error -Message ('Unable to convert input to JSON - {0}' -f $_.Exception.Message)
            }
        }
    }
    end
    {
        Write-Verbose -Message ('{0} in end block' -f $MyInvocation.MyCommand.Name)
    }
}