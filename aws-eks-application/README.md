# Titan SFTP AWS EKS Getting Started Guide

This folder contains buyer-facing documentation for deploying and operating Titan SFTP on AWS EKS from AWS Marketplace.

## Documents Included

- [Buyer subscription and update guide](https://github.com/southrivertech/titansftp.pub/blob/main/aws-eks-application/buyer-subscription-and-update.md) - stack launch flow, required inputs, and update guidance.
- [EKS operations cookbook](https://github.com/southrivertech/titansftp.pub/blob/main/aws-eks-application/eks-operations-cookbook.md) - practical AWS CLI and `kubectl` commands for post-deployment operations.

## Buyer Quick Start

1. Open AWS Marketplace and launch the Titan SFTP container offer.
2. Create the CloudFormation stack with your required parameters.
3. After stack completion, connect to EKS and get service external endpoints.
4. Open Titan Admin UI on `https://<external-ip>:41443`.
5. Use the cookbook for scaling, health checks, and troubleshooting.
