variable "aws_region" {
  description = "AWS region where the cluster will be created"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the Kubernetes (EKS) cluster"
  type        = string
  default     = "voting-app-cluster"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.31"
}
