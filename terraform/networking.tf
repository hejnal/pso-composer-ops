
module "default_vpc" {
  source     = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc"
  project_id = module.main_project.project_id
  name       = "default"
  subnets = [{
    ip_cidr_range = "10.1.0.0/24"
    name          = "default"
    region        = var.region
    secondary_ip_ranges = {
      pods = "10.0.128.0/17"
      services = "10.1.4.0/22"
      pods-failover = "10.1.128.0/17"
      services-failover = "10.2.4.0/22"
      gke-europe-west1-most-recent-co-5903344d-gke-pods-64dd3d34 = "10.154.128.0/17"
    }
  }]
}

module "default_firewall" {
  source       = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-vpc-firewall"
  project_id   = module.main_project.project_id
  network      = module.default_vpc.name
  default_rules_config = {
    admin_ranges = [module.default_vpc.subnet_ips["${var.region}/default"]]
  }
  ingress_rules = {
    ntp-svc = {
      description          = "NTP service."
      direction            = "INGRESS"
      action               = "allow"
      sources              = []
      ranges               = [var.my_home_ip_address]
      targets              = []
      use_service_accounts = false
      rules                = [{ protocol = "tcp", ports = [22, 5432, 3389] }]
      extra_attributes     = {}
    }
  }
}

module "default_nat" {
  source         = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/net-cloudnat"
  project_id     = module.main_project.project_id
  region         = var.region
  name           = "default"
  router_network = module.default_vpc.self_link
}