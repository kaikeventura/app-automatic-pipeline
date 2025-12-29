output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "alb_zone_id" {
  value = aws_lb.this.zone_id
}

output "blue_target_group_arn" {
  value = aws_lb_target_group.blue.arn
}

output "blue_target_group_name" {
  value = aws_lb_target_group.blue.name
}

output "green_target_group_arn" {
  value = aws_lb_target_group.green.arn
}

output "green_target_group_name" {
  value = aws_lb_target_group.green.name
}

output "listener_arn" {
  # Retorna o listener HTTPS se existir, senão o HTTP (para compatibilidade)
  value = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : aws_lb_listener.http.arn
}
