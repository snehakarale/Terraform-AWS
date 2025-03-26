# Create an RDS DB Subnet Group for the RDS instance
resource "aws_db_subnet_group" "mission_db_group" {
  name       = "${var.namespace}-db-group"  # Name of the DB subnet group
  subnet_ids = var.private_subnet_id  # List of subnet IDs where the RDS instances will reside

  # Tags for the DB subnet group
  tags = {
    Name = "${var.namespace}-db-group"  # Tag the DB subnet group with the namespace
  }
}

# Generate a random password for the database
resource "random_password" "default" {
  length           = 25  # Set the length of the generated password
  special          = false  # Do not include special characters by default
  override_special = "!#$%&*()-_=+[]{}<>:?"  # Define a custom set of special characters
}

# Create a Secrets Manager secret to store the database password
resource "aws_secretsmanager_secret" "db" {
  name_prefix             = "${var.namespace}-secret-db-"  # Prefix for the secret name
  description             = "Password to the RDS"  # Description for the secret
  recovery_window_in_days = 7  # Set the recovery window for the secret (time to restore or delete it)
}

# Store the database password in AWS Secrets Manager
resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id  # Reference the secret created above
  secret_string = random_password.default.result  # Store the generated random password
}

# Create an RDS MySQL instance
resource "aws_db_instance" "wp_mysql" {
  identifier = "${var.namespace}-db"  # Unique identifier for the DB instance

  # Storage and performance settings
  allocated_storage      = 20  # Allocated storage size (in GB)
  engine                 = local.rds.engine  # Database engine (e.g., MySQL, PostgreSQL)
  engine_version         = local.rds.engine_version  # Database engine version
  instance_class         = local.rds.instance_class  # Instance type (e.g., db.t2.micro)
  db_name                = local.rds.db_name  # Database name to be created on the instance
  username               = local.rds.username  # Master username for the DB
  password               = aws_secretsmanager_secret_version.db.secret_string  # Retrieve password from Secrets Manager
  db_subnet_group_name   = aws_db_subnet_group.mission_db_group.name  # DB subnet group to place the RDS instance in
  vpc_security_group_ids = var.security_group_db_id  # Security group IDs to attach to the DB instance
  multi_az               = true  # Enable Multi-AZ for high availability
  skip_final_snapshot    = true  # Skip final snapshot when deleting the DB instance (useful for testing)

  # Tags for the DB instance
  tags = {
    Name = "${var.namespace}-db"  # Tag the DB instance with the namespace for identification
  }
}
