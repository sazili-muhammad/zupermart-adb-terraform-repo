variable "environment" {
  description = "Target deployment environment (app, dev or prod)"
  type        = string

  validation {
    condition     = contains(["dev", "app", "prod"], var.environment)
    error_message = "Environment must be either 'dev', 'app', or 'prod'."
  }
}

variable "project_name" {
  description = "Base project prefix used for resource naming"
  type        = string
  default     = "personal"
}

variable "location" {
  description = "Azure region for the resource group and workspace"
  type        = string
  default     = "australiaeast"
}

variable "databricks_sku" {
  description = "Azure Databricks pricing tier (standard, premium, or trial)"
  type        = string
  default     = "premium"
}

variable "storage_config" {
  description = "Dynamic configuration parameters for the ADLS Gen2 Storage Account"
  type = object({
    account_tier             = string
    account_replication_type = string
    container_name           = string
    soft_delete_days         = number
  })
}

variable "cluster_config" {
  description = "Dynamic configuration parameters for the Databricks cluster"
  type = object({
    spark_version           = optional(string, "")
    node_type_id            = string
    driver_node_type_id     = string
    autotermination_minutes = number
    min_workers             = number
    max_workers             = number
    spot_bid_max_price      = number
    spark_conf              = optional(map(string), {})
  })
}

variable "unity_catalog_config" {
  description = "Configuration for Unity Catalog storage credential, external location, catalog, schema, and volume"
  type = object({
    catalog_name   = optional(string, "")
    schema_name    = string
    volume_name    = string
    volume_type    = optional(string, "MANAGED") # "MANAGED" or "EXTERNAL"
    volume_folders = optional(list(string), [])
  })
}

variable "tags" {
  description = "Additional tags applied to Azure resources"
  type        = map(string)
  default     = {}
}
