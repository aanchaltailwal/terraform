terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.16"
    }
  }

  backend "s3" {
 bucket = "aanchal-tf-bucket"
 key    = "tfstate.json"
 region = "eu-north-1"
 # optional: dynamodb_table = "<table-name>"
}

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "eu-north-1"
}

resource "aws_security_group" "sg_web" {
  name = "${var.resource_alias}-${var.env}-sg"
    vpc_id      = module.app_vpc.vpc_id

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Env       = var.env
    Terraform = "true"
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "aanchal-tf-bucket"

  tags = {
    Name      = "${var.resource_alias}-bucket"
    Env       = var.env
    Terraform = "true"
  }
}

resource "aws_instance" "app_server" {
  ami           = "ami-0989fb15ce71ba39e"
  instance_type = var.env == "prod" ? "t3.micro" : "t3.nano"
  key_name      = "Aanchal-key-upes"
  vpc_security_group_ids = [aws_security_group.sg_web.id]
    subnet_id              = module.app_vpc.public_subnets[0]

  tags = {
    Name      = "aanchal-terraform-${var.env}"
    Terraform = "true"


  depends_on = [
    aws_s3_bucket.data_bucket
  ]
}

module "app_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "${var.resource_alias}-vpc"
  cidr = var.vpc_cidr

  azs             = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  private_subnets = var.vpc_private_subnets
  public_subnets  = var.vpc_public_subnets

  enable_nat_gateway = false

  tags = {
    Name        = "${var.resource_alias}-vpc"
    Env         = var.env
    Terraform   = true
  }
}