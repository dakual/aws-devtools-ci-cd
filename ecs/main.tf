terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.38.0"
    }
  }

  required_version = ">= 1.2.5"
}

provider "aws" {
  region = local.region
}

locals {
  name            = "demo-app"
  environment     = "dev"
  region          = "eu-central-1"
  vpc_id          = "vpc-064f43e135e1ecbc0"
  subnets         = ["subnet-02caf3f4a7dab08f6","subnet-0e00855f4313be466", "subnet-0535e60978084785d"]
  security_groups = ["sg-095938d5e717361ea"]
  container_image = "nginx:alpine"
  container_port  = 80
}


# APPLICATION LOADBALANCER
resource "aws_lb" "main" {
  name               = "${local.name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = local.security_groups
  subnets            = [for subnet in local.subnets : subnet]
}

resource "aws_alb_target_group" "target1" {
  name        = "${local.name}-tg1"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_target_group" "target2" {
  name        = "${local.name}-tg2"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = local.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws_lb.main.id
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.target1.id
    type = "forward"
  }
}


# AIM ROLE
data "aws_iam_policy_document" "ecs_code_deploy_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["codedeploy.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_code_deploy_role" {
  name = "${local.name}-ecsCodeDeployRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_code_deploy_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs_code_deploy_role-policy-attachment" {
  role       = aws_iam_role.ecs_code_deploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}


data "aws_iam_policy_document" "ecs_tasks_execution_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_tasks_execution_role" {
  name = "${local.name}-ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_tasks_execution_role.json}"
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_tasks_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecr_repository" "main" {
  name                 = local.name
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = false
  }
}


# ECS CLUSTER, SERVICE AND TASK
resource "aws_cloudwatch_log_group" "task" {
  name = "/ecs/${local.name}-task"
}

resource "aws_ecs_cluster" "main" {
  name = "${local.name}-cluster"
}

resource "aws_ecs_task_definition" "main" {
  family                   = "${local.name}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_tasks_execution_role.arn

  container_definitions = jsonencode([{
      name  = "${local.name}-container"
      image = "${local.container_image}"
      essential = true
      environment = [{
          name  = "ENV_MESSAGE"
          value = "DEMO APP"
      }]
      portMappings = [{
          protocol = "tcp"
          containerPort = local.container_port
          hostPort = local.container_port
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.task.name
          awslogs-region        = local.region
          awslogs-stream-prefix = "ecs"
        }
      }
  }])
}

resource "aws_ecs_service" "main" {
  name                               = "${local.name}-service"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main.arn
  desired_count                      = 1
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 60
  launch_type                        = "FARGATE"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = local.security_groups
    subnets          = [for subnet in local.subnets : subnet]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.target1.arn
    container_name   = "${local.name}-container"
    container_port   = local.container_port
  }

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
}

output "lb_dns_name" {
  value = aws_lb.main.dns_name
}

output "ecs_code_deploy_role_arn" {
  value = aws_iam_role.ecs_code_deploy_role.arn
}