terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

resource "tls_private_key" "myapp_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "myapp_key" {
  key_name   = "posweb-myapp-2026"
  public_key = tls_private_key.myapp_key.public_key_openssh
}

resource "local_sensitive_file" "myapp_private_key" {
  content         = tls_private_key.myapp_key.private_key_pem
  filename        = "${path.module}/posweb-myapp-2026.pem"
  file_permission = "0600"
}
