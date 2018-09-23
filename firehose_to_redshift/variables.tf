variable "env_name" {
    description = "Environment Name"
}

variable "region" {
    description = "AWS region"
}

variable "stream_name" {
    description = "Firehose delivery stream name"
}

variable "redshift_jdbc" {
    description = "Redshift jdbc connection"
}

variable "redshift_user" {
    description = "Redshift database user"
}

variable "redshift_password" {
    description = "Redshift database password"
}

variable "redshift_table" {
    description = "Redshift table"
}

variable "copy_options" {
    description = "Copy options for Redshift"
}

variable "columns" {
    description = "Comma separated list of columns for copy"
}

