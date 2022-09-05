
locals {
    common_tags = {
    Environment = var.env
  }
}

locals {
    id_tag = var.vpc_tag_key != "" ? tomap({(var.vpc_tag_key) = (var.vpc_tag_value)}) : {}
}

provider "aws" {
  region     = var.aws_region
  default_tags {
    tags = merge(local.common_tags, local.id_tag)
  }
}

locals {
  availability_zone_1 = "${var.aws_region}${var.availability_zone1}"
}

locals {
  availability_zone_2 = "${var.aws_region}${var.availability_zone2}"
}
locals {
  public_subnet_cidr_az1 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, var.public_subnet_index)
}
locals {
  private_subnet_cidr_az1 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, var.private_subnet_index)
}
locals {
  sync_subnet_cidr_az1 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, var.sync_subnet_index)
}
locals {
  mgmt_subnet_cidr_az1 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, var.mgmt_subnet_index)
}
locals {
  tgw_subnet_cidr_az1 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, var.tgw_subnet_index)
}
locals {
  public_subnet_cidr_az2 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, (var.public_subnet_index * 10))
}
locals {
  private_subnet_cidr_az2 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, (var.private_subnet_index * 10))
}
locals {
  sync_subnet_cidr_az2 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, (var.sync_subnet_index * 10))
}
locals {
  mgmt_subnet_cidr_az2 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, (var.mgmt_subnet_index * 10))
}
locals {
  tgw_subnet_cidr_az2 = cidrsubnet(var.vpc_cidr_security, var.subnet_bits, (var.tgw_subnet_index * 10))
}
locals {
  fgt_public1_ip_address = cidrhost(local.public_subnet_cidr_az1, var.fgt_host_ip)
}
locals {
  fgt_private1_ip_address = cidrhost(local.private_subnet_cidr_az1, var.fgt_host_ip)
}
locals {
  fgt_sync1_ip_address = cidrhost(local.sync_subnet_cidr_az1, var.fgt_host_ip)
}
locals {
  fgt_mgmt1_ip_address = cidrhost(local.mgmt_subnet_cidr_az1, var.fgt_host_ip)
}
locals {
  fgt_public2_ip_address = cidrhost(local.public_subnet_cidr_az2, var.fgt_host_ip)
}
locals {
  fgt_private2_ip_address = cidrhost(local.private_subnet_cidr_az2, var.fgt_host_ip)
}
locals {
  fgt_sync2_ip_address = cidrhost(local.sync_subnet_cidr_az2, var.fgt_host_ip)
}
locals {
  fgt_mgmt2_ip_address = cidrhost(local.mgmt_subnet_cidr_az2, var.fgt_host_ip)
}
locals {
  linux_east_ip_address = cidrhost(var.vpc_cidr_east, var.linux_host_ip)
}
locals {
  linux_west_ip_address = cidrhost(var.vpc_cidr_east, var.linux_host_ip)
}
locals {
  fortimanager_ip_address = cidrhost(local.tgw_subnet_cidr_az1, var.fortimanager_host_ip)
}

resource "random_string" "random" {
  length           = 5
  special          = false
}

data "template_file" "fgt_userdata_byol1" {
  template = file("./config_templates/fgt-userdata-byol.tpl")

  vars = {
    fgt_id                = var.fortigate_hostname_1
    Port1IP               = local.fgt_public1_ip_address
    Port2IP               = local.fgt_private1_ip_address
    Port3IP               = local.fgt_sync1_ip_address
    Port4IP               = local.fgt_mgmt1_ip_address
    security_cidr         = var.vpc_cidr_security
    spoke1_cidr           = var.vpc_cidr_east
    spoke2_cidr           = var.vpc_cidr_west
    mgmt_cidr             = local.mgmt_subnet_cidr_az1
    mgmt_gw               = cidrhost(local.mgmt_subnet_cidr_az1, 1)
    fgt_priority          = "255"
    fgt_ha_password       = var.fgt_ha_password
    fgt_byol_license      = file("${path.module}/${var.fgt_byol_1_license}")
    fgt-remote-heartbeat  = cidrhost(local.mgmt_subnet_cidr_az2, var.fgt_host_ip)
    PublicSubnetRouterIP  = cidrhost(local.public_subnet_cidr_az1, 1)
    public_subnet_mask    = cidrnetmask(local.public_subnet_cidr_az1)
    private_subnet_mask   = cidrnetmask(local.private_subnet_cidr_az1)
    sync_subnet_mask      = cidrnetmask(local.sync_subnet_cidr_az1)
    hamgmt_subnet_mask    = cidrnetmask(local.mgmt_subnet_cidr_az1)
    PrivateSubnetRouterIP = cidrhost(local.private_subnet_cidr_az1, 1)
    fgt_admin_password    = var.fgt_admin_password
  }
}

