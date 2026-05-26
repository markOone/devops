terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "ubuntu_image" {
  name   = "ubuntu-image"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64.img"
  format = "qcow2"
}

resource "libvirt_volume" "worker_disk" {
  name           = "worker.qcow2"
  base_volume_id = libvirt_volume.ubuntu_image.id
  size           = 10737418240
}

resource "libvirt_volume" "db_disk" {
  name           = "db.qcow2"
  base_volume_id = libvirt_volume.ubuntu_image.id
  size           = 10737418240
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name      = "commoninit.iso"
  user_data = templatefile("${path.module}/cloud_init.cfg", {
    ssh_key = file("~/.ssh/id_rsa.pub")
  })
}

resource "libvirt_domain" "worker" {
  name   = "worker"
  memory = "1024"
  vcpu   = 1
  type   = "qemu" # <--- ОСЬ ЦЕЙ РЯДОК
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  disk {
    volume_id = libvirt_volume.worker_disk.id
  }
}

resource "libvirt_domain" "db" {
  name   = "db"
  memory = "1024"
  vcpu   = 1
  type   = "qemu" # <--- І ОСЬ ТУТ ТАКОЖ
  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }
  cloudinit = libvirt_cloudinit_disk.commoninit.id
  disk {
    volume_id = libvirt_volume.db_disk.id
  }
}

output "worker_ip" {
  value = libvirt_domain.worker.network_interface[0].addresses[0]
}
output "db_ip" {
  value = libvirt_domain.db.network_interface[0].addresses[0]
}