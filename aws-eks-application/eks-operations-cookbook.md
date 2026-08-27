# Titan EKS Operations Cookbook

Buyer-focused command reference for operating Titan SFTP on AWS EKS after stack deployment.

## 1) Configure AWS CLI Profile

```powershell
aws configure
aws sts get-caller-identity
```

Set profile in session (optional):

```powershell
$env:AWS_PROFILE = "<buyer-profile-name>"
```

## 2) Connect `kubectl` to EKS Cluster

```powershell
aws eks update-kubeconfig --region <region> --name <eks-cluster-name>
kubectl get nodes
```

## 3) Discover External Endpoints

```powershell
kubectl get svc -A
```

Look for `EXTERNAL-IP` values. Initial provisioning may take a few minutes.

## 4) Workload Health Checks

```powershell
kubectl get pods -n titansftp-system -o wide
kubectl rollout status deployment/titansftp-titansftp -n titansftp-system
```

## 5) EKS Node Group Scaling (CLI)

### List node groups

```powershell
aws eks list-nodegroups --cluster-name <eks-cluster-name> --region <region>
```

### Scale node group

```powershell
aws eks update-nodegroup-config --cluster-name <eks-cluster-name> --nodegroup-name <nodegroup-name> --scaling-config minSize=<min>,maxSize=<max>,desiredSize=<desired> --region <region>
```

### Validate post-scale state

```powershell
kubectl get nodes
kubectl get pods -n titansftp-system -o wide
```

## 6) Read Metering-Related Environment Variables

```powershell
$POD = kubectl get pod -n titansftp-system -l app=titansftp -o jsonpath='{.items[0].metadata.name}'
kubectl exec -n titansftp-system $POD -- printenv | Select-String -Pattern '^CloudSettings'
```

## 7) Watch Logs for Runtime/Metering Signals

```powershell
kubectl logs -n titansftp-system deploy/titansftp-titansftp -f --since=10m
```

Metering-focused filter:

```powershell
kubectl logs -n titansftp-system deploy/titansftp-titansftp -f --since=30m | Select-String -Pattern "meter|marketplace|RegisterUsage|MeterUsage|NxAwsMarketplaceMeteringClient|NxMeteringLedger"
```

## 8) Optional: Verify Marketplace MeterUsage Event Activity

```powershell
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=MeterUsage --max-results 100 --region <region> --query "Events[].{Time:EventTime,User:Username,EventId:EventId}" --output table
```

## 9) SQLite Discovery and Copy (Advanced Support)

Find SQLite files:

```powershell
kubectl exec -it titansftp-titansftp-0 -n titansftp-system -- sh
find / -type f \( -name "*.db" -o -name "*.sqlite" -o -name "*.sqlite3" \) 2>/dev/null
```

Copy DB file to local machine:

```powershell
kubectl cp titansftp-system/titansftp-titansftp-0:/var/southriver/srxserver/database/lasdb.db .\lasdb.db
```

## 10) Safe Operations Guidance

- Make one change at a time and validate.
- Prefer stack update flow for version changes.
- Keep external SQL and shared storage enabled for better data durability.
- Escalate to support if stack update fails or metering events do not appear.
