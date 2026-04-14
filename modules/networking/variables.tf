variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "Map of subnet names to CIDR prefixes"
  type        = map(string)
}

variable "tags" {
  description = "Resource tags to apply to networking resources"
  type        = map(string)
  default     = {}
}
