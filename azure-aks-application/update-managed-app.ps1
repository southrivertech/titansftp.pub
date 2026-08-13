param(
  # Buyer-visible resource group where the managed application resource exists.
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroup,

  # Managed application name in the buyer RG.
  [string]$ApplicationName = "TitanSftpContainerApp",

  # Optional explicit managed RG / AKS name. If omitted, auto-derived from managed app resource.
  [string]$ManagedResourceGroup = "",
  [string]$AksClusterName = "",

  # Whitelisted operational updates only:
  #  - NodeCount : scale user node pool + StatefulSet replicas
  #  - ImageTag  : update both titansftp and admin-setup containers
  [int]$NodeCount = 0,
  [string]$ImageTag = "",

  # AKS/Helm object names.
  [string]$Namespace = "titansftp-system",
  [string]$StatefulSetName = "titansftp",
  [string]$NodePoolName = "",
  [bool]$ReconcilePerPodLoadBalancers = $true,

  # Image repository is still seller-controlled namespace; buyer only picks tag.
  [string]$AcrName = "titancontainerofferacr",
  [string]$AcrRepo = "titansftp-managedapp",

  # Preview commands without changing cluster state.
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

function Require-Command([string]$Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found on PATH: $Name"
  }
}

function Require-LastExit([string]$Step) {
  if ($LASTEXITCODE -ne 0) { throw "$Step failed (exit code $LASTEXITCODE)." }
}

function Get-LeafResourceName([string]$resourceId) {
  if ([string]::IsNullOrWhiteSpace($resourceId)) { return "" }
  $parts = $resourceId.Trim('/').Split('/')
  if ($parts.Length -eq 0) { return "" }
  return $parts[$parts.Length - 1]
}

function Sync-PerPodLoadBalancers(
  [string]$Namespace,
  [string]$StatefulSetName,
  [int]$Replicas,
  [bool]$WhatIfMode
) {
  if ($Replicas -lt 1) { throw "Replicas must be >= 1 for per-pod load balancers." }

  $ss = kubectl get statefulset $StatefulSetName -n $Namespace -o json 2>$null | ConvertFrom-Json
  Require-LastExit "Read StatefulSet for service selectors"
  if (-not $ss) { throw "StatefulSet not found: $Namespace/$StatefulSetName" }

  $labels = $ss.spec.template.metadata.labels
  $instanceLabel = $labels.'app.kubernetes.io/instance'
  $nameLabel = $labels.'app.kubernetes.io/name'
  if ([string]::IsNullOrWhiteSpace($instanceLabel)) { $instanceLabel = $StatefulSetName }
  if ([string]::IsNullOrWhiteSpace($nameLabel)) { $nameLabel = $StatefulSetName }

  for ($i = 0; $i -lt $Replicas; $i++) {
    $svcName = "$StatefulSetName-lb-$i"
    $yaml = @"
apiVersion: v1
kind: Service
metadata:
  name: $svcName
  namespace: $Namespace
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/instance: $instanceLabel
    app.kubernetes.io/name: $nameLabel
    statefulset.kubernetes.io/pod-name: $StatefulSetName-$i
  ports:
    - protocol: TCP
      name: sftp
      port: 22
      targetPort: 22
    - protocol: TCP
      name: https
      port: 443
      targetPort: 443
    - protocol: TCP
      name: admin
      port: 41443
      targetPort: 41443
"@
    if ($WhatIfMode) {
      Write-Host "[WhatIf] create/apply Service $Namespace/$svcName for pod $StatefulSetName-$i"
    }
    else {
      $yaml | kubectl apply -f - | Out-Null
      Require-LastExit "Apply Service $Namespace/$svcName"
    }
  }

  # Remove stale per-pod LB services above current replica count.
  $svcJson = kubectl get svc -n $Namespace -o json 2>$null | ConvertFrom-Json
  Require-LastExit "List Services for stale LB cleanup"
  # Match names like: titansftp-lb-0, titansftp-lb-1, ...
  # Use a single regex escape for digit group; double-backslash would match a
  # literal "\" and never detect stale services.
  $namePattern = "^" + [regex]::Escape($StatefulSetName) + "-lb-(\d+)$"
  foreach ($svc in $svcJson.items) {
    $n = $svc.metadata.name
    if ($n -match $namePattern) {
      $idx = [int]$Matches[1]
      if ($idx -ge $Replicas) {
        if ($WhatIfMode) {
          Write-Host "[WhatIf] delete stale Service $Namespace/$n"
        }
        else {
          kubectl delete svc $n -n $Namespace --ignore-not-found | Out-Null
          Require-LastExit "Delete stale Service $Namespace/$n"
        }
      }
    }
  }
}

