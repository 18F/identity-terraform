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
  type        = list(string)
  default     = []
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

  user_data = var.user_data

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

  dynamic "block_device_mappings" {
    for_each = var.block_device_mappings
    content {
      device_name  = lookup(block_device_mappings.value, "device_name", null)
      no_device    = lookup(block_device_mappings.value, "no_device", null)
      virtual_name = lookup(block_device_mappings.value, "virtual_name", null)

      dynamic "ebs" {
        for_each = lookup(block_device_mappings.value, "ebs", [])
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

