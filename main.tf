#local variable
locals {
  team        = "api_mgmt_dev"
  application = "corp_api"
  server_name = "ec2-${var.environment}-api-${var.variable_sub_az}"
}

#creating VPC
resource "aws_vpc" "tf-course-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name        = "thaw-vpc"
    Region      = data.aws_region.vpc-region.name
    Environment = "tf-course-dev-vpc"
  }
}

#creating Internet gateway
resource "aws_internet_gateway" "tf-course-ig" {
  vpc_id = aws_vpc.tf-course-vpc.id

  tags = {
    Name = "thaw-ig"
  }
}

#creating router table
resource "aws_route_table" "tf-course-rt" {
  vpc_id = aws_vpc.tf-course-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-course-ig.id
  }

  tags = {
    Name = "thaw-rt"
  }
}

#creating S3 bucket
resource "aws_s3_bucket" "tf-course-s3" {
  bucket = "tf-course-${random_id.tf-course-rm.hex}"

  tags = {
    Name        = "thaw-s3"
    Environment = "tf-course-dev"
  }
}

#creating s3 bucket ownership
resource "aws_s3_bucket_ownership_controls" "tf-course-s3-oc" {
  bucket = aws_s3_bucket.tf-course-s3.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

#testing random id resourse
resource "random_id" "tf-course-rm" {
  byte_length = 16
}

#creating vpc subnet
resource "aws_subnet" "tf-course-subnet" {
  vpc_id                  = aws_vpc.tf-course-vpc.id
  cidr_block              = var.variable_sub_cidr
  availability_zone       = var.variable_sub_az
  map_public_ip_on_launch = var.variable_sub_auto_ip

  tags = {
    Name      = "sub-variables-${var.variable_sub_az}"
    Terraform = "true"
  }
}

/* creating aws instance using local variable
and ami from the data block
*/
resource "aws_instance" "tf-course-ec2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"


  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application

  }
}