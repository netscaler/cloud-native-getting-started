variable "project" {
  type = string
}

variable "basename" {
  type = string
}

variable "region" {
  type = string
}

variable "zone" {
  type = string
}


variable "preemptible" {
  type    = bool
  default = false
}

variable "node_type" {
  type = string
}

variable "max_node_count" {
  type = number
}

variable "vpx_image_path" {
  type = string
}

variable "vpx_mgmt_cidr_range" {
  type = string
}

variable "vpx_vip_cidr_range" {
  type = string
}

variable "vpx_new_password" {
  type = string
}

variable "demo_app_url" {
  type = string
}

variable "ingress_controller_image" {
  default = "quay.io/citrix/citrix-k8s-ingress-controller:1.19.6"
  type = string
}