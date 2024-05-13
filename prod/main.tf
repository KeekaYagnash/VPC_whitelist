locals {
  dynamodb_lock_table = "disraptor-market-place-terraform-state-lock"
  terraform_state_key = "prod/market-place"

}
provider "aws" {
  region = "us-east-1"
}

# create vpc here
#Variables
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
#VPC
resource "aws_vpc" "level_finance_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = {
    Name        = "Level-Finance-Whitelisting-VPC",
    owner       = "disraptor",
    environment = "prod",
    service     = "vpc",
    type        = "application"

  }
}

module "main_subnets" {
  source            = "../modules/Subnets/"
  subnet_name       = ["marketplace-subnet", "payment-subnet", "payroll-subnet", "atomic-subnet", "flexiplepay-subnet"]
  vpc_id            = aws_vpc.level_finance_vpc.id
  subnet_count      = 5
  subnets_cidr      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  availability_zone = ["eu-central-1a", "eu-central-1b", "eu-central-1c", "eu-central-1a", "eu-central-1b"]
}

module "failover_subnets" {
  source            = "../modules/Subnets/"
  subnet_name       = ["marketplace-failover-subnet", "payment-failover-subnet", "payroll-failover-subnet", "atomic-failover-subnet", "flexiplepay-failover-subnet"]
  vpc_id            = aws_vpc.level_finance_vpc.id
  subnet_count      = 5
  subnets_cidr      = ["10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24", "10.0.10.0/24"]
  availability_zone = ["eu-central-1c", "eu-central-1a", "eu-central-1b", "eu-central-1c", "eu-central-1a"]
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.level_finance_vpc.id
  tags = {
    Name        = "Level-Finance-Internet-gateway",
    owner       = "disraptor",
    environment = "prod",
    service     = "IGW",
    type        = "Networking"
  }
}

module "route" {
  source     = "../modules/route-table"
  vpc_id     = aws_vpc.level_finance_vpc.id
  subnet_id  = module.main_subnets.subnet_id_1
  subnet_id2 = module.failover_subnets.subnet_id_1
  # gateway_id = aws_internet_gateway.igw.id
  rt_name = "marketplace-route-table"
  routes = [{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }]
}

module "route_payment" {
  source     = "../modules/route-table"
  vpc_id     = aws_vpc.level_finance_vpc.id
  subnet_id  = module.main_subnets.subnet_id_2
  subnet_id2 = module.failover_subnets.subnet_id_2
  # gateway_id = aws_internet_gateway.igw.id
  rt_name = "payment-route-table"
}

module "route_payroll" {
  source     = "../modules/route-table"
  vpc_id     = aws_vpc.level_finance_vpc.id
  subnet_id  = module.main_subnets.subnet_id_3
  subnet_id2 = module.failover_subnets.subnet_id_3
  # gateway_id = aws_internet_gateway.igw.id
  rt_name = "payroll-route-table"
}

module "route_atomic" {
  source     = "../modules/route-table"
  vpc_id     = aws_vpc.level_finance_vpc.id
  subnet_id  = module.main_subnets.subnet_id_4
  subnet_id2 = module.failover_subnets.subnet_id_4
  # gateway_id = aws_internet_gateway.igw.id
  rt_name = "atomic-route-table"
}

module "route_flexpay" {
  source     = "../modules/route-table"
  vpc_id     = aws_vpc.level_finance_vpc.id
  subnet_id  = module.main_subnets.subnet_id_5
  subnet_id2 = module.failover_subnets.subnet_id_5
  # gateway_id = aws_internet_gateway.igw.id
  rt_name = "flexible-pay-route-table"
}

# create security group
module "mp_security_group" {
  source      = "../modules/security-groups"
  vpc_id      = aws_vpc.level_finance_vpc.id
  service     = "marketplace"
  sg_name     = "marketplace-security-group"
  description = "security group for market place"

  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]

}

module "payment_security_group" {
  source      = "../modules/security-groups"
  vpc_id      = aws_vpc.level_finance_vpc.id
  service     = "payment"
  sg_name     = "payment-security-group"
  description = "security group for payment"

  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

}

module "payroll_security_group" {
  source      = "../modules/security-groups"
  vpc_id      = aws_vpc.level_finance_vpc.id
  service     = "payroll"
  sg_name     = "payroll-security-group"
  description = "security group for payroll"

  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

  egress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

}

module "atomic_security_group" {
  source      = "../modules/security-groups"
  vpc_id      = aws_vpc.level_finance_vpc.id
  service     = "atomic"
  sg_name     = "atomic-security-group"
  description = "security group for atomic"

  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

  # egress = [{
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }]

}

module "flexible_pay_security_group" {
  source      = "../modules/security-groups"
  vpc_id      = aws_vpc.level_finance_vpc.id
  service     = "flexible_pay"
  sg_name     = "flexible_pay-security-group"
  description = "security group for flexible_pay"

  ingress = [{
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.1.0/24", "10.0.6.0/24"]
  }]

  # egress = [{
  #   from_port   = 0
  #   to_port     = 0
  #   protocol    = "-1"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }]

}
