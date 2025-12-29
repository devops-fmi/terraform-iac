# Network Load Balancer for exposing cluster services
resource "aws_lb" "eks_nlb" {
  name                       = "external-eks-nlb"
  internal                   = false
  load_balancer_type         = "network"
  subnets                    = var.subnet_ids
  enable_deletion_protection = false

  tags = {
    Name = "external-eks-nlb"
  }
}

# Target group for NLB
resource "aws_lb_target_group" "eks_tg" {
  name        = "eks-nlb-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
    path                = "/"
    port                = "80"
  }

  tags = {
    Name = "eks-nlb-tg"
  }
}

# NLB Listener for HTTP
resource "aws_lb_listener" "eks_http" {
  load_balancer_arn = aws_lb.eks_nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.eks_tg.arn
  }
}
