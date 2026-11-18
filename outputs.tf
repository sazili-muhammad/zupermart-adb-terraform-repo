output "resource_group_name" {
  description = "Name of the created Azure Resource Group"
  value       = azurerm_resource_group.this.name
}

output "storage_account_name" {
  description = "Globally unique name of the ADLS Gen2 Storage Account"
  value       = azurerm_storage_account.this.name
}

output "storage_primary_dfs_endpoint" {
  description = "Primary Data Lake Storage Gen2 (abfss) endpoint"
  value       = azurerm_storage_account.this.primary_dfs_endpoint
}

output "storage_container_name" {
  description = "Name of the default storage container"
  value       = azurerm_storage_container.this.name
}

output "databricks_workspace_id" {
  description = "Azure Resource ID of the Databricks workspace"
  value       = azurerm_databricks_workspace.this.id
}

output "databricks_workspace_url" {
  description = "URL to access the Azure Databricks workspace UI"
  value       = "https://${azurerm_databricks_workspace.this.workspace_url}"
}

output "databricks_cluster_id" {
  description = "ID of the provisioned Databricks compute cluster"
  value       = databricks_cluster.this.id
}

output "resolved_spark_version" {
  description = "Spark runtime version assigned to the cluster"
  value       = databricks_cluster.this.spark_version
}

output "access_connector_id" {
  description = "Azure Resource ID of the Databricks Unity Catalog Access Connector"
  value       = data.azurerm_databricks_access_connector.unity_catalog.id
}

output "access_connector_principal_id" {
  description = "System-assigned Managed Identity Principal ID of the Access Connector"
  value       = data.azurerm_databricks_access_connector.unity_catalog.identity[0].principal_id
}

output "access_connector_assigned_roles" {
  description = "IAM roles assigned to the Unity Catalog Access Connector on the storage account"
  value       = [for r in azurerm_role_assignment.uc_storage_roles : r.role_definition_name]
}

output "unity_catalog_volume_full_name" {
  description = "Three-level Unity Catalog namespace for the volume"
  value       = "${databricks_catalog.this.name}.${databricks_schema.this.name}.${databricks_volume.this.name}"
}

output "unity_catalog_volume_posix_path" {
  description = "File path to access the volume inside Databricks notebooks and jobs"
  value       = "/Volumes/${databricks_catalog.this.name}/${databricks_schema.this.name}/${databricks_volume.this.name}"
}

output "unity_catalog_volume_folders" {
  description = "List of created directory paths inside the Unity Catalog volume"
  value       = [for folder in var.unity_catalog_config.volume_folders : "${databricks_volume.this.volume_path}/${folder}"]
}
