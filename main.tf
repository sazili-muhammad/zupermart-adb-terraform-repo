locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform Databricks Module"
    },
    var.tags
  )

  uc_storage_roles = toset([
    "EventGrid EventSubscription Contributor",
    "Storage Account Contributor",
    "Storage Blob Data Contributor",
    "Storage Queue Data Contributor"
  ])
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_databricks_workspace" "this" {
  name                        = "adb-${local.name_prefix}"
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = var.databricks_sku
  managed_resource_group_name = "rg-${local.name_prefix}-adb-managed"
  tags                        = local.common_tags
}

data "azurerm_databricks_access_connector" "unity_catalog" {
  name                = "unity-catalog-access-connector"
  resource_group_name = azurerm_databricks_workspace.this.managed_resource_group_name
  depends_on          = [azurerm_databricks_workspace.this]
}

resource "azurerm_storage_account" "this" {
  name                            = "storageadb${var.project_name}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  account_tier                    = var.storage_config.account_tier
  account_replication_type        = var.storage_config.account_replication_type
  account_kind                    = "StorageV2"
  is_hns_enabled                  = true # Enables ADLS Gen2 Hierarchical Namespace
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  blob_properties {
    delete_retention_policy {
      days = var.storage_config.soft_delete_days
    }
    container_delete_retention_policy {
      days = var.storage_config.soft_delete_days
    }
  }

  tags = local.common_tags
}

resource "azurerm_storage_container" "this" {
  name                  = var.storage_config.container_name
  storage_account_id    = azurerm_storage_account.this.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "uc_storage_roles" {
  for_each = local.uc_storage_roles

  scope                = azurerm_storage_account.this.id
  role_definition_name = each.value
  principal_id         = data.azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
}

########################################################################

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
  depends_on        = [azurerm_databricks_workspace.this]
}

resource "databricks_cluster" "this" {
  cluster_name            = "cluster-${local.name_prefix}-shared"
  spark_version           = var.cluster_config.spark_version != "" ? var.cluster_config.spark_version : data.databricks_spark_version.latest_lts.id
  node_type_id            = var.cluster_config.node_type_id
  driver_node_type_id     = var.cluster_config.driver_node_type_id
  autotermination_minutes = var.cluster_config.autotermination_minutes
  data_security_mode      = "USER_ISOLATION"

  autoscale {
    min_workers = var.cluster_config.min_workers
    max_workers = var.cluster_config.max_workers
  }

  azure_attributes {
    availability       = var.cluster_config.spot_bid_max_price != 0 ? "SPOT_WITH_FALLBACK_AZURE" : "ON_DEMAND_AZURE"
    first_on_demand    = 1
    spot_bid_max_price = var.cluster_config.spot_bid_max_price
  }

  spark_conf = merge(
    {
      #"spark.databricks.cluster.profile" = "serverless"
      "spark.databricks.io.cache.enabled" : "true"
    },
    var.cluster_config.spark_conf
  )

  custom_tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# 1. Storage Credential linked to the Azure Databricks Access Connector
resource "databricks_storage_credential" "this" {
  name = "sc-${local.name_prefix}"

  azure_managed_identity {
    access_connector_id = data.azurerm_databricks_access_connector.unity_catalog.id
  }

  depends_on = [azurerm_role_assignment.uc_storage_roles]
}

# 2. External Location pointing to the ADLS Gen2 container
resource "databricks_external_location" "this" {
  name            = "extloc-${local.name_prefix}"
  url             = "abfss://${azurerm_storage_container.this.name}@${azurerm_storage_account.this.name}.dfs.core.windows.net/"
  credential_name = databricks_storage_credential.this.id
  comment         = "External location for ${var.environment} environment"
}

# 3. Unity Catalog (uses the External Location as its managed storage root)
resource "databricks_catalog" "this" {
  name         = "adb-${local.name_prefix}"
  storage_root = databricks_external_location.this.url
  comment      = "Catalog for ${var.environment} environment"
}

# 4. Schema inside the Catalog
resource "databricks_schema" "this" {
  catalog_name = databricks_catalog.this.id
  name         = var.unity_catalog_config.schema_name
  comment      = "Schema for ${var.environment} volumes and tables"
}

# 5. Unity Catalog Volume inside the Schema
resource "databricks_volume" "this" {
  name             = var.unity_catalog_config.volume_name
  catalog_name     = databricks_catalog.this.name
  schema_name      = databricks_schema.this.name
  volume_type      = var.unity_catalog_config.volume_type
  storage_location = var.unity_catalog_config.volume_type == "EXTERNAL" ? "${databricks_external_location.this.url}${var.unity_catalog_config.volume_name}" : null
  comment          = "Volume for unstructured files in ${var.environment}"
}

# A marker file is needed because object storage does not retain empty directories.
resource "databricks_file" "volume_folder_markers" {
  for_each = toset(var.unity_catalog_config.volume_folders)

  content_base64 = base64encode("Managed by Terraform.\n")
  path           = "${databricks_volume.this.volume_path}/${each.value}/.keep"
}
