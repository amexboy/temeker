
resource "aws_vpc" "covid_prod" {
  cidr_block = "10.2.0.0/16"
  tags = {
    Name = "convid-prod"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.covid_prod.id
}

resource "aws_subnet" "covid_public_prod" {
  count = 2
  vpc_id     = aws_vpc.covid_prod.id
  cidr_block = "10.2.${count.index}0.0/24"

  tags = {
    Name = "convid-public-prod-s1"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.covid_prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public_route_table_assoc" {
  count = 2
  subnet_id      = aws_subnet.covid_public_prod[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_subnet" "covid_public_private" {
  vpc_id     = aws_vpc.covid_prod.id
  cidr_block = "10.2.20.0/24"

  tags = {
    Name = "convid-public-private"
  }
}

resource "aws_launch_template" "lunch_template" {
  name_prefix   = "foobar"
  image_id      = "ami-04ac550b78324f651"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "covid_prod" {
  name                = "covid-asg-2-prod"
  availability_zones  = ["us-east-1a"]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1
  vpc_zone_identifier = aws_subnet.covid_public_prod[*].id

  launch_template {
    id      = aws_launch_template.lunch_template.id
    version = "$Latest"
  }
}

resource "aws_ecs_cluster" "prod_cluster" {
  name = "covid-19-prod"
    capacity_providers = [aws_ecs_capacity_provider.covid_ecs_cp.name]
}

resource "aws_ecs_capacity_provider" "covid_ecs_cp" {
  name = "cp-asg-${aws_autoscaling_group.covid_prod.name}"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.covid_prod.arn
    managed_scaling {
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}
