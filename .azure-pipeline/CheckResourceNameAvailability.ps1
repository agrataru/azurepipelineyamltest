# This script is used to check if our resources like keyvault, sql, storage accounts and traffic manager are available or not 
# And if resource is not available it displays error message and exit the deployment. It checks for global name availability.

# This param accepts if it is local test instance or fairfax test instance
param([string] $type, [string]$accountname)
echo "value received $type, $accountname"
# Method to get access token from current user which will be used in the API for resource availability
function Get-AccessTokenFromCurrentUser {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList $azProfile
    $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    ('Bearer ' + $token.AccessToken)
}

# Method which invokes API
function invokeApi {
    param
    (
        [string] $Uri,
        $ServiceType
    )

    $typeByServiceType = @{
        KeyVault        = 'Microsoft.KeyVault/vaults'
        Sql             = 'Microsoft.Sql/servers'
        StorageAccount  = 'Microsoft.Storage/storageAccounts'
        Network         = 'Microsoft.Network/trafficManagerProfiles'
    }

    $AuthorizationToken = Get-AccessTokenFromCurrentUser

    $body = '"name": "{0}", "type": "{1}"' -f $Name, $typeByServiceType[$ServiceType]
    Write-Verbose -Verbose  "API Body : $body"
    Write-Host '-----------------------------------'

    $response = (Invoke-WebRequest -Uri $Uri -Method Post -Body "{$body}" -ContentType "application/json" -Headers @{Authorization = $AuthorizationToken }).content
    $response | ConvertFrom-Json |
        Select-Object @{N = 'Name'; E = { $Name } }, @{N = 'Type'; E = { $ServiceType } }, @{N = 'Available'; E = { $_ | Select-Object -ExpandProperty *available } }, Reason, Message
    Write-Verbose -Verbose "API Response : $response"
    Write-Host '------------------------------------'
}

# Method which takes the parameters to check and call the respective API and returns response if resource is available or not for public cloud
function Test-AzNameAvailabilityPublicCloud {
    param
    (
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [ValidateSet(
             'KeyVault', 'Sql', 'StorageAccount', 'Network')]
        $ServiceType
    )

    $SubscriptionId = '32f750d1-2a53-4792-a857-b5a0ee599f96'

    $uriByServiceType = @{
        KeyVault        = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.KeyVault/checkNameAvailability?api-version=2019-09-01'
        Sql             = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Sql/checkNameAvailability?api-version=2018-06-01-preview'
        StorageAccount  = 'https://management.azure.com/subscriptions/{subscriptionId}/providers/Microsoft.Storage/checkNameAvailability?api-version=2019-06-01'
        Network  =        'https://management.azure.com/providers/Microsoft.Network/checkTrafficManagerNameAvailability?api-version=2018-04-01'
    }

    $uri = $uriByServiceType[$ServiceType] -replace ([regex]::Escape('{subscriptionId}')), $SubscriptionId
    Write-Verbose -Verbose "Requesting Url :  $uri"
    Write-Host '----------------------------------'

    $paramsForInvokingApi = @{
        Uri = $uri
        ServiceType = $ServiceType
    }

    invokeApi @paramsForInvokingApi
}

# Method which takes the parameters to check and call the respective API and returns response if resource is available or not for private cloud
function Test-AzNameAvailabilityPrivateCloud{
     param
    (
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [ValidateSet(
             'KeyVault', 'Sql', 'StorageAccount', 'Network')]
        $ServiceType
    )

    $uriByServiceType = @{
        KeyVault        =  "$($endpoint.Url)/subscriptions/$($endpoint.Data.SubscriptionId)/providers/Microsoft.KeyVault/checkNameAvailability?api-version=2019-09-01"
        Sql             =  "$($endpoint.Url)/subscriptions/$($endpoint.Data.SubscriptionId)/providers/Microsoft.Sql/checkNameAvailability?api-version=2018-06-01-preview"
        StorageAccount  =  "$($endpoint.Url)/subscriptions/$($endpoint.Data.SubscriptionId)/providers/Microsoft.Storage/checkNameAvailability?api-version=2019-06-01"
        Network         =  "$($endpoint.Url)/providers/Microsoft.Network/checkTrafficManagerNameAvailability?api-version=2018-04-01"
    }

    $uri = $uriByServiceType[$ServiceType]
    Write-Verbose -Verbose "Requesting Url1 :  $uri"
    Write-Host '----------------------------------'

    $paramsForInvokingApi = @{
        Uri = $uri
        ServiceType = $ServiceType
    }

    invokeApi @paramsForInvokingApi 
}

