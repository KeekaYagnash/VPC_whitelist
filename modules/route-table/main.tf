resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  dynamic "route" {
    for_each = var.routes
    content {
      cidr_block = route.value.cidr_block
      gateway_id = route.value.gateway_id
    }
  }
  # route {
  #   cidr_block = "0.0.0.0/0"
  #   gateway_id = var.gateway_id
  # }

  tags = {
    Name        = var.rt_name,
    owner       = "disraptor",
    environment = "prod",
    service     = "Level-Finance",
  type = "application" }
}

resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = var.subnet_id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = var.subnet_id2
  route_table_id = aws_route_table.public_route_table.id
}
