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


#Create route table associations
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.tf-course-rt.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}
# #creating S3 bucket
# resource "aws_s3_bucket" "tf-course-s3" {
#   bucket = "tf-course-${random_id.tf-course-rm.hex}"

#   tags = {
#     Name        = "thaw-s3"
#     Environment = "tf-course-dev"
#   }
# }

# #creating s3 bucket ownership
# resource "aws_s3_bucket_ownership_controls" "tf-course-s3-oc" {
#   bucket = aws_s3_bucket.tf-course-s3.id

#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

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

resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.tf-course-vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}


/* creating aws instance using local variable
and ami from the data block
*/
resource "aws_instance" "tf-course-ec2" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.tf-course-aws-key.key_name
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.tf-course-tls.private_key_pem
    host        = self.public_ip
  }

  # Leave the first part of the block unchanged and create our `local-exec` provisioner

  provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /tmp",
      "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
      "sudo sh /tmp/assets/setup-web.sh",
    ]
  }


  tags = {
    Name  = local.server_name
    Owner = local.team
    App   = local.application

  }
}

#To generate RAS key by using Terraform TLS
resource "tls_private_key" "tf-course-tls" {
  algorithm = "RSA"

}

#Save tls key in local file
resource "local_file" "private_key_pem" {
  content  = tls_private_key.tf-course-tls.private_key_pem
  filename = "MyAWSKey.pem"

}

#Create EC2 keypairs
resource "aws_key_pair" "tf-course-aws-key" {
  key_name   = "MyAWSKey"
  public_key = tls_private_key.tf-course-tls.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }

}

# Security Groups
resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.tf-course-vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web-${terraform.workspace}"
  vpc_id      = aws_vpc.tf-course-vpc.id
  description = "Web Traffic"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.tf-course-vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}