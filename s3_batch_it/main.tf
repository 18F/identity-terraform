# -- Variables --
variable "bucket_list" {
  description = "List of bucket names to be configured with Intelligent Tiering."
  type        = list(string)
  default     = []
}

# -- Resources --

resource "aws_s3_bucket" "bucket" {
  for_each = toset(var.bucket_list)
  bucket = each.key
  lifecycle_rule {
    id = "IntelligentTieringArchive"
    enabled = true
    transition {
      storage_class = "INTELLIGENT_TIERING"
      days = 0
    }
    noncurrent_version_transition {
      storage_class = "INTELLIGENT_TIERING"
      days = 0 
    }
  }
}