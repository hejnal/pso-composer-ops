# Cloud Composer IAM bindings
resource "google_project_iam_member" "iam_cloud_composer_custom_service_account_composer_worker" {
  depends_on = [
    google_service_account.composer-sa
  ]
  project =  module.main_project.project_id
  member   = format("serviceAccount:%s", google_service_account.composer-sa.email)
  role     = "roles/composer.worker"
}

resource "google_service_account_iam_member" "iam_cloud_composer_service_account_agent" {
  depends_on = [
    google_service_account.composer-sa
  ]
  service_account_id = google_service_account.composer-sa.name
  role = "roles/composer.ServiceAgentV2Ext"
  member = format("serviceAccount:%s", "service-${module.main_project.number}@cloudcomposer-accounts.iam.gserviceaccount.com")
}

resource "google_project_iam_binding" "iam_cloud_composer_service_account_user_role" {
  depends_on = [
    google_service_account.composer-sa
  ]
  project = module.main_project.project_id
  role    = "roles/iam.serviceAccountUser"
    members = [
        format("serviceAccount:%s", google_service_account.composer-sa.email)
    ]
}

locals {
  source_root_dir = "./"
}

resource "google_composer_environment" "cloud_composer_environment" {
  depends_on = [
    google_service_account.composer-sa,
    google_service_account_iam_member.iam_cloud_composer_service_account_agent,
    google_project_iam_member.iam_cloud_composer_custom_service_account_composer_worker,
    google_project_iam_binding.iam_cloud_composer_service_account_user_role
  ]
  project = module.main_project.project_id
  name    = "${var.prefix}-orchestration"
  region  = var.region
  config {
    software_config {
      airflow_config_overrides = var.composer_config.software_config.airflow_config_overrides
      pypi_packages            = var.composer_config.software_config.pypi_packages
      env_variables = var.composer_config.software_config.env_variables
      image_version = var.composer_config.software_config.image_version
    }
    workloads_config {
      scheduler {
        cpu        = var.composer_config.workloads_config.scheduler.cpu
        memory_gb  = var.composer_config.workloads_config.scheduler.memory_gb
        storage_gb = var.composer_config.workloads_config.scheduler.storage_gb
        count      = var.composer_config.workloads_config.scheduler.count
      }
      web_server {
        cpu        = var.composer_config.workloads_config.web_server.cpu
        memory_gb  = var.composer_config.workloads_config.web_server.memory_gb
        storage_gb = var.composer_config.workloads_config.web_server.storage_gb
      }
      worker {
        cpu        = var.composer_config.workloads_config.worker.cpu
        memory_gb  = var.composer_config.workloads_config.worker.memory_gb
        storage_gb = var.composer_config.workloads_config.worker.storage_gb
        min_count  = var.composer_config.workloads_config.worker.min_count
        max_count  = var.composer_config.workloads_config.worker.max_count
      }
    }

    environment_size = var.composer_config.environment_size

    node_config {
      network              = var.network_config.network_self_link
      subnetwork           = var.network_config.subnet_self_link
      service_account      = google_service_account.composer-sa.email
      enable_ip_masq_agent = true
      tags                 = ["composer-worker"]
      ip_allocation_policy {
        cluster_secondary_range_name  = var.network_config.composer_ip_ranges.pods_range_name
        services_secondary_range_name = var.network_config.composer_ip_ranges.services_range_name
      }
    }
    private_environment_config {
      enable_private_endpoint              = "true"
      cloud_sql_ipv4_cidr_block            = var.network_config.composer_ip_ranges.cloud_sql
      master_ipv4_cidr_block               = var.network_config.composer_ip_ranges.gke_master
      cloud_composer_connection_subnetwork = var.network_config.composer_ip_ranges.connection_subnetwork
    }
  }
}


resource "google_composer_environment" "failover_cloud_composer_environment" {
  count = var.has_dr_occurred ? 1 : 0

  depends_on = [
    google_service_account.composer-sa,
    google_service_account_iam_member.iam_cloud_composer_service_account_agent,
    google_project_iam_member.iam_cloud_composer_custom_service_account_composer_worker,
    google_project_iam_binding.iam_cloud_composer_service_account_user_role
  ]
  project = module.main_project.project_id
  name    = "${var.prefix}-orchestration-failover"
  region  = var.dr_region
  config {
    software_config {
      airflow_config_overrides = var.composer_config.software_config.airflow_config_overrides
      pypi_packages            = var.composer_config.software_config.pypi_packages
      env_variables = var.composer_config.software_config.env_variables
      image_version = var.composer_config.software_config.image_version
    }
    workloads_config {
      scheduler {
        cpu        = var.composer_config.workloads_config.scheduler.cpu
        memory_gb  = var.composer_config.workloads_config.scheduler.memory_gb
        storage_gb = var.composer_config.workloads_config.scheduler.storage_gb
        count      = var.composer_config.workloads_config.scheduler.count
      }
      web_server {
        cpu        = var.composer_config.workloads_config.web_server.cpu
        memory_gb  = var.composer_config.workloads_config.web_server.memory_gb
        storage_gb = var.composer_config.workloads_config.web_server.storage_gb
      }
      worker {
        cpu        = var.composer_config.workloads_config.worker.cpu
        memory_gb  = var.composer_config.workloads_config.worker.memory_gb
        storage_gb = var.composer_config.workloads_config.worker.storage_gb
        min_count  = var.composer_config.workloads_config.worker.min_count
        max_count  = var.composer_config.workloads_config.worker.max_count
      }
    }

    environment_size = var.composer_config.environment_size

    node_config {
      network              = var.network_config.network_self_link
      subnetwork           = var.network_config.subnet_self_link
      service_account      = google_service_account.composer-sa.email
      enable_ip_masq_agent = true
      tags                 = ["composer-worker"]
      ip_allocation_policy {
        cluster_secondary_range_name  = var.network_config.composer_failover_ip_ranges.pods_range_name
        services_secondary_range_name = var.network_config.composer_failover_ip_ranges.services_range_name
      }
    }
    private_environment_config {
      enable_private_endpoint              = "true"
      cloud_sql_ipv4_cidr_block            = var.network_config.composer_failover_ip_ranges.cloud_sql
      master_ipv4_cidr_block               = var.network_config.composer_failover_ip_ranges.gke_master
      cloud_composer_connection_subnetwork = var.network_config.composer_failover_ip_ranges.connection_subnetwork
    }
  }

  # Create provisioners are run after the resource is created
  provisioner "local-exec" {
    when = create
    command = <<EOT
bash ${local.source_root_dir}scripts/toggle_all_dags_primary.sh \
  --project ${module.main_project.project_id} \
  --environment ${google_composer_environment.cloud_composer_environment.name} \
  --location ${var.region} \
  --operation pause \
&& bash ${local.source_root_dir}scripts/composer_snapshot_manager.sh \
  --project ${module.main_project.project_id} \
  --environment ${google_composer_environment.failover_cloud_composer_environment[0].name} \
  --location ${var.dr_region} \
  --snapshot_bucket ${module.snapshot-bucket.bucket.name} \
  --operation restore
EOT
    working_dir = local.source_root_dir
    interpreter = ["bash", "-c"]
  }
}