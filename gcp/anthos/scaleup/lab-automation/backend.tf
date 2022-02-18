terraform {
  backend "gcs" {
    bucket  = "pm-gcp-anthos-terraform"
    prefix      = "terraform"
    credentials = "creds/ctx-anthos-terraform.json"
  }
}