module "main_project" {
  source          = "github.com/GoogleCloudPlatform/cloud-foundation-fabric/modules/project"
  parent          = var.root_node
  billing_account = var.billing_account_id
  prefix          = var.prefix
  name            = "mercadona-data-platform"
  iam_bindings_additive = {
    role-owner = {
        member = var.owners[0]
        role = "roles/owner"
    }
  }
  services        = [
    "bigquery.googleapis.com",
    "storage.googleapis.com",
    "composer.googleapis.com"
  ]
}