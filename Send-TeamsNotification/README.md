# Send-TeamsNotification #
A simple function to send a notification message to a Microsoft Teams channel using the channels connector "Incoming Webhook".

`Send-TeamsNotification -Uri $Uri -Text 'Example notification message' -Title 'IMPORTANT!' -ThemeColor 'FF8000' -ButtonType ViewAction -ButtonName 'Click Here' -ButtonTarget 'https://contoso.com' -Verbose`
![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Advanced_Notification_PS.png)

The result after running the cmdlet above:
![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Advanced_Notification.png)




## Enable a Incomming Webhook ##

- Right click on a channel and choose 'Connectors'
 ![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Connector.png)

- Search for 'Webhook' and click 'Add'
 ![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Webhook.png)

- Enter a name for the Webhook.
 ![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Notification.png)

- Copy the genereted HTTP URL and save it, for example to a variable.
 ![](https://raw.githubusercontent.com/PhilipHaglund/PowerShell/master/Send-TeamsNotification/pics/Copy.png)
