variable "vpc_id" {
  description = "This is the vpc id for the Level Finance VPC - Whitelisting"
  type        = string
}

variable "subnets_cidr" {
  description = "This is the cidr block for the subnet in Level Finance VPC - Whitelisting"
  type        = list(string)
}

variable "availability_zone" {
  description = "This is the availability zone in a region - Whitelisting"
  type        = list(string)
}

variable "subnet_count" {
  description = "This is the number of subnets to be provisioned in the Level Finance VPC - Whitelisting"
  type        = number
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = list(string)
}
