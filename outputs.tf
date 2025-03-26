output "alb_endpoint_uri" {
  #value = aws_lb.mission_app.dns_name
  value = module.lb_tls.lb_dns_name
}

output "alb_endpoint_url" {
  #value = "https://${aws_lb.mission_app.dns_name}"
  value = "https://${module.lb_tls.lb_dns_name}"
}

output "cloudfront_endpoint_url" {
  #value = "https://${aws_cloudfront_distribution.mission_app.domain_name}"
  value = "https://${module.cloudfront.domain_name}"
}