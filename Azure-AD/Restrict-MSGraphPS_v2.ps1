<#
.SYNOPSIS
    Restrict Microsoft Graph PowerShell access.
.DESCRIPTION
    This script configures the recommended restrictions to secure access to Microsoft Graph PowerShell modules. Using these restrictions enable Soteria to perform assessments without the need for Global Administrator rights. 
.COMPONENT
    PowerShell, Azure Active Directory PowerShell Module, and sufficient rights to change Tenant settings
.ROLE
    Recommended to run as Global Admin or Application Admin
.FUNCTIONALITY
    Restrict Microsoft Graph PowerShell access to only approved roles and users.
#>


<#
Steps outlined below:

Define the app you want to restrict
Define the users or roles you want to grant access to
	You may opt for an Azure AD Directory Role (eg, Global Administrator)
	You may use a CSV file of Admins and Users containing their UPN (User Principal Name) 
This method requires that the application has a Service Principal, if one does not exist, you can create it for the specific application
	Check for the Service Principal
    	$servicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"
	Create the Service Principal if it does not exist
    	if (-not $servicePrincipal) {$servicePrincipal = New-AzureADServicePrincipal -AppId $appId}
	Set the Service Principal to require Assignment
    	Set-AzureADServicePrincipal -ObjectId $ervicePrincipal.ObjectId -AppRoleAssignmentRequired $true
	Set the Service Principal Assignment
    	New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId -ResourceId $servicePrincipal.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $admin.ObjectID
#>


#Connect to Azure AD
Connect-AzureAD 


Function Show-Menu {
    param (
        [string]$Title = "Please choose an option"
    )

    Write-Host "================ $Title ================"
    Write-Host ""
    Write-Host "1: Press 'L' to upload a list of users."
    Write-Host "2: Press 'S' to add a single user."
	Write-Host "3: Press 'G' to add an Azure Security Group."
    Write-Host""
}


Function Me {
    $session = Get-AzureADCurrentSessionInfo 
    $me = Get-AzureADUser -ObjectId $session.Account.Id
    $global:Me = $me
}

Function List{
    $path = Read-Host -Prompt "Enter the path to the file containing list of Users DisplayName's. One per line."
    $users = Get-Content -Path $path
    Foreach ($user in $users){
        $x = Get-AzureADUser | Where-Object {$_.DisplayName -like $user}
        $global:Users += $x
    }
}

Function SingleUser {
    $admin = Read-Host -Prompt "Enter the DisplayName of the User"
    $global:Users = Get-AzureADUser | Where-Object {$_.DisplayName -like $admin}
}

Function AADGroup {
    $group = Read-Host -Prompt "Enter the DisplayName of the Group to assign"
    $global:Users = Get-AzureADGroup | Where-Object {$_.DisplayName -like $group}
}

Function Get-Admins {
    do {
        Show-Menu

        $userOption = Read-Host "Choose your option"
        
        Switch ($userOption){
            L {List}
            S {SingleUser}
            G {AADGroup}   
            }
        Return $global:Users | Out-Null
    }
    While($null -eq $userOption)
}


Function Restrict-MSGraph {
    #Define the application by specifying the appId
    #Microsoft Graph - 14d82eec-204b-4c2f-b7e8-296a70dab67e
    $appId = "14d82eec-204b-4c2f-b7e8-296a70dab67e"

    #Check for existing Service Principal
    Write-Output "`nChecking for existing Service Principal"
    $servicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$appId'"

    if (-not $servicePrincipal) {
        $install = Read-Host -Prompt "`nService Prinicpal does not exist. Would you like to create it now?"

        If ($install -eq "y"){
            $servicePrincipal = New-AzureADServicePrincipal -AppId $appId
        }
        Else {
            Write-Output "`nService Principal is required to proceed.`nExiting..."
            Exit
        }
    }
    Else {
        #Set the Service Principal to require assignment
        Write-Output "`nSetting the Service Principal to require assignment"
        Set-AzureADServicePrincipal -ObjectId $servicePrincipal.ObjectId -AppRoleAssignmentRequired $true
    }

    #Set the assignment on the Service Principal. Include user running this script by default to prevent locking out the application.
    Me
        
    Write-Output "`nPreventing lockout of the application. Assigning your user by default."
    New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId -ResourceId $servicePrincipal.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $global:Me

    Get-Admins

    Foreach ($i in $global:Users){
        Write-Output "Adding $($i.DisplayName) to $($servicePrincipal.DisplayName) restriction."
        New-AzureADServiceAppRoleAssignment -ObjectId $servicePrincipal.ObjectId -ResourceId $servicePrincipal.ObjectId -Id ([Guid]::Empty.ToString()) -PrincipalId $i.ObjectID
    }
}


Restrict-MSGraph