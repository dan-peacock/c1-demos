provider "aws" {
  region = "eu-west-1"
}

data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}


resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_default_vpc.default.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "vault" {
  ami = var.ami
  instance_type   = var.instance_type
  key_name        = var.ssh_keyname
  security_groups = [aws_default_security_group.default.name]
  user_data = templatefile("${path.module}/config/install.sh.tpl", {vault_ent_license = var.vault_ent_license})
  tags = {
    Name = "Vault ENT with SoftHSM"
  }
}

output "connection_string" {
  value = [ "ssh -l ubuntu ${aws_instance.vault.public_ip}"]
}

output "vault_ui" {
  value = [ "http://${aws_instance.vault.public_ip}:8200"]
}