data "template_file" "fgt_userdata_byol2" {
  template = file("./config_templates/fgt-userdata-byol.tpl")

  vars = {
    fgt_id                = var.fortigate_hostname_2
    Port1IP               = local.fgt_public2_ip_address
    Port2IP               = local.fgt_private2_ip_address
    Port3IP               = local.fgt_sync2_ip_address
    Port4IP               = local.fgt_mgmt2_ip_address
    PrivateSubnet         = local.private_subnet_cidr_az2
    security_cidr         = var.vpc_cidr_security
    spoke1_cidr           = var.vpc_cidr_east
    spoke2_cidr           = var.vpc_cidr_west
    mgmt_cidr             = local.mgmt_subnet_cidr_az2
    mgmt_gw               = cidrhost(local.mgmt_subnet_cidr_az2, 1)
    fgt_priority          = "100"
    fgt_ha_password       = var.fgt_ha_password
    fgt_byol_license      = file("${path.module}/${var.fgt_byol_2_license}")
    fgt-remote-heartbeat  = cidrhost(local.mgmt_subnet_cidr_az1, var.fgt_host_ip)
    PublicSubnetRouterIP  = cidrhost(local.public_subnet_cidr_az2, 1)
    public_subnet_mask    = cidrnetmask(local.public_subnet_cidr_az2)
    private_subnet_mask   = cidrnetmask(local.private_subnet_cidr_az2)
    sync_subnet_mask      = cidrnetmask(local.sync_subnet_cidr_az2)
    hamgmt_subnet_mask    = cidrnetmask(local.mgmt_subnet_cidr_az2)
    PrivateSubnetRouterIP = cidrhost(local.private_subnet_cidr_az2, 1)
    fgt_admin_password    = var.fgt_admin_password
  }
}

data "template_file" "fgt_userdata_paygo1" {
  template = file("./config_templates/fgt-userdata-paygo.tpl")

  vars = {
    fgt_id                = var.fortigate_hostname_1
    Port1IP               = local.fgt_public1_ip_address
    Port2IP               = local.fgt_private1_ip_address
    Port3IP               = local.fgt_sync1_ip_address
    Port4IP               = local.fgt_mgmt1_ip_address
    security_cidr         = var.vpc_cidr_security
    spoke1_cidr           = var.vpc_cidr_east
    spoke2_cidr           = var.vpc_cidr_west
    mgmt_cidr             = local.mgmt_subnet_cidr_az1
    mgmt_gw               = cidrhost(local.mgmt_subnet_cidr_az1, 1)
    fgt_priority          = "255"
    fgt_ha_password       = var.fgt_ha_password
    fgt-remote-heartbeat  = cidrhost(local.mgmt_subnet_cidr_az2, var.fgt_host_ip)
    PublicSubnetRouterIP  = cidrhost(local.public_subnet_cidr_az1, 1)
    public_subnet_mask    = cidrnetmask(local.public_subnet_cidr_az1)
    private_subnet_mask   = cidrnetmask(local.private_subnet_cidr_az1)
    sync_subnet_mask      = cidrnetmask(local.sync_subnet_cidr_az1)
    hamgmt_subnet_mask    = cidrnetmask(local.mgmt_subnet_cidr_az1)
    PrivateSubnetRouterIP = cidrhost(local.private_subnet_cidr_az1, 1)
    fgt_admin_password    = var.fgt_admin_password
  }
}