if ($NodeCount -le 0 -and [string]::IsNullOrWhiteSpace($ImageTag)) {
  throw "Nothing to update. Provide at least one of: -NodeCount <N> or -ImageTag <tag>."
}
if ($NodeCount -lt 0) {
  throw "-NodeCount cannot be negative."
}

Require-Command "az"
Require-Command "kubectl"

# ---------------------------------------------------------------------------
# Resolve authoritative managed-app identity + immutable metering identifiers.
# ---------------------------------------------------------------------------
$app = az resource show `
  --resource-group $ResourceGroup `
  --name $ApplicationName `
  --resource-type Microsoft.Solutions/applications `
  -o json | ConvertFrom-Json
Require-LastExit "Read managed application resource"

if (-not $app) { throw "Managed application not found: $ApplicationName in $ResourceGroup" }
$planName = $app.plan.name
$appResourceId = $app.id
if ([string]::IsNullOrWhiteSpace($planName)) {
  throw "Managed app plan.name is empty. Cannot enforce immutable metering identity."
}
if ([string]::IsNullOrWhiteSpace($appResourceId)) {
  throw "Managed app resource id is empty. Cannot enforce immutable metering identity."
}

if ([string]::IsNullOrWhiteSpace($ManagedResourceGroup)) {
  $ManagedResourceGroup = Get-LeafResourceName $app.properties.managedResourceGroupId
}
if ([string]::IsNullOrWhiteSpace($ManagedResourceGroup)) {
  throw "Managed resource group could not be resolved. Pass -ManagedResourceGroup explicitly."
}

if ([string]::IsNullOrWhiteSpace($AksClusterName)) {
  $AksClusterName = $app.properties.outputs.aksClusterName.value
}
if ([string]::IsNullOrWhiteSpace($AksClusterName)) {
  throw "AKS cluster name could not be resolved from managed app outputs. Pass -AksClusterName explicitly."
}

$imageRepository = "$AcrName.azurecr.io/$AcrRepo"
$targetImage = if ([string]::IsNullOrWhiteSpace($ImageTag)) { "" } else { "$imageRepository`:$ImageTag" }

Write-Host "=========================================================="
Write-Host " Titan SFTP Managed App - Buyer Safe Updater"
Write-Host " Buyer RG              : $ResourceGroup"
Write-Host " Managed App           : $ApplicationName"
Write-Host " Managed RG            : $ManagedResourceGroup"
Write-Host " AKS Cluster           : $AksClusterName"
Write-Host " Namespace/StatefulSet : $Namespace / $StatefulSetName"
Write-Host " Immutable Plan        : $planName"
Write-Host " Immutable ResourceUri : $appResourceId"
if ($NodeCount -gt 0) { Write-Host " Requested NodeCount   : $NodeCount" }
if ($targetImage) { Write-Host " Requested Image       : $targetImage" }
Write-Host " Reconcile LB Services : $ReconcilePerPodLoadBalancers"
Write-Host " WhatIf                : $($WhatIf.IsPresent)"
Write-Host "=========================================================="

# Keep execution deterministic for the target cluster.
az aks get-credentials --resource-group $ManagedResourceGroup --name $AksClusterName --overwrite-existing | Out-Null
Require-LastExit "az aks get-credentials"

# ---------------------------------------------------------------------------
# Immutable metering guardrail: do not accept arbitrary plan/resource values.
# Always enforce values from managed app contract metadata.
# ---------------------------------------------------------------------------
$existingPlan = (kubectl get statefulset $StatefulSetName -n $Namespace -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name=='CloudSettings__Metering__AzurePlanId')].value}" 2>$null).Trim()
$existingUri  = (kubectl get statefulset $StatefulSetName -n $Namespace -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name=='CloudSettings__Metering__AzureResourceUri')].value}" 2>$null).Trim()

if (-not [string]::IsNullOrWhiteSpace($existingPlan) -and $existingPlan -ne $planName) {
  throw "Metering plan mismatch detected (cluster='$existingPlan', contract='$planName'). Refusing update."
}
if (-not [string]::IsNullOrWhiteSpace($existingUri) -and $existingUri -ne $appResourceId) {
  throw "Metering resourceUri mismatch detected (cluster='$existingUri', contract='$appResourceId'). Refusing update."
}

