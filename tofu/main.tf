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

variable "ssh_pub_path" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}

resource "lxd_project" "kthw" {
  name        = "kube-thw-on-lxd"
  description = "Kubernetes cluster build the hard way"
  config = {
    "features.storage.volumes" = true
    "features.images"          = false
    "features.networks"        = false
    "features.profiles"        = true
    "features.storage.buckets" = true
  }
}

resource "lxd_network" "kthw" {
  name = "kube-thw-on-lxd"

  config = {
    "ipv4.nat"     = "true"
    "ipv6.address" = "none"
    "dns.domain"   = "kthw.local"
  }
}

resource "lxd_storage_pool" "kthw" {
  project = lxd_project.kthw.name
  name    = "kube-thw-on-lxd"
  driver  = "dir"
}

resource "lxd_profile" "kthw-node" {
  project = lxd_project.kthw.name
  name    = "kube-thw-on-lxd-node"

  device {
    name = "eth0"
    type = "nic"

    properties = {
      nictype = "bridged"
      parent  = lxd_network.kthw.name
    }
  }

  device {
    type = "disk"
    name = "root"

    properties = {
      pool = lxd_storage_pool.kthw.name
      path = "/"
    }
  }

  config = {
    "cloud-init.user-data" : templatefile("cloud-init.yaml.tftpl", { ssh_pub = file(var.ssh_pub_path) })
  }
}

resource "lxd_instance" "jh" {
  project  = lxd_project.kthw.name
  name     = "jh"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.kthw-node.name]
}

resource "lxd_instance" "node" {
  count    = 3
  project  = lxd_project.kthw.name
  name     = "node-${count.index}"
  image    = "ubuntu:24.04"
  type     = "virtual-machine"
  profiles = [lxd_profile.kthw-node.name]
}