data "template_file" "fgt_userdata_paygo2" {
  template = file("./config_templates/fgt-userdata-paygo.tpl")

  vars = {
    fgt_id                = var.fortigate_hostname_2
    Port1IP               = local.fgt_public2_ip_address
    Port2IP               = local.fgt_private2_ip_address
    Port3IP               = local.fgt_sync2_ip_address
    Port4IP               = local.fgt_mgmt2_ip_address
    PrivateSubnet         = local.private_subnet_cidr_az2
    security_cidr         = var.vpc_cidr_security
    spoke1_cidr           = var.vpc_cidr_east
    spoke2_cidr           = var.vpc_cidr_west
    mgmt_cidr             = local.mgmt_subnet_cidr_az2
    mgmt_gw               = cidrhost(local.mgmt_subnet_cidr_az2, 1)
    fgt_priority          = "100"
    fgt_ha_password       = var.fgt_ha_password
    fgt-remote-heartbeat  = cidrhost(local.mgmt_subnet_cidr_az1, var.fgt_host_ip)
    PublicSubnetRouterIP  = cidrhost(local.public_subnet_cidr_az2, 1)
    public_subnet_mask    = cidrnetmask(local.public_subnet_cidr_az2)
    private_subnet_mask   = cidrnetmask(local.private_subnet_cidr_az2)
    sync_subnet_mask      = cidrnetmask(local.sync_subnet_cidr_az2)
    hamgmt_subnet_mask    = cidrnetmask(local.mgmt_subnet_cidr_az2)
    PrivateSubnetRouterIP = cidrhost(local.private_subnet_cidr_az2, 1)
    fgt_admin_password    = var.fgt_admin_password
  }
}

#
# AMI to be used by the BYOL instance of Fortigate]
# Change the foritos_version and the use_fortigate_byol variables in terraform.tfvars to change it
#
data "aws_ami" "fortigate_byol" {
  most_recent = true

  filter {
    name                         = "name"
    values                       = ["FortiGate-VM64-AWS * (${var.fortios_version}) GA*"]
  }

  filter {
    name                         = "virtualization-type"
    values                       = ["hvm"]
  }

  owners                         = ["679593333241"] # Canonical
}


#
# AMI to be used by the PAYGO instance of Fortigate
# Change the foritos_version and the use_fortigate_byol variables in terraform.tfvars to change it
#
data "aws_ami" "fortigate_paygo" {
  most_recent = true

  filter {
    name                         = "name"
    values                       = ["FortiGate-VM64-AWSONDEMAND * (${var.fortios_version}) GA*"]
  }

  filter {
    name                         = "virtualization-type"
    values                       = ["hvm"]
  }

  owners                         = ["679593333241"] # Canonical
}

#
# This is an "allow all" security group, but a place holder for a more strict SG
#
module "allow_private_subnets" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_security_group"
  sg_name= "${var.cp}-${var.env}-${random_string.random.result}-${var.fgt_sg_name} Allow Private Subnets"

  vpc_id                  = module.base-vpc.vpc_id
  ingress_to_port         = 0
  ingress_from_port       = 0
  ingress_protocol        = "-1"
  ingress_cidr_for_access = "0.0.0.0/0"
  egress_to_port          = 0
  egress_from_port        = 0
  egress_protocol         = "-1"
  egress_cidr_for_access  = "0.0.0.0/0"
}

#
# This is an "allow all" security group, but a place holder for a more strict SG
#
module "allow_public_subnets" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_security_group"
  sg_name= "${var.cp}-${var.env}-${random_string.random.result}-${var.fgt_sg_name} Allow Public Subnets"

  vpc_id                  = module.base-vpc.vpc_id
  ingress_to_port         = 0
  ingress_from_port       = 0
  ingress_protocol        = "-1"
  ingress_cidr_for_access = "0.0.0.0/0"
  egress_to_port          = 0
  egress_from_port        = 0
  egress_protocol         = "-1"
  egress_cidr_for_access  = "0.0.0.0/0"
}

#
# VPC Setups, route tables, route table associations
#

