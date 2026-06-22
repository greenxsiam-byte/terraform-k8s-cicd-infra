variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-southeast-7"
}

variable "instance_type_jenkins" {
  description = "Instance type for the Jenkins server"
  type        = string
  default     = "t3.small"
}

variable "instance_type_control_plane" {
  description = "Instance type for the Kubernetes control plane"
  type        = string
  default     = "t3.small"
}

variable "instance_type_worker" {
  description = "Instance type for the Kubernetes worker node"
  type        = string
  default     = "t3.micro"
}
