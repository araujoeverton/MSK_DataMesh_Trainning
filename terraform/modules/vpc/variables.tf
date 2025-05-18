variable "region" {
  description = "Região da AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para a VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidrs" {
  description = "Lista de CIDRs para as subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "availability_zones" {
  description = "Lista de availability zones para usar"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ingress_ports" {
  description = "Lista de portas de entrada para o security group"
  type        = list(number)
  default     = [22, 80, 443]
}