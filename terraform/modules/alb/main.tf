locals {
  name = "${var.app_name}-lb"
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Backend Access"
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.this.cidr_block]
  }
}


resource "aws_lb" "this" {
  name               = "${local.name}-${var.stage}"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.this.id]
  subnets            = var.subnets

  enable_deletion_protection = false

  tags = {
    Name = "${local.name}-${var.stage}"
  }

}


resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "503 Service Temporarily Unavailable"
      status_code  = "503"
    }
  }
}
