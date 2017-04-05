## Changelog Office365Connect v1.0.1.1
1. Exchange Online and Compliance Center should now properly import cmdlets from PSSession. 

## Changelog Office365Connect v1.0.1.0
1. Rename LICENSE.txt to LICENSE.
2. Add `$Script:AzureADCredentials = $false` to avoid undefiend variables by PSharper.
3. Remove the script variable `$script:invokecredential`. Replaced by a if-set.
4. Remove `$false` and `$true` from `return` statement where it is not needed.
5. Replaced most string SubExpreesions for `-f` (format) operator.
6. `Disconnect-PHOffice365` now unloads the loaded modules (AzureAD, MSOnline, Sharepoint and Skype4B).
7. Slimed down `Disconnect-SPOnline` to only disconnect and remove module.
8. Add Help for the Dyanmic parameter SharepointDomain.
9. Add a missing foreach loop to both `Connect-PHOffice365` and `Disconnect-PHOffice365` when not using ValuefromPipeline.
10. Renamed parameter value `All` to `AllService` in `Connect-PHOffice365` and `Disconnect-PHOffice365`.
11. Add missing `-SharepointDomain $PSBoundParameters['SharepointDomain']` to `Connect-SPOnline` when using AllService parameter value.
12. Correct typos in Help.
13. Removed function `Remove-AzureADCredential`. Replaced by `Set-Variable`.

## Changelog Office365Connect v1.0.0.6
1. Remove Office365Connect.jpg, changelog.md and LICENSE.txt from the published module to Gallery.

## Changelog Office365Connect v1.0.0.5
1. Remove Office365Connect.jpg, changelog.md and LICENSE.txt from the published module to Gallery.
2. Correct typo in .psd1 manifest for Icon URI.
3. Change 'VariablestoExport' to `@()` instead of `*`. 
4. Add `-TypeName` and `-ArgumentList` parameters for `New-Object` cmdlet where it is missing. 

## Changelog Office365Connect v1.0.0.4
1. Add new version. Begins with 1. instead of 0.
2. Add License and Icon Uri to Module Manifest.
3. Rename RootModule name in Module Manifest.
4. Correct typos in the Example help sections for `Connect-PHOffice365` and `Disconnect-PHOffice365`.


## Changelog Office365Connect v0.0.0.3

1. Inital commit to GitHub.