#
# Security VPC, IGW, Subnets, Route Tables, Route Table Associations, VPC Endpoint
#
module "base-vpc" {
  source                          = "git::https://github.com/40netse/base_vpc_dual_az.git"
  aws_region                      = var.aws_region
  customer_prefix                 = var.cp
  environment                     = var.env
  availability_zone1              = var.availability_zone1
  availability_zone2              = var.availability_zone2
  vpc_name_security               = var.vpc_name_security
  vpc_cidr_security               = var.vpc_cidr_security
  subnet_bits                     = var.subnet_bits
  public_subnet_index             = var.public_subnet_index
  private_subnet_index            = var.private_subnet_index
  public1_description             = var.public1_description
  private1_description            = var.private1_description
  public2_description             = var.public2_description
  private2_description            = var.private2_description
  vpc_tag_key                     = var.vpc_tag_key
  vpc_tag_value                   = var.vpc_tag_value
}

module "vpc-transit-gateway" {
  count                           = var.create_transit_gateway ? 1 : 0
  source                          = "git::https://github.com/40netse/terraform-modules.git//aws_tgw"
  tgw_name                        = "${var.cp}-${var.env}-tgw"
  default_route_table_association = "disable"
  default_route_table_propagation = "disable"
  dns_support                     = "disable"
  default_route_attachment_id     = module.vpc-transit-gateway-attachment-security[0].tgw_attachment_id
}

#
# Point the private route table default route to the TGW
#
resource "aws_route" "tgw1" {
  count                  = var.create_transit_gateway ? 1 : 0
  route_table_id         = module.base-vpc.private1_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.vpc-transit-gateway[0].tgw_id
}


resource "aws_route" "tgw2" {
  count                  = var.create_transit_gateway ? 1 : 0
  route_table_id         = module.base-vpc.private2_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = module.vpc-transit-gateway[0].tgw_id
}

#
# Security VPC Transit Gateway Attachment, Route Table and Routes
#
module "vpc-transit-gateway-attachment-security" {
  count                          = var.create_transit_gateway ? 1 : 0
  source                         = "git::https://github.com/40netse/terraform-modules.git//aws_tgw_attachment"
  tgw_attachment_name            = "${var.cp}-${var.env}-${var.vpc_name_security}-tgw-attachment"

  transit_gateway_id                              = module.vpc-transit-gateway[0].tgw_id
  subnet_ids                                      = [ module.private1-subnet-tgw.id, module.private2-subnet-tgw.id ]
  transit_gateway_default_route_table_propogation = "false"
  vpc_id                                          = module.base-vpc.vpc_id
}

resource "aws_ec2_transit_gateway_route_table" "security" {
  count                  = var.create_transit_gateway ? 1 : 0
  transit_gateway_id     = module.vpc-transit-gateway[0].tgw_id
  tags = {
    Name = "${var.cp}-${var.env}-Security VPC TGW Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "security" {
  count                          = var.create_transit_gateway ? 1 : 0
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-security[0].tgw_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security[0].id
}

resource "aws_ec2_transit_gateway_route" "tgw_route_security_default" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = var.vpc_cidr_west
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-west[0].tgw_attachment_id
}

resource "aws_ec2_transit_gateway_route" "tgw_route_security_cidr" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = var.vpc_cidr_east
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.security[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-east[0].tgw_attachment_id
}

#
# East VPC Transit Gateway Attachment, Route Table and Routes
#
module "vpc-transit-gateway-attachment-east" {
  count                          = var.create_transit_gateway ? 1 : 0
  source                         = "git::https://github.com/40netse/terraform-modules.git//aws_tgw_attachment"
  tgw_attachment_name            = "${var.cp}-${var.env}-${var.vpc_name_east}-tgw-attachment"

  transit_gateway_id                              = module.vpc-transit-gateway[0].tgw_id
  subnet_ids                                      = [ module.subnet-east[0].id ]
  transit_gateway_default_route_table_propogation = "false"
  vpc_id                                          = module.vpc-east[0].vpc_id
}

resource "aws_ec2_transit_gateway_route_table" "east" {
  count                          = var.create_transit_gateway ? 1 : 0
  transit_gateway_id             = module.vpc-transit-gateway[0].tgw_id
    tags = {
      Name = "${var.cp}-${var.env}-East VPC TGW Route Table"
  }
}
resource "aws_ec2_transit_gateway_route_table_association" "east" {
  count                          = var.create_transit_gateway ? 1 : 0
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-east[0].tgw_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east[0].id
}
resource "aws_ec2_transit_gateway_route" "tgw_route_east_default" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-security[0].tgw_attachment_id
}
resource "aws_ec2_transit_gateway_route" "tgw_route_east_cidr" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = var.vpc_cidr_east
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.east[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-east[0].tgw_attachment_id
}

