environment    = "prod"
project_name   = "easymart"
location       = "australiaeast"
databricks_sku = "premium"

cluster_config = {
  spark_version           = "" # Pin to a specific string like "15.4.x-scala2.12" for strict prod stability
  node_type_id            = "Standard_D4ds_v6"
  driver_node_type_id     = "Standard_D4ds_v6"
  autotermination_minutes = 30
  min_workers             = 1
  max_workers             = 1
  spot_bid_max_price      = -1

  #node_type_id            = "Standard_DS4_v2"
  #driver_node_type_id     = "Standard_DS4_v2"
  #autotermination_minutes = 60
  #min_workers             = 2
  #max_workers             = 8
  #spot_bid_max_price      = 0 # 0 forces 100% On-Demand VMs

  spark_conf = {
    "spark.sql.adaptive.enabled" = "true"
  }
}

storage_config = {
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  container_name           = "landing"
  soft_delete_days         = 7
}

unity_catalog_config = {
  schema_name    = "landing"
  volume_name    = "blob_source"
  volume_type    = "EXTERNAL" # "MANAGED" or "EXTERNAL"
  volume_folders = ["incoming", "processed", "archive"]
}

tags = {
  CostCenter = "Data-Engineering-Prod"
}
