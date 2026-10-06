# Titan SFTP Azure Container Offer Getting Started Guide

The Titan SFTP **Azure Container Offer** installs Titan SFTP as an AKS extension on your own Azure Kubernetes Service (AKS) cluster. Unlike the fully managed AKS application, the container offer deploys the Titan SFTP extension into a cluster that you own and manage, giving you direct control over the cluster, node pools, and networking.

For detailed steps on how to subscribe, deploy, and update the offer please read the [Buyer subscription and update guide](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/buyer-subscription-and-update.md).

After the extension is installed you can consult the [AKS operations cookbook](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/aks-operations-cookbook.md) for a handy guide of commands that may be useful.

## Important: One-Time Workload Identity Bootstrap

The Titan SFTP extension validates its Azure Marketplace entitlement at startup (attestation). To do this, the extension's managed identity must be able to read its own extension resource in Azure. This requires two pieces of Azure infrastructure wiring that are **not** always created automatically when the extension is installed:

1. A **Federated Identity Credential (FIC)** on the extension's User Assigned Managed Identity that trusts your cluster OIDC issuer and the extension service account.
2. A **Reader role assignment** on the extension resource so the attestation read call returns `200` instead of `403`.

If either is missing, non-LAS (non-license-authority) servers **fail-closed** (they will not start normally). To create this wiring, run the one-time [`bootstrap-workload-identity.ps1`](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/bootstrap-workload-identity.ps1) script after the extension is installed. See the [Buyer subscription and update guide](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/buyer-subscription-and-update.md) for full details on why this is required and how to run it.

The script is idempotent (safe to re-run) and only creates what is missing.
