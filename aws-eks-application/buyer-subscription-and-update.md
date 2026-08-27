# Buyer Subscription and Update Guide (AWS EKS)

This guide explains how buyers launch Titan SFTP from AWS Marketplace, validate deployment, and update stack versions safely.

## Buyer Marketplace Entry

Use these exact UI steps from AWS Marketplace:

1. Sign in to AWS Console and open **AWS Marketplace**.
2. Go to **Manage subscriptions** and locate the Titan SFTP product.
3. From the product action menu, click **Launch**.
4. On the launch page:
   - choose **EKS** as the service
   - confirm the required product **Version**
5. In the **Deployment templates** panel on the right, click:
   - **Quick Launch - Create EKS and Deploy Titan SFTP**
6. This opens CloudFormation with the correct template URL prefilled for stack creation.

If you do not see **Deployment templates**, scroll down on the launch page and check the right-side card area.

## Stack Creation Flow (Buyer)

1. Open CloudFormation from the **Quick Launch - Create EKS and Deploy Titan SFTP** link.
2. Enter stack name and required parameters.
3. Provide IAM principal ARN required for cluster access setup.
4. Review required capability acknowledgments.
5. Create the stack and wait for `CREATE_COMPLETE`.

## Key Buyer Inputs During Stack Creation

- EKS cluster settings (region, cluster name, node count, node type).
- Titan app settings (admin credentials, image/chart version when exposed).
- Storage/database options when available.
- SQL data retention policy when available:
  - `Snapshot` (recommended for data retention)
  - `Delete` (for full cleanup in test environments)

## Connect to EKS After Stack Deployment

Use commands from the operations cookbook to:

- configure AWS CLI profile
- update kubeconfig for the cluster
- verify nodes/pods/services
- discover external service endpoints

See: [EKS operations cookbook](https://github.com/southrivertech/titansftp.pub/blob/main/aws-eks-application/eks-operations-cookbook.md)

## Access Titan Admin UI

1. Discover external IP using `kubectl get svc -A`.
2. Open browser to `https://<external-ip>:41443`.
3. Accept initial certificate warning (self-signed cert during initial setup).
4. Accept EULA and login with the admin credentials provided during stack creation.

## Update Existing Buyer Stack

When a new version is published:

1. Open existing CloudFormation stack.
2. Choose **Update stack**.
3. Select updated template/version as instructed by offer release notes.
4. Update version-related parameters (image/chart) if exposed.
5. Execute update and monitor events until `UPDATE_COMPLETE`.

## Data Persistence Notes for Buyers

- For external SQL/shared storage deployments, updates are generally safe for retained data.
- For pod-local-only state, data durability risk is higher during pod replacement updates.
- Always follow seller guidance for production-grade external persistence setup.

## Buyer Validation Checklist

- Stack reaches `CREATE_COMPLETE` (or `UPDATE_COMPLETE`).
- `kubectl get pods -n titansftp-system` shows healthy workloads.
- External service endpoint is reachable.
- Titan Admin login works on port `41443`.
