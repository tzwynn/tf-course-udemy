output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.tf-course-vpc.id

}

output "public_url" {
  description = "Public URL for web server"
  value       = "https://${aws_instance.tf-course-ec2.private_ip}:8080/index.html"

}

output "vpc_information" {
  description = "VPC Info"
  value       = "Your ${aws_vpc.tf-course-vpc.tags.Environment} VPC has an ID of ${aws_vpc.tf-course-vpc.id}"

}