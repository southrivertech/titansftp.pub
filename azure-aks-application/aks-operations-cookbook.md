# Titan AKS Operations Cookbook

A collection of sample commands that can be used to monitor and configure your AKS cluster. Please replace 'managed-resource-group' with your AKS resource group, not the parent azure resouce group. Also use the proper aks-cluster-name that was used when you created the Titan AKS Cluster from the Marketplace. One of the most useful commands will be to discover the external IP address of your nodes. 

## Connect to AKS

```powershell
az aks get-credentials --resource-group <managed-resource-group> --name <aks-cluster-name> --overwrite-existing
```

Example:

```powershell
az aks get-credentials --resource-group mrg-tn-sftp-ent-managed-a-20260813115444 --name titansftp-aks --overwrite-existing
```

## Service and External IP Discovery

```powershell
kubectl get svc -A
```

Use this to identify externally exposed services and public endpoints.


## Rollout and Pod Health

```powershell
kubectl rollout status statefulset/titansftp -n titansftp-system
kubectl get pods -n titansftp-system -w
```


## Locate SQLite Databases in Pod

```powershell
kubectl exec -it titansftp-0 -n titansftp-system -- sh
find / -type f \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \) 2>/dev/null
```

Typical result:

```text
/var/southriver/srxserver/database/lasdb.db
/var/southriver/srxserver/database/srxdbDB2112AD555500000000100000000001.db
```

## Copy SQLite Database to Local Machine

```powershell
kubectl cp titansftp-system/titansftp-0:/var/southriver/srxserver/database/lasdb.db .\lasdb.db
```

Replace `titansftp-0` with `<PodName>` if your pod name is different.

If run from `C:\Windows\System32`, the file lands at:

`C:\Windows\System32\lasdb.db`

## How to watch rollout

```powershell
kubectl rollout status statefulset/titansftp -n titansftp-system
kubectl get pods -n titansftp-system -w
```

For pod-specific commands, replace pod name with `<PodName>`.

## Safe Runtime Operations

- Prefer small, validated changes and confirm rollout after each change.
- Capture current values before changes.
- Validate rollout status after every config or image change.
- Keep a rollback image tag ready before production updates.
