locals {
    terraform_service_account = "TERRAFROM_SA_EMAIL"
}

provider "google-beta" {
    alias = "impersonation"
    scopes = [
        "https://www.googleapis.com/auth/cloud-platform",
        "https://www.googleapis.com/auth/userinfo.email",
    ]
}

data "google_service_account_access_token" "default" {
    provider               	= google-beta.impersonation
    target_service_account 	= local.terraform_service_account
    scopes                 	= ["userinfo-email", "cloud-platform"]
    lifetime               	= "1200s"
}

# Required if using User ADCs (Application Default Credentials) for Cloud Identity API.
# source: https://github.com/terraform-google-modules/terraform-google-group
provider "google-beta" {
    access_token = data.google_service_account_access_token.default.access_token
    region  = var.region
    billing_project = "BILLING_PROJECT_ID"
    user_project_override = true
}

provider "google" {
    access_token = data.google_service_account_access_token.default.access_token
    region  = var.region
    billing_project = "BILLING_PROJECT_ID"
    user_project_override = true
}

