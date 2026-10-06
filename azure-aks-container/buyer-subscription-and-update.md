# Buyer Subscription and Update Guide

This guide explains how a buyer subscribes to, deploys, validates, and updates the Titan SFTP **Azure Container Offer** from Azure Marketplace. The container offer installs Titan SFTP as an extension on your own AKS cluster.

## Prerequisites

Before subscribing, make sure you have:

- An **AKS cluster** that you own, with the **OIDC issuer** and **workload identity** features enabled.
- **Azure CLI** (`az`) and **kubectl** installed on your workstation.
- Permission to install Marketplace extensions on the cluster.
- **Owner** or **User Access Administrator** on the extension scope (required only for the one-time workload identity bootstrap described below).

## Subscribe and Install the Extension

1. Open the Titan SFTP Azure Container Offer listing in Azure Marketplace.
2. Confirm the selected **Subscription** and **Plan**.
3. Select the target **AKS cluster** (resource group + cluster name) where the extension should be installed.
4. Review and create. Azure installs the Titan SFTP extension into the target namespace (default `titansftp-system`).
5. Monitor installation status in Azure Portal notifications and deployment history.

## Runtime Validation

After the extension is installed, validate the deployment:

1. Connect to your AKS cluster (see the [AKS operations cookbook](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/aks-operations-cookbook.md)).
2. Check pods and deployment status in the extension namespace (default `titansftp-system`).
3. Confirm the admin initialization path completed and you can log in with the expected credentials.
4. Inspect the pod logs and confirm the Marketplace **attestation succeeded** with no `403` / fail-closed messages.

## Why You Must Run `bootstrap-workload-identity.ps1`

The Titan SFTP extension validates its Marketplace entitlement at startup (**attestation**). To do this, the extension's **User Assigned Managed Identity (UAMI)** exchanges the projected Kubernetes service-account token for an Azure (ARM) token and then reads its own extension resource.

That token exchange and read only work if two pieces of Azure infrastructure wiring exist:

1. A **Federated Identity Credential (FIC)** on the UAMI that trusts your **cluster OIDC issuer** and the **extension service account**. Without it, the extension cannot obtain an ARM token.
2. A **Reader role assignment** on the extension resource scope so the attestation read (`Microsoft.KubernetesConfiguration/extensions/read`) returns `200` instead of `403`.

These are **not** always created automatically when the extension is installed. When either is missing, you will see log entries such as:

```text
Azure attestation failed: unable to get ARM token ...   (missing FIC)
Azure attestation failed: ARM read returned 403 ...     (missing RBAC)
```

and Titan SFTP will **fail-close the non-LAS servers** - meaning they will not start normally.

To create this wiring, run the one-time [`bootstrap-workload-identity.ps1`](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/bootstrap-workload-identity.ps1) script. It discovers everything from your running cluster and extension, and creates **only what is missing**. It is safe to re-run. It performs Azure infrastructure wiring only - it does not change any application configuration or data.

### Run the Bootstrap Script

```powershell
./bootstrap-workload-identity.ps1 `
    -SubscriptionId "<your-subscription-id>" `
    -ClusterResourceGroup "<your-aks-resource-group>" `
    -ClusterName "<your-aks-cluster-name>" `
    -ExtensionName "titansftp-ext" `
    -ReleaseNamespace "titansftp-system" `
    -RestartStatefulSet
```

Parameters:

- `-SubscriptionId` (required): the subscription that contains your AKS cluster.
- `-ClusterResourceGroup` (required): the resource group of your AKS cluster.
- `-ClusterName` (required): the name of your AKS cluster.
- `-ExtensionName` (optional, default `titansftp-ext`): the installed extension name.
- `-ReleaseNamespace` (optional, default `titansftp-system`): the extension namespace.
- `-RestartStatefulSet` (optional switch): restarts the Titan pods so they re-attest immediately after the wiring is created.

> **Note:** Creating the role assignment requires the caller to have **Owner** or **User Access Administrator** on the extension scope.

### Verify Attestation Succeeded

After running the script (allow a minute for pods to re-attest), confirm attestation in the logs:

```powershell
az aks command invoke -g <your-aks-resource-group> -n <your-aks-cluster-name> --command "kubectl logs -n titansftp-system titansftp-ext-0 -c titansftp --tail=200 | grep -i 'attestation'"
```

Expect: `Azure attestation succeeded ...` and **no** `403` / `NoRegisteredProviderFound` / fail-closed stop messages.

## Update an Existing Subscription

To move to a newer Titan SFTP version, update the extension version from the offer listing / Azure Portal. Existing cluster resources stay intact; only the extension is upgraded. After an upgrade, re-run the runtime validation steps above and confirm attestation still succeeds.
