# Create an IAM role for the application with an assume role policy
resource "aws_iam_role" "app" {
  name               = "app"  # Name of the IAM role
  path               = "/"    # Path in which the role is created
  assume_role_policy = data.aws_iam_policy_document.assume_role.json  # Assume role policy document that grants permission to assume this role
}

# Attach policies to the "app" IAM role
resource "aws_iam_role_policy_attachments_exclusive" "app" {
  role_name = aws_iam_role.app.name  # Attach policies to the "app" role
  policy_arns = [
    data.aws_iam_policy.ssm_managed.arn,  # Attach the SSM managed policy to the role
    data.aws_iam_policy.database.arn      # Attach the Database policy to the role
  ]
}

# Create an IAM role for web hosting with an assume role policy
resource "aws_iam_role" "web_hosting" {
  name               = "web_hosting"  # Name of the IAM role
  path               = "/"            # Path in which the role is created
  assume_role_policy = data.aws_iam_policy_document.assume_role.json  # Assume role policy document for this role
}

# Attach policies to the "web_hosting" IAM role
resource "aws_iam_role_policy_attachments_exclusive" "web_hosting" {
  role_name = aws_iam_role.web_hosting.name  # Attach policies to the "web_hosting" role
  policy_arns = [
    data.aws_iam_policy.ssm_managed.arn,     # Attach the SSM managed policy to the role
    data.aws_iam_policy.s3_ReadOnly.arn      # Attach the S3 ReadOnly policy to the role (Read-only access to S3)
  ]
}

# Create an instance profile for the "app" IAM role, which allows EC2 instances to assume the role
resource "aws_iam_instance_profile" "app" {
  name = "app-profile"  # Name of the instance profile
  role = aws_iam_role.app.name  # Link to the "app" IAM role to associate it with the profile
}

# Create an instance profile for the "web_hosting" IAM role, which allows EC2 instances to assume the role
resource "aws_iam_instance_profile" "web_hosting" {
  name = "web-hosting-profile"  # Name of the instance profile
  role = aws_iam_role.web_hosting.name  # Link to the "web_hosting" IAM role to associate it with the profile
}
