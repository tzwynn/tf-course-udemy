variable "variable_sub_cidr" {
  description = "CIDR for the tf-course-subnet"
  type        = string
  default     = "10.0.202.0/24"

}

variable "variable_sub_az" {
  description = "AZ for tf-course-subnet"
  type        = string
  default     = "eu-west-2a" #terraform will apply default value if we don't provide variable value

}

variable "variable_sub_auto_ip" {
  description = "Auto IP for tf-course-subnet"
  type        = bool
  default     = true

}

variable "environment" {
  description = "Environment for deployment"
  type        = string
  default     = "dev"

}