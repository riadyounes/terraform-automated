terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.17.1"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "user-terraform"
  region  = "us-east-1"
}

resource "aws_security_group" "ssh-access" {
  tags = {
    "Name" = "SSH Access"
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    description = "SSH"
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "backend-access" {
  tags = {
    "Name" = "Backend Access"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db-access" {
  tags = {
    "Name" = "DB Access"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.backend-access.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

module "vm_setup" {
  source        = "./modules/vm_setup"
  instance_ami  = "ami-005de95e8ff495156"
  instance_type = "t2.micro"

  instance_security_group = [
    aws_security_group.ssh-access.id,
    aws_security_group.backend-access.id
  ]

}

resource "aws_db_instance" "database" {
  allocated_storage       = 20
  engine                  = "postgres"
  engine_version          = "13.4"
  instance_class          = "db.t3.micro"
  db_name                 = "banco"
  username                = "postgres"
  password                = "password"
  parameter_group_name    = "default.postgres13"
  skip_final_snapshot     = true
  backup_retention_period = 0

  vpc_security_group_ids = [
    aws_security_group.ssh-access.id,
    aws_security_group.db-access.id
  ]
}
