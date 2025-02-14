variable "project_id" {
  description = "The project id to be created"
  type = string
}

variable "region" {
  description = "The region for resources and networking"
  type = string
}

variable "dr_region" {
  description = "The region for resources and networking"
  type = string
}

variable "organization" {
  description = "Organization for the project/resources"
  type = string
}

variable "prefix" {
  description = "Prefix used to generate project id and name."
  type        = string
  default     = null
}

variable "root_node" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
}

variable "billing_account_id" {
  description = "Billing account for the projects/resources"
  type = string
}

variable "owners" {
  description = "List of owners for the projects and folders"
  type = list(string)
}

variable "quota_project" {
  description = "Quota project used for admin settings"
  type = string
}

variable "my_home_ip_address" {
  description = "The public IP address of your computer to access private resources in the VPC"
  type = string
}

variable "network_config" {
  description = "Shared VPC network configurations to use."
  type = object({
    network_self_link = optional(string)
    subnet_self_link  = optional(string)
    composer_ip_ranges = optional(object({
      connection_subnetwork = optional(string)
      cloud_sql             = optional(string, "10.20.10.0/24")
      gke_master            = optional(string, "10.20.11.0/28")
      pods_range_name       = optional(string, "pods")
      services_range_name   = optional(string, "services")
    }), {})
    composer_failover_ip_ranges = optional(object({
      connection_subnetwork = optional(string)
      cloud_sql             = optional(string, "10.20.20.0/24")
      gke_master            = optional(string, "10.20.21.0/28")
      pods_range_name       = optional(string, "pods-failover")
      services_range_name   = optional(string, "services-failover")
    }), {})
  })
  nullable = false
  default  = {}
  validation {
    condition     = (var.network_config.composer_ip_ranges.cloud_sql == null) != (var.network_config.composer_ip_ranges.connection_subnetwork == null)
    error_message = "One, and only one, of `network_config.composer_ip_ranges.cloud_sql` or `network_config.composer_ip_ranges.connection_subnetwork` must be specified."
  }
}

variable "composer_config" {
  description = "Cloud Composer config."
  type = object({
    environment_size = optional(string, "ENVIRONMENT_SIZE_SMALL")
    software_config = optional(object({
      airflow_config_overrides = optional(map(string), {})
      pypi_packages            = optional(map(string), {})
      env_variables            = optional(map(string), {})
      image_version            = optional(string, "composer-2-airflow-2")
    }), {})
    web_server_access_control = optional(map(string), {})
    workloads_config = optional(object({
      scheduler = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
        count      = optional(number, 1)
        }
      ), {})
      web_server = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
      }), {})
      worker = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 1.875)
        storage_gb = optional(number, 1)
        min_count  = optional(number, 1)
        max_count  = optional(number, 3)
        }), {})
      triggerer = optional(object({
        cpu        = optional(number, 0.5)
        memory_gb  = optional(number, 0.5)
        count      = optional(number, 1)
        }), {})
    }), {})
  })
  nullable = false
  default  = {}
}

variable "has_dr_occurred" {
  description = "flag to determine if the DR has occured"
  type = bool
  default = false
}