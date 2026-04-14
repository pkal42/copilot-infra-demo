variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-infra-demo"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "uksouth"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefixes" {
  description = "Address prefixes for subnets"
  type        = map(string)
  default = {
    app  = "10.0.1.0/24"
    db   = "10.0.2.0/24"
    mgmt = "10.0.3.0/24"
  }
}

variable "enable_diagnostics" {
  description = "Enable diagnostic settings"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Resource tags. Must include 'owner' and 'cost_center'. The 'environment' tag is auto-set from var.environment."
  type        = map(string)
  default     = {}

  validation {
    condition     = lookup(var.tags, "owner", "") != ""
    error_message = "The 'owner' tag is required and must not be empty."
  }

  validation {
    condition     = lookup(var.tags, "cost_center", "") != ""
    error_message = "The 'cost_center' tag is required and must not be empty."
  }
}
