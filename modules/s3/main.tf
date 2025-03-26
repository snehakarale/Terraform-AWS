# Create an S3 bucket for storing items related to the mission app
resource "aws_s3_bucket" "mission_app" {
  # Set a prefix for the bucket name based on the namespace variable
  bucket_prefix = "${var.namespace}-mission-app-"  

  # Add tags to the S3 bucket for descriptive purposes
  tags = {
    Description = "Used to store items"  # Tag to describe the purpose of the bucket
  }
}

# Create a public access block for the S3 bucket to prevent public access
resource "aws_s3_bucket_public_access_block" "mission_app" {
  # Link the public access block configuration to the previously created S3 bucket
  bucket = aws_s3_bucket.mission_app.bucket  

  # Block public ACLs (Access Control Lists), ensuring that no objects are publicly accessible
  block_public_acls       = true

  # Block public policies that could potentially expose the S3 bucket or its objects
  block_public_policy     = true

  # Ignore public ACLs on objects, meaning the bucket and its objects are not publicly accessible even if the ACLs are set to public
  ignore_public_acls      = true

  # Restrict access to the bucket to prevent it from being publicly accessible
  restrict_public_buckets = true
}
