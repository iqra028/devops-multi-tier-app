variable "aws_region" {
  default = "us-east-1"
}

variable "key_name" {
  default = "devops-key"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "ami_id" {
  # Ubuntu 22.04 LTS us-east-1 (free tier eligible)
  default = "ami-0c7217cdde317cfec"
}
