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
  description = "Map of tags to apply to all resources. Must include non-empty values for: environment, owner, cost_center."
  type        = map(string)

  validation {
    condition = alltrue([
      for key in ["environment", "owner", "cost_center"] :
      contains(keys(var.tags), key) && length(var.tags[key]) > 0
    ])
    error_message = "Tags must include non-empty values for: environment, owner, cost_center."
  }
}
