output "iam_instance_profile_app" {
  value = aws_iam_instance_profile.app.name
}

output "iam_instance_profile_web_hosting" {
  value = aws_iam_instance_profile.web_hosting.name
}