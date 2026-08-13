# Metering Failure Test Playbook

This playbook validates failure handling and recovery for Azure metering behavior in Titan SFTP.

## Test Script

`Test-Azure-Metering-Failure.ps1`

## 1) Simulate Corruption (20-hour scenario)

```powershell
powershell -ExecutionPolicy Bypass -File "..\Test-Azure-Metering-Failure.ps1" -Mode Corrupt -Namespace titansftp-system -StatefulSetName titansftp -RestartStatefulSet
```

## 2) Recover

```powershell
powershell -ExecutionPolicy Bypass -File "..\Test-Azure-Metering-Failure.ps1" -Mode Recover -Namespace titansftp-system -StatefulSetName titansftp -RestartStatefulSet
```

### Fast recovery tick (1 minute)

```powershell
powershell -ExecutionPolicy Bypass -File "..\Test-Azure-Metering-Failure.ps1" -Mode Recover -Namespace titansftp-system -StatefulSetName titansftp -RestartStatefulSet -FastRecoveryTick
```

## 3) Verify

```powershell
powershell -ExecutionPolicy Bypass -File "..\Test-Azure-Metering-Failure.ps1" -Mode Verify
```

## Operational Verification

After each mode run:

- Check pod restarts and health.
- Check rollout completion.
- Verify metering env values in the running pod.
- Capture logs and timestamps for incident correlation.

## Recommended Evidence Collection

- Command transcripts.
- StatefulSet rollout output.
- Pod event summaries.
- Metering-specific environment variables before and after recovery.