# Resource names which needs to be checked for availability
$KeyVault = $accountname + '-kv'
$KeyVaultEncrypted = $accountname + 'pri-des-kv'
$Sql = $accountname + '-mssql'
$StorageAccountActions = $accountname + 'actions'
$StorageAccountPackages = $accountname + 'packages'
$StorageAccountPriAudit = $accountname + 'priaudit'
$TrafficManager  = $accountname

if ($type -eq 'fairfax') {
    $KeyVaultResponse = Test-AzNameAvailabilityPrivateCloud  -Name $KeyVault -ServiceType 'KeyVault'
} else {
    $KeyVaultResponse = Test-AzNameAvailabilityPublicCloud -Name $KeyVault-ServiceType 'KeyVault'
}

if (($KeyVaultResponse).Available) {
   Write-Host 'KeyVault' $KeyVault 'looks good'
} else {
   Write-Host 'KeyVault' $KeyVault 'not available'
}

Write-Host '---------------------------------'

if ($type -eq 'fairfax') {
    $EncryptedKeyVaultResponse = Test-AzNameAvailabilityPrivateCloud -Name $KeyVaultEncrypted -ServiceType 'KeyVault' 
} else {
    $EncryptedKeyVaultResponse = Test-AzNameAvailabilityPublicCloud -Name $KeyVaultEncrypted -ServiceType 'KeyVault'
}

if (($EncryptedKeyVaultResponse).Available) {
   Write-Host 'KeyVault' $KeyVaultEncrypted 'looks good'
} else {
   Write-Host 'KeyVault' $KeyVaultEncrypted 'not available'
}

Write-Host '------------------------------------------'

if ($type -eq 'fairfax') {
    $SqlResponse  = Test-AzNameAvailabilityPrivateCloud -Name $Sql -ServiceType 'Sql'
} else {
    $SqlResponse  = Test-AzNameAvailabilityPublicCloud -Name $Sql -ServiceType 'Sql'
}

if (($SqlResponse).Available) {
    Write-Host 'SQL' $Sql 'looks good'
} else {
    Write-Host 'Sql' $Sql 'not available'
}

 Write-Host '---------------------------------'

if ($type -eq 'fairfax') {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPrivateCloud -Name $StorageAccountActions -ServiceType 'StorageAccount'
} else {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPublicCloud -Name $StorageAccountActions -ServiceType 'StorageAccount'
}

if (($StorageAccountActionsResponse).Available) {
    Write-Host 'StorageAccountActions' $StorageAccountActions 'looks good'
} else {
    Write-Host 'StorageAccountActions' $StorageAccountActions 'not available'
}

 Write-Host '---------------------------------'

$paramsStorageAccountPackages = @{
    Name               = $StorageAccountPackages
    ServiceType        = 'StorageAccount'
}

if ($type -eq 'fairfax') {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPrivateCloud -Name $StorageAccountPackages -ServiceType 'StorageAccount'
} else {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPublicCloud -Name $StorageAccountPackages -ServiceType 'StorageAccount'
}

if (($StorageAccountPackagesResponse).Available) {
    Write-Host 'StorageAccountPackages' $StorageAccountPackages 'looks good'
} else {
    Write-Host 'StorageAccountPackages' $StorageAccountPackages 'not available'
}

 Write-Host '---------------------------------'

if ($type -eq 'fairfax') {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPrivateCloud -Name $StorageAccountPriAudit -ServiceType 'StorageAccount'
} else {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPublicCloud -Name $StorageAccountPriAudit -ServiceType 'StorageAccount'
}

if (($StorageAccountPriAuditResponse).Available) {
    Write-Host 'StorageAccountPreAudit' $StorageAccountPreAudit 'looks good'
} else {
    Write-Host 'StorageAccountPreAudit' $StorageAccountPriAudit 'not available'
}

 Write-Host '---------------------------------'

$paramsTrafficManager = @{
    Name               = $TrafficManager
    ServiceType        = 'Network'
}

if ($type -eq 'fairfax') {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPrivateCloud -Name $TrafficManager -ServiceType 'Network'
} else {
    $StorageAccountActionsResponse  = Test-AzNameAvailabilityPublicCloud -Name $TrafficManager -ServiceType 'Network'
}

if (($TrafficManagerResponse).Available) {
    Write-Host 'TrafficManager' $TrafficManager 'looks good' -Name $KeyVaultEncrypted -ServiceType 'KeyVault'
} else {
    Write-Host 'TrafficManager' $TrafficManager 'not available'
}
