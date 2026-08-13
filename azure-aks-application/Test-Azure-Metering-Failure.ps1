param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Corrupt","Recover","Verify")]
    [string]$Mode,

    [string]$Namespace = "titansftp-system",
    [string]$StatefulSetName = "titansftp",
    [int]$LogSinceMinutes = 120,
    [switch]$RestartStatefulSet,
    [switch]$FastRecoveryTick
)

$ErrorActionPreference = "Stop"

function Write-H([string]$t) {
    Write-Host "------------------------------------------------------------"
    Write-Host $t
    Write-Host "------------------------------------------------------------"
}

function Get-Pods() {
    kubectl -n $Namespace get pods -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{end}" |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ -like "$StatefulSetName-*" -or $_ -like "titansftp-*" }
}

function Restart-StsIfNeeded() {
    if ($RestartStatefulSet) {
        Write-Host "Restarting statefulset/$StatefulSetName ..."
        kubectl -n $Namespace rollout restart "statefulset/$StatefulSetName" | Out-Null
        kubectl -n $Namespace rollout status "statefulset/$StatefulSetName" --timeout=12m
    }
}

function Set-FastTickIfRequested() {
    if ($FastRecoveryTick) {
        Write-Host "Setting metering interval to 1 minute for faster recovery verification..."
        kubectl -n $Namespace set env "statefulset/$StatefulSetName" CloudSettings__Metering__IntervalMinutes=1 | Out-Null
    }
}

function Restore-NormalTickIfRequested() {
    if ($FastRecoveryTick) {
        Write-Host "Restoring metering interval to 60 minutes..."
        kubectl -n $Namespace set env "statefulset/$StatefulSetName" CloudSettings__Metering__IntervalMinutes=60 | Out-Null
    }
}

switch ($Mode) {
    "Corrupt" {
        Write-H "Mode: Corrupt (block metering API egress via proxy env)"
        # Block outbound HTTPS calls from process without touching workload identity
        kubectl -n $Namespace set env "statefulset/$StatefulSetName" `
            HTTPS_PROXY=http://127.0.0.1:9 `
            HTTP_PROXY=http://127.0.0.1:9 `
            ALL_PROXY=http://127.0.0.1:9 `
            NO_PROXY=127.0.0.1,localhost,.svc,.cluster.local | Out-Null

        Set-FastTickIfRequested
        Restart-StsIfNeeded

        Write-Host "Corruption applied. Metering API calls should fail transiently."
        Write-Host "Run Verify after some time to confirm transient failures."
        break
    }

    "Recover" {
        Write-H "Mode: Recover (remove proxy block)"
        kubectl -n $Namespace set env "statefulset/$StatefulSetName" `
            HTTPS_PROXY- HTTP_PROXY- ALL_PROXY- | Out-Null

        # keep NO_PROXY harmless if present
        kubectl -n $Namespace set env "statefulset/$StatefulSetName" `
            CloudSettings__Metering__Enabled=true | Out-Null

        Set-FastTickIfRequested
        Restart-StsIfNeeded

        Write-Host "Recovery applied. Wait for next metering tick."
        if (-not $FastRecoveryTick) {
            Write-Host "Note: default tick is 60 min, recovery log may appear later."
        }
        break
    }

    "Verify" {
        Write-H "Mode: Verify"

        $pods = Get-Pods
        if (-not $pods -or $pods.Count -eq 0) {
            throw "No pods found in namespace $Namespace"
        }

        Write-Host "Pods:"
        kubectl -n $Namespace get pods

        $p0 = $pods[0]
        Write-Host ""
        Write-Host "Env check from pod: $p0"
        kubectl -n $Namespace exec $p0 -c titansftp -- printenv | Select-String -Pattern "AZURE_CLIENT_ID|HTTPS_PROXY|HTTP_PROXY|ALL_PROXY|CloudSettings__Metering__Enabled|CloudSettings__Metering__IntervalMinutes"

        Write-Host ""
        Write-Host "Recent metering logs:"
        foreach ($p in $pods) {
            Write-Host ""
            Write-Host "--- $p ---"
            kubectl -n $Namespace logs $p -c titansftp --since=${LogSinceMinutes}m |
                Select-String -Pattern "Marketplace metering transient failure|Marketplace metering permanent failure|Marketplace metering tick:|Marketplace metering recovered|initiating domain-wide shutdown|ClientAssertionCredential|submitted="
        }

        Write-Host ""
        Write-Host "Verify complete."
        break
    }
}