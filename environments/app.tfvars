environment    = "app"
project_name   = "personal"
location       = "australiaeast"
databricks_sku = "premium"

storage_config = {
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  container_name           = "landing"
  soft_delete_days         = 7
}

cluster_config = {
  spark_version           = "" # Leave blank to automatically use the latest LTS runtime
  node_type_id            = "Standard_D4ds_v6"
  driver_node_type_id     = "Standard_D4ds_v6"
  autotermination_minutes = 30
  min_workers             = 1
  max_workers             = 1
  spot_bid_max_price      = 0

  spark_conf = {
    "spark.sql.adaptive.enabled" = "true"
  }
}

unity_catalog_config = {
  schema_name    = "landing"
  volume_name    = "blob_source"
  volume_type    = "EXTERNAL" # "MANAGED" or "EXTERNAL"
  volume_folders = ["incoming", "processed", "archive"]
}

tags = {
  CostCenter = "Data-Engineering-App"
}
