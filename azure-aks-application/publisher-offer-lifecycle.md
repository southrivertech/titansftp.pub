# Publisher Offer Lifecycle

This guide covers how to create and update the Azure Marketplace managed application plan for Titan SFTP.

## 1) Deployment Package Structure

The package uploaded to Partner Center should include only required deployment artifacts:

```text
package.zip
|-- mainTemplate.json
`-- createUiDefinition.json
```

For container-centric implementations, supporting assets can live in your source tree, but the upload package should stay minimal unless explicitly required by your template.

## 2) What Each Required File Does

- `mainTemplate.json`: ARM template that provisions required Azure resources.
- `createUiDefinition.json`: Azure Portal deployment UI, parameter constraints, and user choices.

## 3) Build the Managed App Package

Packaging script location:

`ServerCore/Source/Helm Charts/Container Offer/AzureManagedAPP/titansftp-managed-app/package-managed-app.ps1`

Primary build flow script:

`ServerCore/Source/Helm Charts/Container Offer/AzureManagedAPP/titansftp-managed-app/build-and-package.ps1`

Before execution, update `SourceImage` to the new version in `build-and-package.ps1`.

### ZIP only (no ACR import)

```powershell
powershell -ExecutionPolicy Bypass -File "..\Srt.NextGen\ServerCore\Source\Helm Charts\Container Offer\AzureManagedAPP\titansftp-managed-app\build-and-package.ps1" -Version "1.0.24" -SkipImageImport -SkipAnonymousPull -MeteringPlanId "payg-custom-metered"
```

### Full flow (import image + build ZIP)

```powershell
powershell -ExecutionPolicy Bypass -File "..\Srt.NextGen\ServerCore\Source\Helm Charts\Container Offer\AzureManagedAPP\titansftp-managed-app\build-and-package.ps1" -Version "1.0.24" -DockerHubUser "rohitsrt" -DockerHubPassword "<DockerHubPassword>" -MeteringPlanId "payg-custom-metered"
```

## 4) Upload to Partner Center

In the managed application plan:

1. Open **Technical configuration**.
2. Go to **Package details**.
3. Upload the generated ZIP.
4. Save and submit for publish.

## 5) Critical Versioning Rule

Keep ZIP version and container image version aligned.  
If package version and ACR image tag diverge, deployment can fail.

## 6) Publisher Management and Customer Access

Recommended model for Titan SFTP current architecture:

- Disable publisher management access.
- Enable full customer access.

Reasoning:

- Metering is emitted by Titan SFTP itself.
- No separate publisher-managed metering service is required in customer subscription.

## 7) Legal Terms and Commercial Readiness Checklist

- Terms and privacy links are updated.
- Metering dimensions/plans are verified.
- Technical configuration package is uploaded.
- Test purchase completed in a validation subscription.
- Release notes prepared for buyer-facing changes.