#
# West VPC Transit Gateway Attachment, Route Table and Routes
#
module "vpc-transit-gateway-attachment-west" {
  count                          = var.create_transit_gateway ? 1 : 0
  source                         = "git::https://github.com/40netse/terraform-modules.git//aws_tgw_attachment"
  tgw_attachment_name            = "${var.cp}-${var.env}-${var.vpc_name_east}-tgw-attachment"

  transit_gateway_id                              = module.vpc-transit-gateway[0].tgw_id
  subnet_ids                                      = [ module.subnet-west[0].id ]
  transit_gateway_default_route_table_propogation = "false"
  vpc_id                                          = module.vpc-west[0].vpc_id
}

resource "aws_ec2_transit_gateway_route_table" "west" {
  count                          = var.create_transit_gateway ? 1 : 0
  transit_gateway_id             = module.vpc-transit-gateway[0].tgw_id
  tags = {
    Name = "${var.cp}-${var.env}-West VPC TGW Route Table"
  }
}

resource "aws_ec2_transit_gateway_route_table_association" "west" {
  count                          = var.create_transit_gateway ? 1 : 0
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-west[0].tgw_attachment_id
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west[0].id
}

resource "aws_ec2_transit_gateway_route" "tgw_route_west" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = var.vpc_cidr_west
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-west[0].tgw_attachment_id
}

resource "aws_ec2_transit_gateway_route" "tgw_route_west_default" {
  count                          = var.create_transit_gateway ? 1 : 0
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_route_table_id = aws_ec2_transit_gateway_route_table.west[0].id
  transit_gateway_attachment_id  = module.vpc-transit-gateway-attachment-security[0].tgw_attachment_id
}


resource "aws_default_route_table" "route_security" {
  count                          = var.create_transit_gateway ? 1 : 0
  default_route_table_id         = module.base-vpc.vpc_main_route_table_id
  tags = {
    Name = "default table for security vpc (unused)"
  }
}

#
# Private 1 and 2 subnets that are connected to the TGW
# These route tables point to the ENI of the ACTIVE Fortigate
#
module "private1-subnet-tgw" {
  source      = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-tgw1-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_1
  subnet_cidr                = local.tgw_subnet_cidr_az1
}

module "private1_tgw_route_table" {
  source                     = "git::https://github.com/40netse/terraform-modules.git//aws_route_table"
  rt_name                    = "${var.cp}-${var.env}-tgw1-route_table"
  vpc_id                     = module.base-vpc.vpc_id
  eni_route                  = 1
  eni_id                     = element(module.fortigate_1.network_private_interface_id, 0)
}

module "private1_tgw_route_table_association" {
  source                     = "git::https://github.com/40netse/terraform-modules.git//aws_route_table_association"

  subnet_ids                 = module.private1-subnet-tgw.id
  route_table_id             = module.private1_tgw_route_table.id
}

module "private2-subnet-tgw" {
  source      = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-tgw2-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_2
  subnet_cidr                = local.tgw_subnet_cidr_az2
}

module "private2_tgw_route_table" {
  source                     = "git::https://github.com/40netse/terraform-modules.git//aws_route_table"
  rt_name                    = "${var.cp}-${var.env}-tgw2-route_table"

  vpc_id                     = module.base-vpc.vpc_id
  eni_route                  = 1
  eni_id                     = element(module.fortigate_1.network_private_interface_id, 0)
}

module "private2_tgw_route_table_association" {
  source                     = "git::https://github.com/40netse/terraform-modules.git//aws_route_table_association"

  subnet_ids                 = module.private2-subnet-tgw.id
  route_table_id             = module.private2_tgw_route_table.id
}

module "sync-subnet-1" {
  source      = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-sync1-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_1
  subnet_cidr                = local.sync_subnet_cidr_az1
}

