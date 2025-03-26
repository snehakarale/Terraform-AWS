output "lb_dns_name" {
  value = aws_lb.mission_app.dns_name
}


output "lb_target_group_arn" {
  value = [aws_lb_target_group.mission_app.arn]
}

