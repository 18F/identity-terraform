variable "role" {
}

variable "env" {
  description = "Environment name"
}

variable "root_domain" {
}

variable "ami_id_map" {
  description = "Mapping from role names to AMI IDs"
  type        = map(string)
}

variable "default_ami_id" {
  description = "AMI ID to use if the role is not found in the map"
}

variable "instance_type" {
}

variable "instance_initiated_shutdown_behavior" {
  default = "terminate"
}

variable "iam_instance_profile_name" {
}

variable "user_data" {
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_tags" {
  description = "Tags to apply to the launched instances"
  type        = map(string)
  default     = {}
}

variable "template_tags" {
  description = "Tags to apply to the launch template"
  type        = map(string)
  default     = {}
}

variable "block_device_mappings" {
  description = "EBS or other block devices to map on created instances. https://www.terraform.io/docs/providers/aws/r/launch_template.html#block-devices"
  type        = list(any)
  default     = []
}

variable "use_spot_instances" {
  description = "Use spot instances - Only suitable if one or more terminated instances are acceptable"
  type        = number
  default     = 0
}

variable "metadata_response_hop_limit" {
  description = "Desired HTTP PUT response hop limit for instance metadata requests. You might need a larger hop limit for backward compatibility with container services running on the instance."
  type        = number
  default     = 1
}
