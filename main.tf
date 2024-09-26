terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "spring-boot-server" {
  instance_type = "t2.micro"
  ami = "ami-033067239f2d2bfbc"
  key_name = "dh-sa-04-us-west-2"
  security_groups = [ aws_security_group.allow-ssh.name ]
  iam_instance_profile = aws_iam_instance_profile.allows-s3-interaction.name

  tags = {
    "Name" = "dennis-tf-checkpoint-server"
  }
}

resource "aws_security_group" "allow-ssh" {
  
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.allow-ssh.id

  ip_protocol = "tcp"
  from_port = 22
  to_port = 22
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow-all-traffic-outbound" {
  security_group_id = aws_security_group.allow-ssh.id

  ip_protocol = "-1"
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_iam_instance_profile" "allows-s3-interaction" {
  
}