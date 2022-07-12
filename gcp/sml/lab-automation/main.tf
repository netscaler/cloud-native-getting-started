data "google_client_config" "current" {}

# Create GKE Service Account
resource "google_service_account" "ctx_lab" {
  account_id   = "${var.basename}-cluster"
  display_name = "Service Account for the CTX GKE Cluster"
}

# Create GKE Cluster
resource "google_container_cluster" "ctx_lab" {
  name                     = "${var.basename}-cluster"
  location                 = var.zone
  remove_default_node_pool = true
  initial_node_count       = 1

  network_policy {
    enabled  = true
    provider = "CALICO"
  }
  addons_config {
    network_policy_config {
      disabled = false
    }
  }

}

# Create GKE Node Pool
resource "google_container_node_pool" "ctx_nodes" {
  name       = "${var.basename}-nodes"
  location   = var.zone
  cluster    = google_container_cluster.ctx_lab.name
  initial_node_count       = 1


  autoscaling {
    # Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count.
    min_node_count = 1

    # Maximum number of nodes in the NodePool. Must be >= min_node_count.
    max_node_count = var.max_node_count
  }

  node_config {
    preemptible  = var.preemptible
    machine_type = var.node_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.ctx_lab.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  lifecycle {
    ignore_changes = [
      initial_node_count
    ]
  }

}

resource "local_file" "get_ca" {
  content  = base64decode(google_container_cluster.ctx_lab.master_auth[0].cluster_ca_certificate)
  filename = "${path.module}/creds/cluster_ca.pem"
}


output "cluster_details" {
  value = "gcloud container clusters get-credentials ${var.basename}-cluster --zone ${var.zone} --project ${var.project}"
  description = "The command used to obtain credentials for the new GKE Cluster"
}