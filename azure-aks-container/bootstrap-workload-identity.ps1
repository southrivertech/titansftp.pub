<#
.SYNOPSIS
    One-shot, idempotent bootstrap of Azure Workload Identity for the Titan SFTP
    Simple Azure Container Offer (AKS extension).

.DESCRIPTION
    Marketplace attestation for the AKS container offer needs the extension's
    User Assigned Managed Identity (UAMI) to be able to exchange the projected
    Kubernetes service-account token for an ARM token and then read the
    extension resource. That requires two pieces of infra wiring that are NOT
    always created automatically:

        1. A Federated Identity Credential (FIC) on the UAMI that trusts the
           cluster OIDC issuer + the extension service account.
        2. An RBAC role assignment (Reader) on the extension resource so the
           attestation ARM read (Microsoft.KubernetesConfiguration/extensions/read)
           returns 200 instead of 403.

    When either is missing, Titan logs:
        "Azure attestation failed: unable to get ARM token ..."   (missing FIC)
        "Azure attestation failed: ARM read returned 403 ..."     (missing RBAC)
    and then fail-closes the non-LAS servers.

    This script discovers everything from the running cluster/extension and
    creates only what is missing. It is safe to re-run.

    NOTE: This is infra wiring only. It does NOT change any application/C# code.
    Creating the role assignment requires the caller to have Owner or
    User Access Administrator on the extension scope.

.EXAMPLE
    ./bootstrap-workload-identity.ps1 `
        -SubscriptionId "<your-subscription-id>" `
        -ClusterResourceGroup "<your-aks-resource-group>" `
        -ClusterName "<your-aks-cluster-name>" `
        -ExtensionName "titansftp-ext" `
        -ReleaseNamespace "titansftp-system" `
        -RestartStatefulSet
#>

param(
    [Parameter(Mandatory = $true)]  [string]$SubscriptionId,
    [Parameter(Mandatory = $true)]  [string]$ClusterResourceGroup,
    [Parameter(Mandatory = $true)]  [string]$ClusterName,
    [string]$ExtensionName      = "titansftp-ext",
    [string]$ReleaseNamespace   = "titansftp-system",
    # Service account name = extension name (chart uses fullname = release name).
    [string]$ServiceAccountName = "",
    [string]$FederatedCredentialName = "titansftp-ext-sa-fic",
    [string]$Role               = "Reader",
    [switch]$RestartStatefulSet
)

$ErrorActionPreference = "Stop"

function Test-RequiredCommand($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        throw "Missing required command: $name"
    }
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Script,
        [int]$MaxAttempts = 10,
        [int]$DelaySeconds = 15,
        [string]$Description = "operation"
    )
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $result = & $Script
            if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace(($result -join [Environment]::NewLine))) {
                return $result
            }
        } catch {
            Write-Host "  [$attempt/$MaxAttempts] $Description not ready: $($_.Exception.Message)"
        }
        if ($attempt -lt $MaxAttempts) {
            Write-Host "  [$attempt/$MaxAttempts] Waiting $DelaySeconds s for $Description ..."
            Start-Sleep -Seconds $DelaySeconds
        }
    }
    throw "Timed out waiting for $Description after $MaxAttempts attempts."
}

Test-RequiredCommand az

# Trim stray whitespace so a leading/trailing space in a pasted argument
# (e.g. " rohit_rg_marketplace") does not cause ResourceGroupNotFound.
$SubscriptionId         = "$SubscriptionId".Trim()
$ClusterResourceGroup   = "$ClusterResourceGroup".Trim()
$ClusterName            = "$ClusterName".Trim()
$ExtensionName          = "$ExtensionName".Trim()
$ReleaseNamespace       = "$ReleaseNamespace".Trim()
$ServiceAccountName     = "$ServiceAccountName".Trim()
$FederatedCredentialName = "$FederatedCredentialName".Trim()
$Role                   = "$Role".Trim()

if ([string]::IsNullOrWhiteSpace($ServiceAccountName)) {
    $ServiceAccountName = $ExtensionName
}

Write-Host "Setting subscription context ..."
az account set --subscription $SubscriptionId
if ($LASTEXITCODE -ne 0) { throw "Unable to set subscription $SubscriptionId." }

Write-Host "Reading AKS OIDC issuer and node resource group ..."
$issuer = az aks show -g $ClusterResourceGroup -n $ClusterName --query "oidcIssuerProfile.issuerUrl" -o tsv
if ([string]::IsNullOrWhiteSpace($issuer)) {
    throw "Cluster OIDC issuer is empty. Enable oidcIssuerProfile + workloadIdentity on the AKS cluster first."
}
$nodeRg = az aks show -g $ClusterResourceGroup -n $ClusterName --query "nodeResourceGroup" -o tsv
Write-Host "  OIDC issuer : $issuer"
Write-Host "  Node RG     : $nodeRg"

