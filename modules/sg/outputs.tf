output "security_group_db_id" {
  value = [aws_security_group.db.id]
}

output "security_group_nfs_id" {
  value = [aws_security_group.nfs.id]
}

output "security_group_app_id" {
  value = [aws_security_group.app.id]
}