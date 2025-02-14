resource "google_project_iam_binding" "iam_whejna_compute_admin_role" {
  project =  module.main_project.project_id
  role    = "roles/compute.admin"
    members = [
        "user:whejna@google.com"
    ]
}

resource "google_service_account" "composer-sa" {
  project = module.main_project.project_id
  account_id   = "composer-sa"
  display_name = "Service Account for Cloud Composer"
}
