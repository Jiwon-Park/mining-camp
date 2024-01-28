resource "aws_s3_bucket_lifecycle_configuration" "minecraft" {
  bucket = var.minecraft["bucket_name"]
  rule {
    id = "general"
    status = "Enabled"
    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
  }
  rule {
    id = "backup pruning"
    status = "Enabled"
    filter{
      tag{
        key = "backup"
        value = "old"
      }
    }
    expiration {
      days = 3
    }
  }
  
}
