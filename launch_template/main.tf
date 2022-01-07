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

# ----

resource "aws_launch_template" "template" {
  name = "${var.env}-${var.role}"

  iam_instance_profile {
    name = var.iam_instance_profile_name
  }

  image_id = lookup(var.ami_id_map, var.role, var.default_ami_id)

  instance_initiated_shutdown_behavior = var.instance_initiated_shutdown_behavior

  instance_type = var.instance_type

  dynamic "instance_market_options" {
    for_each = var.use_spot_instances == 1 ? [1] : []

    content {
      market_type = "spot"

      # ASG will take care of replacing terminated instances
      spot_options {
        spot_instance_type = "one-time"
      }
    }
  }

  user_data = var.user_data

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = var.metadata_response_hop_limit
  }

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = var.security_group_ids

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name   = "asg-${var.env}-${var.role}"
      prefix = var.role
      domain = "${var.env}.${var.root_domain}"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name   = "asg-${var.env}-${var.role}"
      prefix = var.role
      domain = "${var.env}.${var.root_domain}"
    }
  }

  tags = merge(
    {
      "prefix" = var.role
      "domain" = "${var.env}.${var.root_domain}"
    },
    var.template_tags,
  )

  # TF12 syntax requires using a dynamic block in order to set var.block_device_mappings
  # to the resource's block_device_mappings, hence this complex block-in-block.
  # This logic is used to pass through block_device_mappings unchanged.
  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = lookup(block_device_mappings.value, "device_name", null)
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = flatten(list(lookup(block_device_mappings.value, "ebs", [])))
        content {
          delete_on_termination = lookup(ebs.value, "delete_on_termination", null)
          encrypted             = lookup(ebs.value, "encrypted", null)
          iops                  = lookup(ebs.value, "iops", null)
          kms_key_id            = lookup(ebs.value, "kms_key_id", null)
          snapshot_id           = lookup(ebs.value, "snapshot_id", null)
          volume_size           = lookup(ebs.value, "volume_size", null)
          volume_type           = lookup(ebs.value, "volume_type", null)
        }
      }
    }
  }
}

output "template_id" {
  value = aws_launch_template.template.id
}

output "template_name" {
  value = aws_launch_template.template.name
}

