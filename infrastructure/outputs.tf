# output "instance_hostname" {
#   description = "Private DNS name of the EC2 instance."
#   value       = aws_instance.app_server.private_dns
# }

output "cluster_name" {
  value = aws_ecs_cluster.cluster.arn
}

output "task_definition" {
  value = aws_ecs_task_definition.ecs_task_definition
}

output "alb_dns_name" {
  description = "Public DNS of the Application Load Balancer"
  value       = aws_lb.ecs_alb.dns_name
}