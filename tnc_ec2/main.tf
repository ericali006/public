locals {
  vpc_cidr = "10.20.0.0/27"
  azs = ["us-west-2a", "us-west-2b"]
}

# Generate TLS private key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create an AWS key pair from the generated private key
resource "aws_key_pair" "keypair" {
  key_name   = "tnc_keypair"  
  public_key = tls_private_key.key.public_key_openssh
}

# Store the private key in AWS Secrets Manager
resource "aws_secretsmanager_secret" "secret_key" {
  name_prefix = "tnc_keypair"
  tags = {
    Name = "tnc_keypair"
  }
}

resource "aws_secretsmanager_secret_version" "secret_key_value" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = tls_private_key.key.private_key_pem
}

# Fetch the secret version containing the private key
data "aws_secretsmanager_secret_version" "ssh_private_key" {
  depends_on = [aws_secretsmanager_secret.secret_key, aws_secretsmanager_secret_version.secret_key_value]
  secret_id = aws_secretsmanager_secret.secret_key.id
}

# Write the private key to a local file
resource "local_file" "ssh_key" {
  content  = data.aws_secretsmanager_secret_version.ssh_private_key.secret_string
  filename = "${path.module}/tnc_key.pem"
}

# VPC Module
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "tnc_vpc"
  cidr = local.vpc_cidr

  azs             = local.azs
  public_subnets = ["10.20.0.0/28"]
  private_subnets = ["10.20.0.16/28"]
  
  create_igw = false

  tags = {
    Name = "tnc_vpc"
  }
}

# Security Group Module
module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.1.2"

  name        = "tnc_sg"
  description = "Security group for tnc_ec2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = "192.112.66.25/32"
    }
  ]
  egress_rules = ["all-all"]
  tags = {
    Name = "tnc_sg"
  }
}

# EC2 Instance
resource "aws_instance" "ec2" {
  depends_on = [
    aws_key_pair.keypair,
    aws_secretsmanager_secret.secret_key
    ]

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.keypair.key_name
  availability_zone           = element(module.vpc.azs, 0)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = false

  provisioner "file" {
    source      = "file/apache2-packages.tar.gz"
    destination = "/home/ubuntu/apache2-packages.tar.gz"
       
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${local_file.ssh_key.filename}")
      host        = aws_instance.ec2.private_ip
    }
  }

  provisioner "remote-exec" {
    inline = [
      "gzip -d apache2-packages.tar.gz",
      "tar xvf apache2-packages.tar",
      "cd apache2-packages",
      "sudo dpkg -i *.deb",
      "sudo /usr/local/apache2/bin/apachectl -k start",
      "echo 'Hello, TNC!' | sudo tee /var/www/html/index.html",
      "sudo chown -R www-data:www-data /var/www/html/"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${local_file.ssh_key.filename}")
      host        = aws_instance.ec2.private_ip
    }
  }

  tags = {
    Name = "tnc_apache"
  }
}

output "instance_ip" {
  value = aws_instance.ec2.private_ip
}
