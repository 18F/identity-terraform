variable "name" {
  description = "Unique name to use for resources"
  type        = string
  default     = "snow_incident"
}

variable "topic_name" {
  description = "Topic name - Must be unique account+region"
  type        = string
  default     = "snow-incident"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.8"
}

variable "snow_incident_url" {
  description = "ServiceNow Incident URL"
  type        = string
}

variable "snow_caller_id" {
  description = "ServiceNow caller ID"
  type        = string
}

variable "snow_category_id" {
  description = "ServiceNow incident category ID"
  type        = string
}

variable "snow_subcategory_id" {
  description = "ServiceNow incident subcategory ID"
  type        = string
}

variable "snow_item_id" {
  description = "ServiceNow item ID for incident"
  type        = string
}

variable "snow_parameter_base" {
  description = "Base path in SSM Parameter Store to pull settings from"
  type        = string
  default     = "/account/snow_incident"
}
