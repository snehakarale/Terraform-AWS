# Output for the database name
output "db_name" {
  value       = aws_db_instance.wp_mysql.db_name
  description = "The name of the RDS database"
}

# Output for the database username
output "db_username" {
  value       = aws_db_instance.wp_mysql.username
  description = "The username for the RDS database"
}

# Output for the database password (from Secrets Manager)
output "db_password" {
  value       = aws_secretsmanager_secret_version.db.secret_string
  sensitive   = true
  description = "The password for the RDS database"
}

# Output for the database host (endpoint address)
output "db_host" {
  value       = aws_db_instance.wp_mysql.address
  description = "The host (endpoint) address of the RDS database"
}
