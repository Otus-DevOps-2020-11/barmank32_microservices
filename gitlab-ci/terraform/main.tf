provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

data "yandex_compute_image" "image" {
  family = "ubuntu-1804-lts"
}

resource "yandex_compute_instance" "gitlab" {
  name = "gitlab-ci"

  zone = var.zone

  resources {
    cores  = 2
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.image.id
      size = 50
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }
  scheduling_policy {
    preemptible = true
  }
}

locals {
  names = [yandex_compute_instance.gitlab.name]
  ips   = [yandex_compute_instance.gitlab.network_interface.0.nat_ip_address]
}

resource "local_file" "generate_inventory" {
  content = templatefile("inventory.tpl", {
    names = local.names,
    addrs = local.ips,
  })
  filename = "inventory"

  provisioner "local-exec" {
    command = "chmod a-x inventory"
  }

  provisioner "local-exec" {
    command = "cp -u inventory ../ansible/inventory"
  }

  provisioner "local-exec" {
    when       = destroy
    command    = "mv inventory inventory.backup"
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "ansible-playbook run_gitlab.yml"
    working_dir = "../ansible"
  }
}
