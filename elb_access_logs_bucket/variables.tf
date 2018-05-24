variable "region" {
    description = "Region to create the secrets bucket in"
    default = "us-west-2"
}

variable "bucket_name_prefix" {
    description = "Base name for the secrets bucket to create"
}

variable "log_prefix" {
    description = "Prefix inside the bucket where access logs will go"
    default = "logs"
}

# This is optional to support the use case where multiple loadbalancers use the
# same S3 bucket with different log prefixes.
variable "use_prefix_for_permissions" {
    description = "Scope load balancer permissions by log_prefix"
    default = false
}

variable "force_destroy" {
    default = false
    description = "Allow destroy even if bucket contains objects"
}


variable "lifecycle_days_standard_ia" {
    description = "Number of days after object creation to move logs to Standard Infrequent Access. Set to 0 to disable."
    default = 60
}

variable "lifecycle_days_glacier" {
    description = "Number of days after object creation to move logs to Glacier. Set to 0 to disable."
    default = 365
}

variable "lifecycle_days_expire" {
    description = "Number of days after object creation to delete logs. Set to 0 to disable."
    default = 0
}
