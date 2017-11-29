$Theme              = 'Contoso'
$ThemePath          = "$env:SystemDrive\ADFS\Theme"
$DomainShortName    = "$ENV:USERDOMAIN"
$OrganizationDomain = 'contoso.com'

# For backup the default Theme
New-Item -Path $ThemePath\Backup -ItemType Directory
Export-AdfsWebTheme -Name Default -DirectoryPath $ThemePath\Backup

New-AdfsWebTheme -Name $Theme -SourceName Default

$enUS = @{
    HelpDeskLink                              = 'https://servicedesk.{0}/' -f $OrganizationDomain
    PrivacyLink                               = 'https://adfs.{0}/adfs/portal/updatepassword/' -f $OrganizationDomain
    HomeLink                                  = 'https://www.{0}/' -f $OrganizationDomain
    ErrorPageSupportEmail                     = 'servicedesk@{0}' -f $OrganizationDomain
    HelpDeskLinkText                          = 'Help'
    PrivacyLinkText                           = 'Change password'
    HomeLinkText                              = 'Home'
    ErrorPageDescriptionText                  = 'An error has occurred'
    ErrorPageGenericErrorMessage              = 'An error has occurred, contact Servicedesk for assistance.'
    ErrorPageAuthorizationErrorMessage        = 'You have received an Authorization error.  Contact Servicedesk for assistance.'
    ErrorPageDeviceAuthenticationErrorMessage = 'Your device is not authorized.  Contact Servicedesk for assistance.'
    UpdatePasswordPageDescriptionText         = 'To change your password provide your current password.'
}

$svSE = @{
    Locale                                    = 'sv-SE'
    HelpDeskLink                              = 'https://servicedesk.{0}/' -f $OrganizationDomain
    PrivacyLink                               = 'https://adfs.{0}/adfs/portal/updatepassword/' -f $OrganizationDomain
    HomeLink                                  = 'https://www.{0}/' -f $OrganizationDomain
    ErrorPageSupportEmail                     = 'servicedesk@{0}' -f $OrganizationDomain
    HelpDeskLinkText                          = 'Hjälp'
    PrivacyLinkText                           = 'Byt lösenord'
    HomeLinkText                              = 'Hem'
    ErrorPageDescriptionText                  = 'Ett fel har uppstått'
    ErrorPageGenericErrorMessage              = 'Ett fel har uppstått, kontakta Servicedesk för vidare hjälp.'
    ErrorPageAuthorizationErrorMessage        = 'Du har fått ett inloggningsfel. Kontakta Servicedesk för hjälp.'
    ErrorPageDeviceAuthenticationErrorMessage = 'Din enhet är inte auktoriserad. Kontakta Servicedesk för hjälp.'
    UpdatePasswordPageDescriptionText         = 'För att uppdatera lösenordet så behövs ditt nuvarande lösenord.'
}

Set-AdfsGlobalWebContent @enUS
Set-AdfsGlobalWebContent @svSE

Set-AdfsAuthenticationProviderWebContent -Name CertificateAuthentication -DisplayName 'Sign in with a certificate'
Set-AdfsAuthenticationProviderWebContent -Name CertificateAuthentication -DisplayName 'Logga in med certifikat' -Locale sv-SE

$Logo = ('{0}\logo\logo.png' -f $Theme)
if (Test-Path -Path $Logo) {
    Set-AdfsWebTheme -TargetName $Theme -Logo @{Path = $Logo}
}

$Illustration = ('{0}\illustration\Illustration.png' -f $Theme)
if (Test-Path -Path $Illustration) {
    Set-AdfsWebTheme -TargetName $Theme -Illustration @{Path = $Illustration}
}

$StyleSheet = ('{0}\css\style.css' -f $ThemePath)
if (Test-Path -Path $StyleSheet) {
    Set-AdfsWebTheme -TargetName $Theme -StyleSheet @{Locale=''; Path = $StyleSheet} -RTLStyleSheetPath $StyleSheet
}

$Onload = ('{0}\script\onload.js' -f $ThemePath)
if (Test-Path -Path $StyleSheet) {
    (Get-Content -Path $Onload -Encoding UTF8) -replace 'REPLACENETBIOS', $DomainShortName -replace 'REPLACEDOMAIN', $OrganizationDomain | Out-File -FilePath $Onload -Encoding utf8 -Force
    Set-AdfsWebTheme -TargetName $Theme -AdditionalFileResource @{Uri='/adfs/portal/script/onload.js'; Path = $Onload}
}

Set-AdfsWebConfig -ActiveThemeName $Theme

Restart-Service -Name adfssrv -Force -Verbose