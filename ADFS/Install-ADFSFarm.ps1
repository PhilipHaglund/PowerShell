# Group Managed Service Accounts requires at least Domain Functional level Windows Server 2012
[string]$DomainShortName                  = "$ENV:USERDOMAIN"
[string]$ADFSGMSA                         = 'svc-adfsfarm$'

[string]$OrganizationDomain               = 'contoso.com'
[string]$FederationServiceName            = 'adfs.{0}' -f $OrganizationDomain
[string]$FederationServiceDisplayName     = 'Contoso ADFS Server'
[string]$DeviceRegistrationUpnSuffix      = '{0}' -f $OrganizationDomain

[string]$CertificateLengthinDays          = '1826'
[string]$ADFSContactPersonCompany         = '{0}' -f $OrganizationDomain
[string]$ADFSContactPersonEmailAddress    = 'servicedesk@{0}' -f $OrganizationDomain
[string]$ADFSContactPersonGivenName       = 'Philip'
[string]$ADFSContactPersonSurname         = 'Haglund'
[string]$ADFSContactPersonTelephoneNumber = '+46 555 12345'
[string]$ADFSOrganizationDisplayName      = 'Contoso'
[string]$ADFSOrganizationName             = 'Contoso'
[string]$ADFSOrganizationUrl              = 'https://www.{0}/' -f $OrganizationDomain

$RunCred = {
    [System.Diagnostics.CodeAnalysis.SuppressMessage('PSUseDeclaredVarsMoreThanAssignments', '')]
    $Cred = Get-Credential -Credential ('{0}\svc-adfs' -f $DomainShortName)
}

# Locate TLS Certificate on the ADFS Server. Must be imported the correct store.
$FederationServiceCertificate = Get-ChildItem -Path 'Cert:\LocalMachine\My' | Where-Object -FilterScript {
    $_.Subject -match ('CN={0}' -f $FederationServiceName) -or $_.Subject -match ($FederationServiceName -replace '^(.*?)\.', 'CN=*.')
}
$CertificateThumbprint = $FederationServiceCertificate.Thumbprint.ToString()

# Install ADFS role
Get-WindowsFeature -Name ADFS-Federation | Where-Object -FilterScript {
    $_.Installed -match 'False'
} | Install-WindowsFeature

# Configure ADFS role and install ADFS farm
if ((Test-Certificate -Cert $FederationServiceCertificate -EKU 1.3.6.1.5.5.7.3.1 -DNSName ('{0}' -f $FederationServiceName)) -match $True) {
    #Install ADFS farm
    try {
        Install-AdfsFarm -CertificateThumbprint $CertificateThumbprint -FederationServiceName $FederationServiceName -FederationServiceDisplayName $FederationServiceDisplayName -GroupServiceAccountIdentifier $DomainShortName\$ADFSGMSA -OverwriteConfiguration -ErrorAction Stop
    }
    catch {
        . $RunCred
        Install-AdfsFarm -CertificateThumbprint $CertificateThumbprint -FederationServiceName $FederationServiceName -FederationServiceDisplayName $FederationServiceDisplayName -ServiceAccountCredential $Cred -OverwriteConfiguration
    }
    
    #Extend certificate duration
    Set-ADFSProperties -CertificateDuration $CertificateLengthinDays

    # Generate new ADFS certificates
    Update-ADFSCertificate -Urgent

    # Enable Device Registration Service
    if ((Test-Certificate -Cert $FederationServiceCertificate -EKU 1.3.6.1.5.5.7.3.1 -DNSName ('enterpriseregistration.{0}' -f $DeviceRegistrationUpnSuffix)) -match $True) {
        # Prepare Active Directory for DRS
        Initialize-ADDeviceRegistration -ServiceAccountName $Cred -Force

        # Activate DRS on ADFS server (if Windows Server 2012 R2)
        if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -eq '6.3.9600') {
            Enable-AdfsDeviceRegistration
        }

        # Add UPN-suffix in DRS
        Add-AdfsDeviceRegistrationUpnSuffix -UpnSuffix ('{0}' -f $DeviceRegistrationUpnSuffix)

        # Enable DRS in authentication policy
        Set-AdfsGlobalAuthenticationPolicy -DeviceAuthenticationEnabled $True
    }


    # Configure authentication policy (if Windows Server 2012 R2)
    if ((Get-CimInstance -ClassName Win32_OperatingSystem).Version -eq '6.3.9600') {
        Set-AdfsGlobalAuthenticationPolicy -PrimaryIntranetAuthenticationProvider FormsAuthentication, WindowsAuthentication
        Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider FormsAuthentication
        Set-AdfsGlobalAuthenticationPolicy -AdditionalAuthenticationProvider CertificateAuthentication
    }

    # Configure authentication policy (if Windows Server 2016)
    if (([version](Get-CimInstance -ClassName Win32_OperatingSystem).Version).Major -ge 10) {
        Set-AdfsGlobalAuthenticationPolicy -PrimaryIntranetAuthenticationProvider FormsAuthentication, WindowsAuthentication, DeviceAuthentication
        Set-AdfsGlobalAuthenticationPolicy -PrimaryExtranetAuthenticationProvider FormsAuthentication, DeviceAuthentication
        Set-AdfsGlobalAuthenticationPolicy -AdditionalAuthenticationProvider CertificateAuthentication
    }

    #Enable KMSI (Keep Me Signed In) in ADFS
    Set-AdfsProperties -EnableKmsi $True

    #Disable Extended Protection Token Check
    Set-ADFSProperties -ExtendedProtectionTokenCheck None

    #Enable Password Change in ADFS
    Enable-AdfsEndpoint -TargetAddressPath /adfs/portal/updatepassword/

    #Enable Password Change in WAP
    Set-AdfsEndpoint -TargetAddressPath /adfs/portal/updatepassword/ -Proxy $True

    # Configure ADFS Organization Information
    $AdfsContactPerson = New-ADFSContactPerson -Company $ADFSContactPersonCompany -EmailAddress $ADFSContactPersonEmailAddress -GivenName $ADFSContactPersonGivenName -Surname $ADFSContactPersonSurname -TelephoneNumber $ADFSContactPersonTelephoneNumber
    $AdfsOrganization = New-ADFSOrganization -DisplayName $ADFSOrganizationDisplayName -OrganizationUrl $ADFSOrganizationUrl -Name $ADFSOrganizationName
    Set-AdfsProperties -OrganizationInfo $AdfsOrganization -ContactPerson $AdfsContactPerson

    #Restart ADFS service
    Restart-Service -Name adfssrv -Force
}