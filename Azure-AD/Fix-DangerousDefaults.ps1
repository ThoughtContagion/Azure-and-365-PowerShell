Function Fix-DangerousDefaults{
    $permissions = Get-MsolCompanyInformation
    $authPolicy = Get-AzureADMSAuthorizationPolicy

    If (($permissions.UsersPermissionToReadOtherUsersEnabled -eq $true) -or ($permissions.UsersPermissionToCreateGroupsEnabled -eq $true) -or ($permissions.UsersPermissionToCreateLOBAppsEnabled -eq $true) -or ($permissions.UsersPermissionToUserConsentToAppEnabled -eq $true) -or ($authPolicy.AllowEmailVerifiedUsersToJoinOrganization -eq $true) -or ($authPolicy.AllowedToSignupEmailBasedSubscriptions -eq $true)){
        Set-MsolCompanySettings -UsersPermissionToCreateGroupsEnabled $false
        Set-MsolCompanySettings -UsersPermissionToCreateLOBAppsEnabled $false
        Set-MsolCompanySettings -UsersPermissionToReadOtherUsersEnabled $false
        Set-MsolCompanySettings -UsersPermissionToUserConsentToAppEnabled $false
        Set-AzureADMSAuthorizationPolicy -id (Get-AzureADMSAuthorizationPolicy).id -AllowedToSignupEmailBasedSubscriptions $false
        Set-AzureADMSAuthorizationPolicy -id (Get-AzureADMSAuthorizationPolicy).id -AllowEmailVerifiedUsersToJoinOrganization $false
    }
}