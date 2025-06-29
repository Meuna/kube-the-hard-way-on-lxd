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
    "features.images"          = false
    "features.networks"        = false
    "features.profiles"        = true
    "features.storage.buckets" = true
  }
}

resource "lxd_network" "k8sthw" {
  name = "k8sthw"

  config = {
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "dns.domain"   = "k8sthw.local"
  }
}

resource "lxd_storage_pool" "k8sthw" {
  project = lxd_project.k8sthw.name
  name    = "k8sthw"
  driver  = "dir"
}

resource "lxd_profile" "k8sthw" {
  project = lxd_project.k8sthw.name
  name    = "k8sthw"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.k8sthw.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.k8sthw.name
      path = "/"
      size = "5GiB"
    }
  }
}

resource "lxd_instance" "jh" {
  project  = lxd_project.k8sthw.name
  name     = "jh"
  image    = "ubuntu:24.04"
  profiles = [lxd_profile.k8sthw.name]
}

resource "lxd_instance" "node" {
  count    = 3
  project  = lxd_project.k8sthw.name
  name     = "node-${count.index}"
  image    = "ubuntu:24.04"
  profiles = [lxd_profile.k8sthw.name]
}

