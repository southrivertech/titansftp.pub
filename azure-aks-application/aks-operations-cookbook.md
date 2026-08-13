# AKS Operations Cookbook

Use this command reference for live operations and support scenarios.

## Connect to AKS

```powershell
az aks get-credentials --resource-group <managed-resource-group> --name <aks-cluster-name> --overwrite-existing
```

Example:

```powershell
az aks get-credentials --resource-group mrg-tn-sftp-ent-managed-a-20260813115444 --name titansftp-aks --overwrite-existing
```

## Service and IP Discovery

```powershell
kubectl get svc -A
```

Use this to identify externally exposed services and public endpoints.

## Find External IP Address of Container Pods

Run these commands in sequence:

```powershell
az aks get-credentials --resource-group mrg-tn-sftp-ent-managed-a-20260813115444 --name titansftp-aks --overwrite-existing
kubectl get svc -A
```

## Rollout and Pod Health

```powershell
kubectl rollout status statefulset/titansftp -n titansftp-system
kubectl get pods -n titansftp-system -w
```

## Environment Variable Inspection and Update

### Read metering env values from pod

```powershell
kubectl exec -n titansftp-system titansftp-0 -- printenv | Select-String "CloudSettings__Metering"
```

Replace `titansftp-0` with `<PodName>` where needed.

## Set Env Variables for AKS

```powershell
kubectl set env statefulset/titansftp -n titansftp-system CloudSettings__Metering__Enabled=false
```

### Update metering env settings

```powershell
kubectl set env statefulset/titansftp -n titansftp-system CloudSettings__Metering__Enabled=false
kubectl set env statefulset/titansftp -n titansftp-system CloudSettings__Metering__IntervalMinutes=60
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

- Prefer declarative updates through approved scripts.
- Capture current values before changes.
- Validate rollout status after every config or image change.
- Keep a rollback image tag ready before production updates.
