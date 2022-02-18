# GitHub Repo Creation

resource "github_repository" "ctx_acm" {
  name        = var.github_reponame
  description = "CTX Lab ACM Repo"

  visibility = "private"
  auto_init  = true
}

resource "github_repository_file" "readme" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "README.md"
  content             = <<EOF
# Configuration Repository
This is the repo containing ACM configurations as well as the manifests for the demo application. This repo contains two folders, one for Anthos Config Management (acm), and one for the sample application (online-boutique).
                        EOF
  commit_message      = "Terraform commit"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# This block processes all static files in the `files` directory that are present at the time of plan. 
resource "github_repository_file" "acm_static_files" {
  for_each            = fileset("${path.module}/acm_files/", "**")
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/${each.key}"
  content             = file("acm_files/${each.key}")
  commit_message      = "Terraform commit - ${each.key}"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# This block processes all static files in the `files` directory that are present at the time of plan. 
resource "github_repository_file" "online_boutique_static_files" {
  for_each            = fileset("${path.module}/online-boutique/", "**")
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/namespaces/online-boutique/${each.key}"
  # file                = "online-boutique/${each.key}"
  content             = file("online-boutique/${each.key}")
  commit_message      = "Terraform commit - ${each.key}"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Dynamically rendered files need their own resource.
resource "github_repository_file" "cic-deployment" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/namespaces/ctx-ingress/cic-deployment.yaml"
  content             = templatefile("${path.module}/templates/cic-deployment.yaml.tpl", {
    ns_ip = google_compute_instance_from_template.vpx-01.network_interface.0.network_ip,
    new_password = var.vpx_new_password,
    ns_vip = google_compute_instance_from_template.vpx-01.network_interface.1.network_ip

  })
  commit_message      = "Terraform commit - cic-deployment"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

resource "github_repository_file" "cnc-deployment" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/namespaces/ctx-ingress/cnc-deployment.yaml"
  content             = templatefile("${path.module}/templates/cnc-deployment.yaml.tpl", {
    ns_ip = google_compute_instance_from_template.vpx-01.network_interface.0.network_ip,
    new_password = var.vpx_new_password

  })
  commit_message      = "Terraform commit - cnc-deployment"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Dynamically rendered online-boutique loadgen files
resource "github_repository_file" "online_boutique_ingress" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/namespaces/online-boutique/ingress.yaml"
  # file                = "online-boutique/ingress.yaml"
  content             = templatefile("${path.module}/templates/online-boutique-ingress.yaml.tpl", {
    demo_app_url = "${google_compute_instance_from_template.vpx-01.network_interface.1.access_config.0.nat_ip}.nip.io"
    #demo_app_url = var.demo_app_url
  })
  commit_message      = "Terraform commit - online-boutique-ingress"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

resource "github_repository_file" "online_boutique_loadgen" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "acm/namespaces/online-boutique/loadgen.yaml"
  # file                = "online-boutique/loadgen.yaml"
  content             = templatefile("${path.module}/templates/online-boutique-loadgen.yaml.tpl", {
    demo_app_url = "${google_compute_instance_from_template.vpx-01.network_interface.1.access_config.0.nat_ip}.nip.io",
    #demo_app_url = var.demo_app_url
    external_vip = google_compute_instance_from_template.vpx-01.network_interface.1.access_config.0.nat_ip

  })
  commit_message      = "Terraform commit - loadgen"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}


resource "tls_private_key" "ctx_acm" {
  algorithm = "RSA"
}

resource "github_repository_deploy_key" "ctx_acm" {
  title      = "${var.basename} key"
  repository = github_repository.ctx_acm.name
  key        = tls_private_key.ctx_acm.public_key_openssh
  read_only  = "true"
}