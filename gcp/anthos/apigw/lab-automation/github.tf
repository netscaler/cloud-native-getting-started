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
This is the repo containing the manifests for API Gateway Lab. This repo contains two folders, one for Anthos Config Management (acm), and one for the sample application (demoapp).
                        EOF
  commit_message      = "Terraform commit"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# This block processes all static files in the `acm_files` directory that are present at the time of plan. 
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

# This block processes all static files in the `demoapp` directory that are present at the time of plan. 
resource "github_repository_file" "demo_app_static_files" {
  for_each            = fileset("${path.module}/demoapp/", "**")
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "demoapp/${each.key}"
  content             = file("demoapp/${each.key}")
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
    image = var.ingress_controller_image,
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

# Dynamically rendered demoapp vpx ingress file
resource "github_repository_file" "demoapp_vpx_ingress" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "demoapp/vpx-ingress.yaml"
  content             = templatefile("${path.module}/templates/vpx-ingress.yaml.tpl", {
    demo_app_url_1 = var.demo_app_url_1,
    demo_app_url_2 = var.demo_app_url_2,
    demo_app_url_3 = var.demo_app_url_3
  })
  commit_message      = "Terraform commit - vpx-ingress"
  commit_author       = "Terraform"
  commit_email        = "terraform@example.com"
  overwrite_on_create = true
}

# Dynamically rendered demoapp cpx ingress file
resource "github_repository_file" "demoapp_cpx_ingress" {
  repository          = github_repository.ctx_acm.name
  branch              = "main"
  file                = "demoapp/cpx-ingress.yaml"
  content             = templatefile("${path.module}/templates/cpx-ingress.yaml.tpl", {
    demo_app_url_1 = var.demo_app_url_1,
    demo_app_url_2 = var.demo_app_url_2,
    demo_app_url_3 = var.demo_app_url_3
  })
  commit_message      = "Terraform commit - cpx-ingress"
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