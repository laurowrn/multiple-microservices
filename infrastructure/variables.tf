variable "instance_name" {
  description = "Value of the EC2 instance's Name tag."
  type        = string
  default     = "learn-terraform"
}

variable "instance_type" {
  description = "The EC@ instance's type."
  type        = string
  default     = "t2.small"
}

variable "user_service_image_uri" {
  description = "AWS URI of the user-service container image"
  type        = string
  default     = "390844743452.dkr.ecr.us-east-1.amazonaws.com/user-service:latest"
}

variable "product_service_image_uri" {
  description = "AWS URI of the product-service container image"
  type        = string
  default     = "390844743452.dkr.ecr.us-east-1.amazonaws.com/product-service:latest"
}

variable "order_service_image_uri" {
  description = "AWS URI of the order-service container image"
  type        = string
  default     = "390844743452.dkr.ecr.us-east-1.amazonaws.com/order-service:latest"
}

variable "ecs_ec2_cluster_ami_id" {
  description = "AWS AMI id of the ECS EC2 image"
  type        = string
  default     = "ami-0c3e8df62015275ea"
}

variable "key_name" {
  description = "Keypair name"
  type        = string
  default     = "ecs_keypair"
}

variable "vpc_zone_identifier" {
  description = "VPC Subnet zone identifier"
  type        = string
  default     = "subnet-075198aa059faccc0"
}

variable "vpc_id" {
  type    = string
  default = "vpc-0b719f28686296b26"
}

variable "vpc_ipv4_cidr" {
  type    = string
  default = "172.31.0.0/16"
}

variable "subnet_ids" {
  type    = list(string)
  default = ["subnet-075198aa059faccc0", "subnet-0b4ae3b006de78561"]
}