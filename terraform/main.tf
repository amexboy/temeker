provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role_policy" "temeker_bot" {
  name = "temeker_bot_policy"
  role = aws_iam_role.temeker_bot_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "ec2:Describe*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
EOF
}

data "aws_iam_policy_document" "temeker_bot_role" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "temeker_bot_role" {
  name               = "temeker_bot"
  assume_role_policy = data.aws_iam_policy_document.temeker_bot_role.json
}

data "aws_iam_policy_document" "temeker_deployer" {
  statement {
    sid     = "1"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
    effect = "Allow"
  }
}

resource "aws_iam_role" "temeker_deployer_role" {
  name               = "temeker_deployer"
  assume_role_policy = data.aws_iam_policy_document.temeker_deployer.json
}

resource "aws_iam_role_policy" "temeker_deployer" {
  name = "temeker_deployer_policy"
  role = aws_iam_role.temeker_deployer_role.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "*"
        ],
        "Effect": "Allow",
        "Resource": "*"
      }
    ]
  }
EOF
}

resource "aws_codebuild_project" "temeker_deployer" {
  name        = "bot-deployer"
  description = "Deploys bot project"

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:2.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "AWS_REGION"
      value = "us-east-1"
    }
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = aws_ecr_repository.temeker_ecr.name
    }
  }



  source {
    type            = "GITHUB"
    location        = "https://github.com/amexboy/temeker.git"
    git_clone_depth = 1
  }

  source_version = "master"

  service_role = aws_iam_role.temeker_deployer_role.arn

  tags = {
    Environment = "Prod"
  }
}

resource "aws_ecr_repository" "temeker_ecr" {
  name                 = "temeker-bot"
  image_tag_mutability = "MUTABLE"
}

resource "aws_vpc" "covid_prod" {
  cidr_block = "10.2.0.0/16"
}

resource "aws_lb_target_group" "temeker_tg" {
  name     = "temeker-tg"
  port     = 9000
  protocol = "HTTP"
  vpc_id   = aws_vpc.covid_prod.id
}

resource "aws_ecs_service" "temeker_bot" {
  name            = "temeker-bot"
  cluster         = aws_ecs_cluster.prod_cluster.id
  task_definition = aws_ecs_task_definition.temeker_bot.arn
  desired_count   = 1
  iam_role        = aws_iam_role.temeker_bot_role.arn

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.temeker_tg.arn
    container_name   = "temeker"
    container_port   = 9000
  }
}

resource "aws_ecs_task_definition" "temeker_bot" {
  family                = "service"
  container_definitions = file("task-definition.json")

  # volume {
  #   name      = "service-storage"
  #   host_path = "/ecs/service-storage"
  # }
}

resource "aws_launch_template" "lunch_template" {
  name_prefix   = "foobar"
  image_id      = "ami-04ac550b78324f651"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "covid_prod" {
  availability_zones = ["us-east-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.lunch_template.id
    version = "$Latest"
  }
}

resource "aws_ecs_cluster" "prod_cluster" {
  name = "covid-19-prod"
}

resource "aws_ecs_capacity_provider" "covid_ecs_cp" {
  name = "test"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.covid_prod.arn
  }
}