module "sync-subnet-2" {
  source      = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-sync2-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_2
  subnet_cidr                = local.sync_subnet_cidr_az2
}

module "ha-subnet-1" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-mgmt1-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_1
  subnet_cidr                = local.mgmt_subnet_cidr_az1
  public_route               = 1
  public_route_table_id      = module.base-vpc.public_route_table_id
}

module "ha-subnet-2" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  subnet_name = "${var.cp}-${var.env}-mgmt2-subnet"

  vpc_id                     = module.base-vpc.vpc_id
  availability_zone          = local.availability_zone_2
  subnet_cidr                = local.mgmt_subnet_cidr_az2
  public_route               = 1
  public_route_table_id      = module.base-vpc.public_route_table_id
}

#
# VPC Endpoint for AWS API Calls
#
module "vpc_s3_endpoint" {
  source                     = "git::https://github.com/40netse/terraform-modules.git//aws_vpc_endpoints"

  aws_region                 = var.aws_region
  vpc_endpoint_name          = "${var.cp}-${var.env}-vpc_endpoint"
  vpc_id                     = module.base-vpc.vpc_id
  route_table_id             = [ module.base-vpc.public_route_table_id ]
}

#
# East VPC
#
module "vpc-east" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_vpc"
  count                      = var.create_transit_gateway ? 1 : 0
  vpc_name                   = "${var.cp}-${var.env}-${var.vpc_name_east}-vpc"
  vpc_cidr                   = var.vpc_cidr_east
}

module "subnet-east" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  count                      = var.create_transit_gateway ? 1 : 0
  subnet_name                = "${var.cp}-${var.env}-${var.vpc_name_east}-subnet"

  vpc_id                     = module.vpc-east[0].vpc_id
  availability_zone          = local.availability_zone_1
  subnet_cidr                = var.vpc_cidr_east
}

#
# Default route table that is created with the east VPC. We just need to add a default route
# that points to the TGW Attachment
#
resource "aws_default_route_table" "route_east" {
  count                      = var.create_transit_gateway ? 1 : 0
  default_route_table_id = module.vpc-east[0].vpc_main_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = module.vpc-transit-gateway[0].tgw_id
  }
  tags = {
    Name = "default table for vpc east"
  }
}

module "rta-east" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_route_table_association"
  count                      = var.create_transit_gateway ? 1 : 0
  subnet_ids                 = module.subnet-east[0].id
  route_table_id             = module.vpc-east[0].vpc_main_route_table_id
}

#
# West VPC
#
module "vpc-west" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_vpc"
  count                      = var.create_transit_gateway ? 1 : 0
  vpc_name                   = "${var.cp}-${var.env}-${var.vpc_name_west}-vpc"
  vpc_cidr                   = var.vpc_cidr_west

}

module "subnet-west" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_subnet"
  count                      = var.create_transit_gateway ? 1 : 0
  subnet_name                = "${var.cp}-${var.env}-${var.vpc_name_west}-subnet"

  vpc_id                     = module.vpc-east[0].vpc_id
  availability_zone          = local.availability_zone_2
  subnet_cidr                = var.vpc_cidr_west
}
#
# Default route table that is created with the west VPC. We just need to add a default route
# that points to the TGW Attachment
#
resource "aws_default_route_table" "route_west" {
  default_route_table_id     = module.vpc-west[0].vpc_main_route_table_id
  count                      = var.create_transit_gateway ? 1 : 0
  route {
    cidr_block = "0.0.0.0/0"
    transit_gateway_id = module.vpc-transit-gateway[0].tgw_id
  }
  tags = {
    Name = "default table for vpc west"
  }
}

module "rta-west" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_route_table_association"

  count                      = var.create_transit_gateway ? 1 : 0
  subnet_ids                 = module.subnet-west[0].id
  route_table_id             = module.vpc-west[0].vpc_main_route_table_id
}

#
# Fortigate HA Pair and IAM Profiles
#
module "iam_profile" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance_iam_role"
  iam_role_name = "${var.cp}-${var.env}-${random_string.random.result}-fortigate-instance_role"

}

module "fortigate_1" {
  source                      = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance"

