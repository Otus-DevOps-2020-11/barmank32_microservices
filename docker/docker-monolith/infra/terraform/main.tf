provider "yandex" {
  service_account_key_file = var.service_account_key_file
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

resource "yandex_compute_instance" "docker" {
  count = var.app_count

  name = "docker-${count.index}"

  zone = var.zone

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 5
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
    }
  }

  network_interface {
    subnet_id = var.subnet_id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_path)}"
  }

}

locals {
  names = yandex_compute_instance.docker[*].name
  ips   = yandex_compute_instance.docker[*].network_interface.0.nat_ip_address
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
    command = "ansible-playbook run_docker.yml"
    working_dir = "../ansible"
  }
}
