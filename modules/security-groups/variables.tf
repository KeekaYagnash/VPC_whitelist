variable "sg_name" {
  description = "The name of the security group"
  type        = string
}

variable "description" {
  description = "This is the description for the security group"
  type        = string
}

variable "service" {
  description = "This is the name of the Services"
  type        = string
}

variable "vpc_id" {
  description = "Value for the vpc_id"
  type        = string
}

# variable "sg_cidr_block" {
#   description = "This is the Cidr block"
# }


variable "ingress" {
  description = "This is a Ingress rule for Inbound Traffic"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}

variable "egress" {
  description = "This is a Egress rule for Outbound Traffic"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
}
