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
  instance_type        = "t2.micro"
  ami                  = "ami-033067239f2d2bfbc"
  key_name             = "dh-sa-04-us-west-2"
  security_groups = [aws_security_group.allow-ssh-spring-boot.name]
  iam_instance_profile = aws_iam_instance_profile.allows-s3-interaction.name
  user_data = templatefile("install-launch-spring-boot.tftpl", {
    name_bucket = aws_s3_bucket.jar-staging.bucket
    name_file   = aws_s3_object.jar-archive.key
  })
  user_data_replace_on_change = true

  # lifecycle {
  #   replace_triggered_by = [ aws_s3_object.jar-archive.source_hash ]
  # }

  tags = {
    "Name" = "dennis-tf-checkpoint-server"
  }
}

resource "aws_security_group" "allow-ssh-spring-boot" {
}

resource "aws_vpc_security_group_ingress_rule" "allow-ssh" {
  security_group_id = aws_security_group.allow-ssh-spring-boot.id

  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "allow-spring-boot" {
  security_group_id = aws_security_group.allow-ssh-spring-boot.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "allow-all-traffic-outbound" {
  security_group_id = aws_security_group.allow-ssh-spring-boot.id

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_iam_instance_profile" "allows-s3-interaction" {
  role = aws_iam_role.allows-s3-interaction.name
}

resource "aws_iam_role" "allows-s3-interaction" {
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy" "allows-s3-interaction" {
  role = aws_iam_role.allows-s3-interaction.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
        ]
        Effect   = "Allow"
        Resource = aws_s3_object.jar-archive.arn
      },
    ]
  })
}

resource "aws_s3_bucket" "jar-staging" {
}

variable "path-to-jar" {
  default = "build/libs/g-hello-0.0.1-SNAPSHOT.jar"
}

resource "aws_s3_object" "jar-archive" {
  bucket = aws_s3_bucket.jar-staging.bucket
  key    = "g-hello.jar"
  source = var.path-to-jar

  source_hash = filemd5(var.path-to-jar)
}