resource "google_project_service" "project" {
  project = var.gcp_project_name
  service = "vision.googleapis.com"

  disable_dependent_services = true
}

resource "google_service_account" "service_account" {
  account_id   = "acg-challenge-service-account"
  display_name = "ACG Challenge Account"
}

resource "google_service_account_key" "key" {
  service_account_id = google_service_account.service_account.name
}

resource "aws_ssm_parameter" "acg_challenge_service_account" {
  name  = "acg_challenge_service_account"
  type  = "SecureString"
  value = base64decode(google_service_account_key.key.private_key)
}
