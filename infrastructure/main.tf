provider "aws" {
  region = "us-east-1"
}

resource "aws_ecs_cluster" "cluster" {
  name = "cluster"
  depends_on = [
    aws_iam_role.ecs_role,
    aws_iam_role.ecs_task_execution_role
  ]
}

data "aws_iam_policy_document" "ec2_instance_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_execution_role_assume_role_policy" {
  version = "2012-10-17"
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_role" {
  name                = "ecs_role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.ec2_instance_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"]
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ecs_profile"
  role = aws_iam_role.ecs_role.name
}

resource "aws_security_group" "ecs_security_group" {
  name        = "ecs_security_group"
  description = "Security group of the ECS cluster"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "allow_tcp_port_22" {
  security_group_id = aws_security_group.ecs_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "from_alb" {
  security_group_id            = aws_security_group.ecs_security_group.id
  referenced_security_group_id = aws_security_group.alb_sg.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_trafic" {
  security_group_id = aws_security_group.ecs_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "ecs_launch_template" {
  name          = "ecs_launch_template"
  instance_type = var.instance_type
  image_id      = var.ecs_ec2_cluster_ami_id
  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_profile.name
  }
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ecs_security_group.id]
  user_data              = filebase64("${path.module}/start.sh")
}

resource "aws_autoscaling_group" "ecs_autoscaling_group" {
  min_size            = 1
  max_size            = 1
  desired_capacity    = 1
  vpc_zone_identifier = [var.vpc_zone_identifier]
  force_delete = true
  launch_template {
    id      = aws_launch_template.ecs_launch_template.id
    version = aws_launch_template.ecs_launch_template.latest_version
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_http_inbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_all_outbound" {
  security_group_id = aws_security_group.alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_lb" "ecs_alb" {
  name                       = "ecs-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg.id]
  subnets                    = var.subnet_ids
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "user_tg" {
  name        = "user-tg"
  port        = 3001
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "product_tg" {
  name        = "product-tg"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_target_group" "order_tg" {
  name        = "order-tg"
  port        = 3002
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}

resource "aws_lb_listener_rule" "user" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.user_tg.arn
  }
  condition {
    path_pattern {
      values = ["/user*", "/api/user*"]
    }
  }
}

resource "aws_lb_listener_rule" "product" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 200
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.product_tg.arn
  }
  condition {
    path_pattern {
      values = ["/product*", "/api/product*"]
    }
  }
}

resource "aws_lb_listener_rule" "order" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 300
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.order_tg.arn
  }
  condition {
    path_pattern {
      values = ["/order*", "/api/order*"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name                = "ecs_task_execution_role"
  path                = "/"
  assume_role_policy  = data.aws_iam_policy_document.ecs_task_execution_role_assume_role_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"]
}

resource "aws_ecs_task_definition" "ecs_task_definition" {
  family                   = "ecs_task_definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["EC2"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = "user-service"
      image     = var.user_service_image_uri
      essential = true
      portMappings = [
        {
          containerPort = 3001
        }
      ]
    },
    {
      name      = "product-service"
      image     = var.product_service_image_uri
      essential = true
      portMappings = [
        {
          containerPort = 3000
        }
      ]
    },
    {
      name      = "order-service"
      image     = var.order_service_image_uri
      essential = true
      portMappings = [
        {
          containerPort = 3002
        }
      ]
      environment = [
        {
          name  = "USER_SERVICE_BASE_URL"
          value = "http://localhost:3001"
        },
        {
          name  = "PRODUCT_SERVICE_BASE_URL"
          value = "http://localhost:3000"
        }
      ]
    },
  ])
}

resource "aws_ecs_service" "ecs_service" {
  name = "ecs_service"
  depends_on = [
    aws_autoscaling_group.ecs_autoscaling_group,
    aws_lb_listener.http,
    aws_iam_role.ecs_task_execution_role,
    aws_iam_role.ecs_role
  ]
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ecs_task_definition.arn
  desired_count   = 1
  launch_type     = "EC2"
  network_configuration {
    subnets         = var.subnet_ids
    security_groups = [aws_security_group.ecs_security_group.id]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.user_tg.arn
    container_name   = "user-service"
    container_port   = 3001
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.product_tg.arn
    container_name   = "product-service"
    container_port   = 3000
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.order_tg.arn
    container_name   = "order-service"
    container_port   = 3002
  }
  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

resource "null_resource" "ecs_service_scale_to_zero_on_destroy" {
  triggers = {
    cluster_name = aws_ecs_cluster.cluster.name
    service_name = "ecs_service"
    region       = "us-east-1"          # ← your region
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "Force-scaling ECS service to 0..."
      aws ecs update-service \
        --cluster "${self.triggers.cluster_name}" \
        --service "${self.triggers.service_name}" \
        --desired-count 0 \
        --force-new-deployment \
        --region "${self.triggers.region}" || true

      echo "Waiting max 90 seconds only – then forcing delete anyway..."
      timeout 90 aws ecs wait services-inactive \
        --cluster "${self.triggers.cluster_name}" \
        --services "${self.triggers.service_name}" \
        --region "${self.triggers.region}" || true

      # THIS IS THE KEY LINE THAT MAKES IT NEVER HANG:
      echo "Force-deleting the service itself (safe during destroy)"
      aws ecs delete-service \
        --cluster "${self.triggers.cluster_name}" \
        --service "${self.triggers.service_name}" \
        --force \
        --region "${self.triggers.region}" || true
    EOT
  }

  depends_on = [aws_ecs_service.ecs_service]
}