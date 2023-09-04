locals {
  name           = "${var.app_name}-ecs"
  log_group_name = "/ecs/${local.name}/logs"
}

data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_security_group" "this" {
  name = "${local.name}-${var.stage}"
  tags = {
    Name = "${local.name}-${var.stage}"
  }

  description = "Security Group for ${local.name}-${var.stage}"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Access"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }

  egress {
    description = "HTTPS Access"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "exec" {
  name = "${local.name}-ecs-task-exec-${var.stage}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "exec" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  name = "${local.name}-ecs-task-${var.stage}"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}

resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days
}

resource "aws_ecs_cluster" "this" {
  name = "${local.name}-${var.stage}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"


      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.this.name
        s3_key_prefix              = "ecs/${local.name}/logs"
      }
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = ["FARGATE"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${local.name}-${var.stage}"
  cpu                      = 256 # .25 vCPU
  memory                   = 512 # 512 MiB
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.exec.arn
  task_role_arn      = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.ecr_image_url
      cpu       = 256
      memory    = 512
      essential = true
      linuxParameters = {
        initProcessEnabled = true
      }
      portMappings = [{ containerPort : var.container_port }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = var.region
          awslogs-group         = aws_cloudwatch_log_group.this.name
          awslogs-stream-prefix = "logs"
        }
      }
    },
  ])
}

resource "aws_ecs_service" "this" {
  name            = local.name
  cluster         = aws_ecs_cluster.this.arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.this.id]
    subnets         = var.subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }
}


resource "aws_lb_target_group" "this" {
  name        = "${local.name}-${var.stage}"
  target_type = "ip"
  protocol    = "HTTP"
  port        = var.container_port
  vpc_id      = var.vpc_id

  health_check {
    path                = var.health_check_path
    port                = var.health_check_port
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 5
    interval            = 10
    matcher             = "200,301,302,403"
  }
}



resource "aws_lb_listener_rule" "this" {
  listener_arn = var.lb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}
