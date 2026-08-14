# Metering Failure Test Playbook

This buyer-facing playbook provides non-invasive checks for metering-related runtime settings.

## Scope

This public documentation does not include internal publisher test scripts.

## 1) Verify Metering Environment Variables

```powershell
kubectl exec -n titansftp-system <PodName> -- printenv | Select-String "CloudSettings__Metering"
```

Check that expected values are present and valid for the running environment.

## 2) Verify Rollout Health

```powershell
kubectl rollout status statefulset/titansftp -n titansftp-system
kubectl get pods -n titansftp-system -w
```

## 3) Optional Metering Interval Update (Validation Scenario)

```powershell
kubectl set env statefulset/titansftp -n titansftp-system CloudSettings__Metering__IntervalMinutes=60
```

After update, re-run rollout and environment checks.

## Recommended Evidence Collection

- Output from environment variable checks.
- StatefulSet rollout status output.
- Pod readiness and restart counts.
- Timestamped notes for any observed transient errors.
