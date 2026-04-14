subscription_id = "00000000-0000-0000-0000-000000000000"
environment     = "dev"
location        = "uksouth"

vnet_address_space = ["10.0.0.0/16"]

subnet_prefixes = {
  app  = "10.0.1.0/24"
  db   = "10.0.2.0/24"
  mgmt = "10.0.3.0/24"
}

enable_diagnostics = true
log_retention_days = 30
