# Provider and access details
provider "aws" {
  profile = "minecraft"
  region  = var.aws_region
}

# Create a VPC for our instances
resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.default.id
  availability_zone = var.aws_availability_zone
  cidr_block        = "10.0.0.0/16"
}

# Create a gateway for our VPC
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# We'll need to add a route to the internet from our VPC
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}

# Security group that allows SSH, Web Traffic, and a special port for our
# Minecraft server
resource "aws_security_group" "default" {
  name        = "minecraft"
  description = "Security group for standalone MC server"
  vpc_id      = aws_vpc.default.id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Minecraft
  ingress {
    from_port   = var.minecraft["port"]
    to_port     = var.minecraft["port"]
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = var.minecraft["port"]
    to_port     = var.minecraft["port"]
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# AMI to use for our instances
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu-pro-server/images/hvm-ssd/ubuntu-jammy-22.04-amd64-pro-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}


# Route53
resource "aws_route53_zone" "minecraft" {
    # Create an instance of this only if the server hostname is defined
    count = var.minecraft["hostname"] != "" ? 1 : 0

    name = var.minecraft["hostname"]
    force_destroy = true
}


# Launch template
# We'll use this to easily turn on and off our server without having to remake
# our entire instance configuration every time.
resource "aws_launch_template" "minecraft" {
  name              = "minecraft"
  image_id          = data.aws_ami.ubuntu.id
  
  instance_type     = var.aws_instance_type
  ebs_optimized     = false
  monitoring {
    enabled = false
  }
  credit_specification {
    cpu_credits = "standard"
  }
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price = var.max_spot_price
    }
  }
  
  network_interfaces {
    associate_public_ip_address = true
    security_groups = [ aws_security_group.default.id ]
    delete_on_termination = true
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.minecraft.name
  }
  key_name             = "minecraft"

  user_data = base64encode(templatefile("${ path.module }/provision.sh", {
      bucket_name = var.minecraft["bucket_name"],
      server_name = var.minecraft["server_name"]
  }))

  lifecycle {
    create_before_destroy = true
  }
}
# Autoscaling Group
resource "aws_autoscaling_group" "minecraft" {
  vpc_zone_identifier = [aws_subnet.main.id]

  name                 = "minecraft"
  desired_capacity     = 0
  min_size             = 0
  max_size             = 1
  launch_template {
    id                 = aws_launch_template.minecraft.id
    version            = "$Latest"
  }

}
