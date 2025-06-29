terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "2.5.0"
    }
  }
}

provider "lxd" {
}

resource "lxd_project" "k8sthw" {
  name        = "k8sthw"
  description = "Kubernetes cluster build the hard way"
  config = {
    "features.storage.volumes" = true
    "features.images"          = true
    "features.networks"        = true
    "features.profiles"        = true
    "features.storage.buckets" = true
  }
}