  aws_ec2_instance_name       = "${var.cp}-${var.env}-${var.vpc_name_security}-${var.fortigate_instance_name_1}"
  availability_zone           = local.availability_zone_1
  enable_private_interface    = true
  enable_sync_interface       = true
  enable_hamgmt_interface     = true
  enable_public_ips           = var.create_public_elastic_ip
  enable_mgmt_public_ips      = var.create_management_elastic_ips
  public_subnet_id            = module.base-vpc.public1_subnet_id
  public_ip_address           = local.fgt_public1_ip_address
  private_subnet_id           = module.base-vpc.private1_subnet_id
  private_ip_address          = local.fgt_private1_ip_address
  sync_subnet_id              = module.sync-subnet-1.id
  sync_ip_address             = local.fgt_sync1_ip_address
  ha_subnet_id                = module.ha-subnet-1.id
  ha_ip_address               = local.fgt_mgmt1_ip_address
  aws_ami                     = var.use_fortigate_byol ? data.aws_ami.fortigate_byol.id : data.aws_ami.fortigate_paygo.id
  keypair                     = var.keypair
  instance_type               = var.fortigate_instance_type
  instance_name               = var.fortigate_instance_name_1
  security_group_private_id   = module.allow_private_subnets.id
  security_group_public_id    = module.allow_public_subnets.id
  acl                         = var.acl
  iam_instance_profile_id     = module.iam_profile.id
  userdata_rendered           = var.use_fortigate_byol ? data.template_file.fgt_userdata_byol1.rendered : data.template_file.fgt_userdata_paygo1.rendered
}

module "fortigate_2" {
  source                      = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance"

  aws_ec2_instance_name       = "${var.cp}-${var.env}-${var.vpc_name_security}-${var.fortigate_instance_name_2}"
  availability_zone           = local.availability_zone_1
  enable_private_interface    = true
  enable_sync_interface       = true
  enable_hamgmt_interface     = true
  enable_public_ips           = false
  enable_mgmt_public_ips      = var.create_management_elastic_ips
  public_subnet_id            = module.base-vpc.public2_subnet_id
  public_ip_address           = local.fgt_public2_ip_address
  private_subnet_id           = module.base-vpc.private2_subnet_id
  private_ip_address          = local.fgt_private2_ip_address
  sync_subnet_id              = module.sync-subnet-2.id
  sync_ip_address             = local.fgt_sync2_ip_address
  ha_subnet_id                = module.ha-subnet-2.id
  ha_ip_address               = local.fgt_mgmt2_ip_address
  aws_ami                     = var.use_fortigate_byol ? data.aws_ami.fortigate_byol.id : data.aws_ami.fortigate_paygo.id
  keypair                     = var.keypair
  instance_type               = var.fortigate_instance_type
  instance_name               = var.fortigate_instance_name_2
  security_group_private_id   = module.allow_private_subnets.id
  security_group_public_id    = module.allow_public_subnets.id
  acl                         = var.acl
  iam_instance_profile_id     = module.iam_profile.id
  userdata_rendered           = var.use_fortigate_byol ? data.template_file.fgt_userdata_byol2.rendered : data.template_file.fgt_userdata_paygo2.rendered
}

#
# Optional Linux Instances from here down
#
# Linux Instance that are added on to the East and West VPCs for testing EAST->West Traffic
#
# Endpoint AMI to use for Linux Instances. Just added this on the end, since traffic generating linux instances
# would not make it to a production template.
#

data "template_file" "web_userdata" {
  template = file("./config_templates/web-userdata.tpl")
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-20220609"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"] # Canonical
}

#
# EC2 Endpoint Resources
#

#
# Security Groups are VPC specific, so an "ALLOW ALL" for each VPC
#
module "ec2-east-sg" {
  source                  = "git::https://github.com/40netse/terraform-modules.git//aws_security_group"
  count                   = var.create_transit_gateway ? 1 : 0
  sg_name                 = "${var.cp}-${var.env}-${random_string.random.result}-${var.ec2_sg_name} Allow East Subnets"
  vpc_id                  = module.vpc-east[0].vpc_id
  ingress_to_port         = 0
  ingress_from_port       = 0
  ingress_protocol        = "-1"
  ingress_cidr_for_access = "0.0.0.0/0"
  egress_to_port          = 0
  egress_from_port        = 0
  egress_protocol         = "-1"
  egress_cidr_for_access  = "0.0.0.0/0"
}


