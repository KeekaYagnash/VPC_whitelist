variable "vpc_id" {
  description = "vpc id"
  type        = string
}

variable "subnet_id" {
  description = "subnet id"
  type        = string
}

variable "subnet_id2" {
  description = "subnet id"
  type        = string
}

# variable "count" {
#   type        = number
#   description = "counter value"
# }

# variable "gateway_id" {
#   description = "igw"
#   type        = string
# }
variable "rt_name" {
  description = "name of the route table"
  type        = string
}

variable "routes" {
  description = "Takes in values for the Cidr Block and Gateway id"
  type = list(object({
    cidr_block = string
    gateway_id = string
  }))
  default = []
}
