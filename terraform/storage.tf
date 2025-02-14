module "snapshot-bucket" {
  source        = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/gcs"
  project_id    = module.main_project.project_id
  name          = "${module.main_project.project_id}-cloud-composer-snapshots"
  location      = var.region
  storage_class = "STANDARD"
  force_destroy = true
}
