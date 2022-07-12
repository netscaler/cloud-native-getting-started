terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
    google = {
      source = "hashicorp/google"
      version = "4.15.0"
    }
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.15.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  owner = var.github_owner
}

provider "google" {
  project     = var.project
  credentials = "creds/ctx-bcom.json"
  region = var.region
}

provider "google-beta" {
  project     = var.project
  credentials = "creds/ctx-bcom.json"
  region = var.region
}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.ctx_lab.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.ctx_lab.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}
