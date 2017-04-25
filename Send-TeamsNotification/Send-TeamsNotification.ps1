function Send-TeamsNotification
{
    <# 
        .SYNOPSIS
        Send a notification message to a Microsoft Teams channel using an incomming webhooks connection.
        
        .DESCRIPTION
        Send a notification message to a Microsoft Teams channel using an incomming webhooks connection. 
        Before one can send/post a webhook connection to a channel, the webhooks connector needs to be enabled for that channel. See the link below.
        Microsoft Teams Connectors: https://msdn.microsoft.com/en-us/microsoft-teams/connectors
        Make sure that 'Sideloading of external bots & tabs' setting is enabled on your Office 365 tenant if you want to be able and open links.
        
        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message'
        
        This cmdlet will post a simple notification message to the selected (uri) Microsoft Teams channel with the text provided in the parameter 'Text'.

        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message' -Title 'Notification' -ThemeColor 'E81123'

        This cmdlet will post an advanced notification message to the selected (uri) Microsoft Teams channel with the text provided in the parameter 'Text'.
        The notification message will have title or heading named 'Notification'
        The notification message will have a color banner with the HTML color E81123.

        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        Send-TeamsNotification -Uri $Uri -Text 'Example notification message' -Title 'IMPORTANT!' -ThemeColor 'FF8000' -ButtonType ViewAction -ButtonName 'Click Here' -ButtonTarget 'https://contoso.com'

        This cmdlet will post a more advanced notification message to the selected (uri) Microsoft Teams channel with the text provided in the parameter 'Text'.
        The notification message will have title or heading named 'IMPORTANT!'
        The notification message will have a color banner with the HTML color FF8000.
        The notification message will contain a button with a link target to 'https://contoso.com'.

        .EXAMPLE
        $Uri = 'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        $Object = [PscustomObject]@{Text = 'Example notification message'}
        $Object | Send-TeamsNotification -Uri $Uri

        This cmdlet will post a simple notification message to the selected (uri) Microsoft Teams channel with information provided from the pieline.
        

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
        <#
            An Uri for a incomming webhook at a Microsoft Teams channel.
            How to enable a webhook connector can be found in the following link: https://msdn.microsoft.com/en-us/microsoft-teams/connectors

            Example of a webhooks uri:
            'https://outlook.office.com/webhook/5adf112d-4426-45ad-bce5-7e27r3d4eac4@4580044a-27bc-41b9-b7f2-e0f0dd7cbb56/IncomingWebhook/527c1b2asd2b67ae991ac5118e07a8e6/433a0d7d-6508-49b3-b486-60bv687428a7'
        #>
        
        [Parameter(
            ParameterSetName = 'Text',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
         [Parameter(
            ParameterSetName = 'Pipeline',
            Mandatory = $true
        )]
        [uri]$Uri,

        
        # A text string that will represent the actual notification message.       
        [Parameter(
            ParameterSetName = 'Text',
            Mandatory = $true
        )]
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [string]$Text,

        # If the notification message should have Title/Header for it's message.
        [Parameter(
            ParameterSetName = 'Text'
        )]
        [Parameter(
            ParameterSetName = 'Extended'
        )]
        [string]$Title = 'Title',

        # If the notification message should have special color for it's message banner.
        [Parameter(
            ParameterSetName = 'Text'
        )]
        [Parameter(
            ParameterSetName = 'Extended'
        )]
        [string]$ThemeColor = 'E81123',

        <#
            If this parameter is used the ParameterSet will be 'Extended' and the following parameters is mandatory: ButtonName and ButtonTarget.
            ButtonType is a Schema.org type "Consume Action" that is used by the webhooks API to provide a valid button.

            A validateSet is used here to allow a future extend if another button is to be used.
            At this moment "ViewAction" is the only allowed option.
        #>
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [ValidateSet('ViewAction')]
        [string]$ButtonType,

        <#
            If this parameter is used the ParameterSet will be 'Extended' and the following parameters is mandatory: ButtonType and ButtonTarget.
            ButtonName is a string that is used in the webhooks API to provide a text inside the button.
        #>
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [string]$ButtonName,

        <#
            If this parameter is used the ParameterSet will be 'Extended' and the following parameters is mandatory: ButtonType and ButtonName.
            ButtonTarget is a uri or string that is used in the webhooks API to provide a clickable link button.
        #>
        [Parameter(
            ParameterSetName = 'Extended',
            Mandatory = $true
        )]
        [uri]$ButtonTarget,

        <#
            Inputobject will take a PSObject as input from the pipeline.
            This parameter is in beta and needs a validator to not allow faulty PSObjects.
        #>
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
            if ($PSCmdlet.ParameterSetName -eq 'Pipeline')
            {
                # Need to add a validator for InputObject.
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