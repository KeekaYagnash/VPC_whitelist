# Subnets code
resource "aws_subnet" "public_subnet" {
  count             = var.subnet_count
  vpc_id            = var.vpc_id
  cidr_block        = var.subnets_cidr[count.index]
  availability_zone = var.availability_zone[count.index]


  tags = {
    Name        = var.subnet_name[count.index]
    owner       = "disraptor",
    environment = "prod",
    service     = "marketplace",
    type        = "whitelisting"
  }

  map_public_ip_on_launch = true
}