module "ec2-west-sg" {
  source                  = "git::https://github.com/40netse/terraform-modules.git//aws_security_group"
  count                   = var.create_transit_gateway ? 1 : 0
  sg_name                 = "${var.cp}-${var.env}-${random_string.random.result}-${var.ec2_sg_name} Allow West Subnets"
  vpc_id                  = module.vpc-west[0].vpc_id
  ingress_to_port         = 0
  ingress_from_port       = 0
  ingress_protocol        = "-1"
  ingress_cidr_for_access = "0.0.0.0/0"
  egress_to_port          = 0
  egress_from_port        = 0
  egress_protocol         = "-1"
  egress_cidr_for_access  = "0.0.0.0/0"
}

#
# IAM Profile for linux instance
#
module "linux_iam_profile" {
  source = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance_iam_role"
  count                       = var.create_transit_gateway && var.enable_linux_instances ? 1 : 0
  iam_role_name = "${var.cp}-${var.env}-${random_string.random.result}-linux-instance_role"
}

#
# East Linux Instance for Generating East->West Traffic
#
module "east_instance" {
  source                      = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance"
  count                       = var.create_transit_gateway && var.enable_linux_instances ? 1 : 0
  aws_ec2_instance_name       = "${var.cp}-${var.env}-${var.vpc_name_east}-${var.linux_instance_name_east}"
  enable_public_ips           = false
  availability_zone           = local.availability_zone_1
  public_subnet_id            = module.subnet-east[0].id
  public_ip_address           = local.linux_east_ip_address
  aws_ami                     = data.aws_ami.ubuntu.id
  keypair                     = var.keypair
  instance_type               = var.linux_instance_type
  security_group_public_id    = module.ec2-east-sg[0].id
  acl                         = var.acl
  iam_instance_profile_id     = module.iam_profile.id
  userdata_rendered           = data.template_file.web_userdata.rendered
}

#
# West Linux Instance for Generating West->East Traffic
#
module "west_instance" {
  source                      = "git::https://github.com/40netse/terraform-modules.git//aws_ec2_instance"
  count                       = var.create_transit_gateway && var.enable_linux_instances ? 1 : 0
  aws_ec2_instance_name       = "${var.cp}-${var.env}-${var.vpc_name_west}-${var.linux_instance_name_west}"
  enable_public_ips           = false
  availability_zone           = local.availability_zone_2
  public_subnet_id            = module.subnet-west[0].id
  public_ip_address           = local.linux_west_ip_address
  aws_ami                     = data.aws_ami.ubuntu.id
  keypair                     = var.keypair
  instance_type               = var.linux_instance_type
  security_group_public_id    = module.ec2-west-sg[0].id
  acl                         = var.acl
  iam_instance_profile_id     = module.iam_profile.id
  userdata_rendered           = data.template_file.web_userdata.rendered
}

#
# Fortimanager
#
module "fortimanager" {
  source                      = "git::https://github.com/40netse/fortimanager_existing_vpc.git"
  count                       = var.enable_fortimanager ? 1 : 0
  aws_ec2_instance_name       = "${var.cp}-${var.env}-${var.vpc_name_security}-${var.fortimanager_instance_name}"

  aws_region                  = var.aws_region
  customer_prefix             = var.cp
  environment                 = var.env
  availability_zone           = local.availability_zone_1
  vpc_id                      = module.base-vpc.vpc_id
  subnet_id                   = module.private1-subnet-tgw.id
  ip_address                  = local.fortimanager_ip_address
  keypair                     = var.keypair
  fortimanager_instance_type  = var.fortimanager_instance_type
  fortimanager_instance_name  = var.fortimanager_instance_name
  fortimanager_sg_name        = var.fortimanager_sg_name
  fortimanager_os_version     = var.fortimanager_os_version
  fmgr_byol_license           = var.fortimanager_byol_license
  acl                         = var.acl
  enable_public_ips           = false
  use_fortimanager_byol       = var.use_fortimanager_byol
  fmgr_admin_password         = var.fgt_admin_password
}
