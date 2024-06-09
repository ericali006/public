# Terraform AWS Infrastructure Setup

This project contains Terraform code to set up an AWS infrastructure, including a VPC, security groups, and an EC2 instance running an Apache web server. The web server serves a static HTML page with the message 'Hello, TNC!'.

## Overview

This Terraform configuration includes the following components:

### VPC and Subnet Configuration
- Creates a VPC with CIDR block 10.20.0.0/27.
- Sets up public and private subnets within specified availability zones.

### Key Management
- Generates a TLS private key.
- Creates an AWS key pair from the generated private key.
- Stores the private key in AWS Secrets Manager.

### Security Groups
- Configures security groups to allow HTTP traffic on port 80 from anywhere and SSH access on port 22 from a specific IP address (192.112.66.25/32).

### EC2 Instance
- Launches an EC2 instance with latest Ubuntu OS.
- Configures the instance to run an Apache web server, serving a static HTML page with the message 'Hello, TNC!'.
- Ensures the Apache web server starts automatically after the instance is provisioned.

### Outputs
- Outputs the private IP address of the EC2 instance.

## Detailed Configuration

### VPC Module
- Utilizes the `terraform-aws-modules/vpc/aws` module to create a VPC and subnets.
- Configures subnets with CIDR blocks 10.20.0.0/28 (public) and 10.20.0.16/28 (private).

### Key Pair and Secrets Management
- Generates a 4096-bit RSA private key using Terraform's `tls` provider.
- Creates an AWS key pair using the generated key.
- Stores the private key securely in AWS Secrets Manager and writes it to a local file.

### Security Group
- Uses the `terraform-aws-modules/security-group/aws` module to create a security group.
- Allows HTTP access on port 80 from any IP and SSH access on port 22 from a specific IP.

### EC2 Instance Provisioning
- Uses the generated key pair for SSH access.
- Configures the EC2 instance with an Apache web server.
- Deploys a static HTML page saying 'Hello, TNC!'.

## Usage

### Prerequisites
- Terraform installed
- AWS credentials configured

### Steps

1. Clone the repository:
    ```bash
    git clone git@github.com:ericali006/public.git
    cd public/tnc_ec2
    ```

2. Initialize the Terraform configuration:
    ```bash
    terraform init
    ```

3. Apply the Terraform configuration:
    ```bash
    terraform apply
    ```

4. Access the EC2 instance:
    - The private IP address of the EC2 instance will be output after a successful `terraform apply`.
    - Use the private key stored in the `tnc_key.pem` file to SSH into the instance:
    ```bash
    ssh -i tnc_key.pem ubuntu@<private_ip>
    ```

5. Verify the Apache web server:
    - Access the static HTML page served by the Apache web server:
    ```bash
    curl http://<private_ip>
    ```

## Notes
- SSH access is restricted to a specific IP for enhanced security.
- The private key is securely managed using AWS Secrets Manager to ensure compliance with security best practices.

## License
This project is licensed under the MIT License. See the LICENSE file for details.
