resource "google_compute_network" "vip_network" {
  name                    = "vip-network"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "vip_subnet" {
  name          = "vip-subnetwork"
  ip_cidr_range = var.vpx_vip_cidr_range
  region        = var.region
  network       = google_compute_network.vip_network.id
}

resource "google_compute_address" "vpx_vip_ip" {
  name = "vpx-vip-address"
}

resource "google_compute_address" "vpx_mgmt_ip" {
  name = "vpx-mgmt-address"
}

resource "google_compute_firewall" "nsip_firewall" {

  name          = "nsip-firewall"
  network       = "default"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags = ["http-server", "https-server"]
}

resource "google_compute_firewall" "vip_firewall" {
  depends_on = [
    google_compute_network.vip_network, 
    google_compute_subnetwork.vip_subnet
  ]

  name          = "vip-firewall"
  network       = google_compute_network.vip_network.name
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  target_tags = ["http-server", "https-server"]
}


resource "google_compute_instance_template" "vpx" {

  depends_on = [
    google_compute_network.vip_network, 
    google_compute_subnetwork.vip_subnet, 
    google_compute_image.vpx_image
  ]

  name        = "vpx"
  description = "Deploy a single instance of Citrix VPX"

  instance_description = "vpx"
  machine_type         = "e2-medium"
  can_ip_forward       = true
  tags                 = ["http-server", "https-server"]


  scheduling {
    automatic_restart = false
    preemptible       = false
  }

  // Create a new boot disk from an image
  disk {
    source_image = "${var.project}/vpx"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
    }
  }

  network_interface {
    network    = "vip-network"
    subnetwork = "vip-subnetwork"
    access_config {
    }
  }

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.ctx_lab.email
    scopes = ["cloud-platform"]
  }
}


resource "google_compute_image" "vpx_image" {
  name   = "vpx"
  family = "citrix"

  raw_disk {
    source = var.vpx_image_path
  }

  guest_os_features {
    type = "MULTI_IP_SUBNET"
  }
}

resource "google_compute_instance_from_template" "vpx-01" {
  name = "vpx-01"
  zone = var.zone

  source_instance_template = google_compute_instance_template.vpx.id

  metadata_startup_script = templatefile("${path.module}/templates/vpx_startup.sh.tpl", {
    password = var.vpx_new_password
  })

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.vpx_mgmt_ip.address
    }
  }

  network_interface {
    network    = "vip-network"
    subnetwork = "vip-subnetwork"
    access_config {
      nat_ip = google_compute_address.vpx_vip_ip.address
    }
  }
}

output "vpx_public_mgmt_ip_address" {
  value       = "http://${google_compute_instance_from_template.vpx-01.network_interface.0.access_config.0.nat_ip}"
  description = "The Public IP address of the VPX instance for mangagement."
}

output "vpx_vip_address" {
  value       = google_compute_instance_from_template.vpx-01.network_interface.1.access_config.0.nat_ip
  description = "The Public IP address of the VPX for Client data."
}

output "demo_app" {
  value       = "http://${google_compute_instance_from_template.vpx-01.network_interface.1.access_config.0.nat_ip}.nip.io"
  description = "The demo application is accessible here."
}