if ($WhatIf) {
  Write-Host "[WhatIf] kubectl set env statefulset/$StatefulSetName -n $Namespace CloudSettings__Metering__Enabled=true CloudSettings__Metering__AzurePlanId=$planName CloudSettings__Metering__AzureResourceUri=$appResourceId"
}
else {
  kubectl set env statefulset/$StatefulSetName -n $Namespace `
    "CloudSettings__Metering__Enabled=true" `
    "CloudSettings__Metering__AzurePlanId=$planName" `
    "CloudSettings__Metering__AzureResourceUri=$appResourceId" | Out-Null
  Require-LastExit "Apply immutable metering env"
}

# ---------------------------------------------------------------------------
# Whitelisted update #1: image tag rollout.
# ---------------------------------------------------------------------------
if ($targetImage) {
  if ($WhatIf) {
    Write-Host "[WhatIf] kubectl set image statefulset/$StatefulSetName -n $Namespace titansftp=$targetImage admin-setup=$targetImage"
  }
  else {
    kubectl set image statefulset/$StatefulSetName -n $Namespace `
      "titansftp=$targetImage" `
      "admin-setup=$targetImage" | Out-Null
    Require-LastExit "Update StatefulSet image"
    kubectl rollout status statefulset/$StatefulSetName -n $Namespace --timeout=20m
    Require-LastExit "Wait for image rollout"
  }
}

# ---------------------------------------------------------------------------
# Whitelisted update #2: node count + replica count.
# ---------------------------------------------------------------------------
if ($NodeCount -gt 0) {
  if ([string]::IsNullOrWhiteSpace($NodePoolName)) {
    $pools = az aks nodepool list --resource-group $ManagedResourceGroup --cluster-name $AksClusterName -o json | ConvertFrom-Json
    Require-LastExit "List AKS node pools"
    $userPool = $pools | Where-Object { $_.mode -eq "User" } | Select-Object -First 1
    if (-not $userPool) { $userPool = $pools | Select-Object -First 1 }
    if (-not $userPool) { throw "No AKS node pool found. Pass -NodePoolName explicitly." }
    $NodePoolName = $userPool.name
  }

  if ($WhatIf) {
    Write-Host "[WhatIf] az aks nodepool scale --resource-group $ManagedResourceGroup --cluster-name $AksClusterName --name $NodePoolName --node-count $NodeCount"
    Write-Host "[WhatIf] kubectl scale statefulset/$StatefulSetName -n $Namespace --replicas=$NodeCount"
    if ($ReconcilePerPodLoadBalancers) {
      Sync-PerPodLoadBalancers -Namespace $Namespace -StatefulSetName $StatefulSetName -Replicas $NodeCount -WhatIfMode $true
    }
  }
  else {
    az aks nodepool scale --resource-group $ManagedResourceGroup --cluster-name $AksClusterName --name $NodePoolName --node-count $NodeCount --only-show-errors | Out-Null
    Require-LastExit "Scale AKS node pool"

    kubectl scale statefulset/$StatefulSetName -n $Namespace --replicas=$NodeCount | Out-Null
    Require-LastExit "Scale StatefulSet replicas"
    kubectl rollout status statefulset/$StatefulSetName -n $Namespace --timeout=20m
    Require-LastExit "Wait for replica rollout"
    if ($ReconcilePerPodLoadBalancers) {
      Sync-PerPodLoadBalancers -Namespace $Namespace -StatefulSetName $StatefulSetName -Replicas $NodeCount -WhatIfMode $false
    }
  }
}

# ---------------------------------------------------------------------------
# Final snapshot
# ---------------------------------------------------------------------------
if (-not $WhatIf) {
  Write-Host "`nPost-update snapshot:"
  kubectl get nodes -o wide
  kubectl get pods -n $Namespace -o wide
  kubectl get svc -n $Namespace -o wide
  $effectivePlan = (kubectl get statefulset $StatefulSetName -n $Namespace -o jsonpath="{.spec.template.spec.containers[0].env[?(@.name=='CloudSettings__Metering__AzurePlanId')].value}" 2>$null).Trim()
  $effectiveImage = kubectl get statefulset $StatefulSetName -n $Namespace -o jsonpath="{.spec.template.spec.containers[0].image}"
  Write-Host "Effective image   : $effectiveImage"
  Write-Host "Effective plan id : $effectivePlan"
}