$extId = "/subscriptions/$SubscriptionId/resourceGroups/$ClusterResourceGroup/providers/Microsoft.ContainerService/managedClusters/$ClusterName/providers/Microsoft.KubernetesConfiguration/extensions/$ExtensionName"

Write-Host "Resolving extension-assigned identity principalId (waiting until available) ..."
$principalId = Invoke-WithRetry -Description "extension identity" -Script {
    az resource show --ids $extId --query "properties.aksAssignedIdentity.principalId" -o tsv 2>$null
}
Write-Host "  Extension principalId : $principalId"

Write-Host "Locating UAMI by principalId in node resource group ..."
# NOTE: filter in PowerShell instead of an az --query JMESPath. On Windows,
# az is a .cmd wrapper and JMESPath strings containing [ ] ? == | get mangled
# by cmd.exe parsing (fails with "-o was unexpected at this time").
$uamiJson = Invoke-WithRetry -Description "UAMI" -Script {
    az identity list -g $nodeRg -o json 2>$null
}
$uami = ($uamiJson | ConvertFrom-Json) | Where-Object { $_.principalId -eq $principalId } | Select-Object -First 1
if (-not $uami -or [string]::IsNullOrWhiteSpace($uami.name)) {
    throw "UAMI with principalId $principalId not found in $nodeRg."
}
Write-Host "  UAMI name     : $($uami.name)"
Write-Host "  UAMI clientId : $($uami.clientId)"

$subject = "system:serviceaccount:${ReleaseNamespace}:${ServiceAccountName}"

# --- 1. Federated Identity Credential -------------------------------------
Write-Host "Ensuring federated credential '$FederatedCredentialName' ..."
$ficList = az identity federated-credential list `
    --resource-group $nodeRg `
    --identity-name $uami.name -o json | ConvertFrom-Json
$fic = $ficList | Where-Object { $_.name -eq $FederatedCredentialName } | Select-Object -First 1

if (-not $fic) {
    az identity federated-credential create `
        --resource-group $nodeRg `
        --identity-name $uami.name `
        --name $FederatedCredentialName `
        --issuer $issuer `
        --subject $subject `
        --audiences "api://AzureADTokenExchange" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Unable to create federated credential '$FederatedCredentialName'." }
    Write-Host "  Created FIC (issuer=$issuer subject=$subject)."
} elseif ($fic.issuer -ne $issuer -or $fic.subject -ne $subject) {
    Write-Host "  WARNING: existing FIC does not match. Updating ..."
    az identity federated-credential update `
        --resource-group $nodeRg `
        --identity-name $uami.name `
        --name $FederatedCredentialName `
        --issuer $issuer `
        --subject $subject `
        --audiences "api://AzureADTokenExchange" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Unable to update federated credential '$FederatedCredentialName'." }
} else {
    Write-Host "  FIC already correct, skipping."
}

# --- 2. RBAC role assignment on the extension scope -----------------------
Write-Host "Ensuring '$Role' role assignment on extension scope ..."
$raList = az role assignment list `
    --assignee-object-id $principalId `
    --scope $extId -o json | ConvertFrom-Json
$ra = $raList | Where-Object { $_.roleDefinitionName -eq $Role } | Select-Object -First 1

if (-not $ra) {
    az role assignment create `
        --assignee-object-id $principalId `
        --assignee-principal-type ServicePrincipal `
        --role $Role `
        --scope $extId | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "Unable to create role assignment '$Role' on extension scope." }
    Write-Host "  Created '$Role' assignment for principal $principalId."
} else {
    Write-Host "  Role assignment already present, skipping."
}

# --- 3. Optional: restart pods so they re-attest immediately --------------
if ($RestartStatefulSet) {
    Write-Host "Restarting statefulset/$ExtensionName so pods re-attest ..."
    az aks command invoke -g $ClusterResourceGroup -n $ClusterName `
        --command "kubectl rollout restart statefulset/$ExtensionName -n $ReleaseNamespace" | Out-Null
}

Write-Host ""
Write-Host "Workload identity bootstrap completed."
Write-Host "  FIC issuer  : $issuer"
Write-Host "  FIC subject : $subject"
Write-Host "  RBAC role   : $Role on $ExtensionName"
Write-Host ""
Write-Host "Verify with:"
Write-Host "  az aks command invoke -g $ClusterResourceGroup -n $ClusterName --command `"kubectl logs -n $ReleaseNamespace ${ExtensionName}-0 -c titansftp --tail=200 | grep -i 'attestation'`""
Write-Host "Expect: 'Azure attestation succeeded ...' and no 403 / NoRegisteredProviderFound / fail-closed stop."
