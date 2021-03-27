provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

# --------- AIM
resource "yandex_iam_service_account" "zonal_k8s" {
  name        = "zonal-k8s"
  description = "service account to manage zonal_k8s"
}

resource "yandex_resourcemanager_folder_iam_binding" "admin" {
  folder_id = var.folder_id
  role      = "admin"

  members = [
    "serviceAccount:${yandex_iam_service_account.zonal_k8s.id}",
  ]

  depends_on = [
    yandex_iam_service_account.zonal_k8s
  ]
}

# -------------- Network
resource "yandex_vpc_network" "k8s" {
  name = "k8s"
}

resource "yandex_vpc_subnet" "k8s-subnet-a" {
  name           = "k8s-subnet-a"
  v4_cidr_blocks = ["10.0.0.0/16"]
  zone           = var.zone
  network_id     = yandex_vpc_network.k8s.id
}

# ------------------ k8s
resource "yandex_kubernetes_cluster" "zonal_k8s" {
  name = "terraform-k8s"

  network_id = yandex_vpc_network.k8s.id

  master {
    version = "1.19"

    zonal {
      zone      = var.zone
      subnet_id = yandex_vpc_subnet.k8s-subnet-a.id
    }

    public_ip = true

    # security_group_ids = ["${yandex_vpc_security_group.security_group_name.id}"]

    maintenance_policy {
      auto_upgrade = true

      maintenance_window {
        start_time = "15:00"
        duration   = "3h"
      }
    }
  }

  service_account_id      = yandex_iam_service_account.zonal_k8s.id
  node_service_account_id = yandex_iam_service_account.zonal_k8s.id

  # labels = {
  #   my_key       = "my_value"
  #   my_other_key = "my_other_value"
  # }

  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  # kms_provider {
  #   key_id = yandex_kms_symmetric_key.kms_key_resource_name.id
  # }

  depends_on = [
    yandex_iam_service_account.zonal_k8s,
    yandex_resourcemanager_folder_iam_binding.admin
  ]
}

resource "yandex_kubernetes_node_group" "k8s_node_group" {
  cluster_id = yandex_kubernetes_cluster.zonal_k8s.id
  name       = "node-group"
  version    = "1.19"

  # labels = {
  #   "key" = "value"
  # }

  instance_template {
    platform_id = "standard-v2"

    network_interface {
      nat        = true
      subnet_ids = [yandex_vpc_subnet.k8s-subnet-a.id]
    }

    resources {
      memory = 8
      cores  = 4
    }

    boot_disk {
      type = "network-hdd"
      size = 64
    }

    metadata = {
      ssh-keys = "ubuntu:${file(var.public_key_path)}"
    }

    scheduling_policy {
      preemptible = false
    }
  }

  scale_policy {
    fixed_scale {
      size = 2
    }
  }

  allocation_policy {
    location {
      zone = var.zone
    }
  }
  maintenance_policy {
    auto_upgrade = true
    auto_repair  = true

    maintenance_window {
      day        = "monday"
      start_time = "15:00"
      duration   = "3h"
    }

    maintenance_window {
      day        = "friday"
      start_time = "10:00"
      duration   = "4h30m"
    }
  }

  depends_on = [
    yandex_iam_service_account.zonal_k8s,
    yandex_resourcemanager_folder_iam_binding.admin
  ]
}
