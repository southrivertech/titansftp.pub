# Titan SFTP Azure Container Offer Operations Cookbook

A collection of sample commands that can be used to monitor and operate the Titan SFTP extension on your AKS cluster. Replace `<your-aks-resource-group>` and `<your-aks-cluster-name>` with the resource group and name of the AKS cluster where the extension is installed. The default extension namespace is `titansftp-system` and the default pod name is `titansftp-ext-0`.

## Connect to AKS

```powershell
az aks get-credentials --resource-group <your-aks-resource-group> --name <your-aks-cluster-name> --overwrite-existing
```

## Check Pods and Services

```powershell
kubectl get pods -n titansftp-system
kubectl get svc -n titansftp-system -o wide
```

## Discover the External IP (Single Command via AKS Run)

If you prefer not to fetch credentials locally, you can run the check directly against the cluster. This lists services, pods, and the admin-init logs in one call:

```powershell
az aks command invoke -g <your-aks-resource-group> -n <your-aks-cluster-name> --command "kubectl get svc -n titansftp-system -o wide && echo --- && kubectl get pods -n titansftp-system && echo --- && kubectl logs -n titansftp-system -l component=init-admin --tail=50"
```

Use the external IP of the load-balanced service to reach the Titan SFTP Administrator web UI.

## Check Attestation Status

```powershell
az aks command invoke -g <your-aks-resource-group> -n <your-aks-cluster-name> --command "kubectl logs -n titansftp-system titansftp-ext-0 -c titansftp --tail=200 | grep -i 'attestation'"
```

Expect `Azure attestation succeeded ...`. If you see `unable to get ARM token` or `403`, run the [`bootstrap-workload-identity.ps1`](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/bootstrap-workload-identity.ps1) script - see the [Buyer subscription and update guide](https://github.com/southrivertech/titansftp.pub/blob/main/azure-aks-container/buyer-subscription-and-update.md).

## Rollout and Pod Health

```powershell
kubectl rollout status statefulset/titansftp-ext -n titansftp-system
kubectl get pods -n titansftp-system -w
```

## Restart the Extension Pods (Force Re-Attestation)

```powershell
az aks command invoke -g <your-aks-resource-group> -n <your-aks-cluster-name> --command "kubectl rollout restart statefulset/titansftp-ext -n titansftp-system"
```

## Safe Runtime Operations

- Prefer small, validated changes and confirm rollout after each change.
- Capture current values before changes.
- Validate rollout status after every config or image change.
- Keep a rollback version ready before production updates.
