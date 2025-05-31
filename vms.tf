data "yandex_compute_image" "ubuntu_2204_lts" {
  family = "ubuntu-2204-lts"
}
//-----------VM-1-(nginxserver1)----------
resource "yandex_compute_instance" "nginxserver1" {
  name        = "nginxserver1" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-a" #зона ВМ должна совпадать с зоной subnet!!!
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-1.id
    nat                = false
    ip_address = "192.168.1.11"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }

}
//-----------VM-2-(nginxserver2)----------
resource "yandex_compute_instance" "nginxserver2" {
  name        = "nginxserver2" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-b" #зона ВМ должна совпадать с зоной subnet!!!
  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }
  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-2.id
    nat                = false
    ip_address = "192.168.2.22"
    security_group_ids = [yandex_vpc_security_group.nginx-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }
}

//-----------VM-3-(zabbix)----------
resource "yandex_compute_instance" "zabbix" {
  name        = "zabbix" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-d" #зона ВМ должна совпадать с зоной subnet!!!
  hostname = "zabbix"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-4.id
    nat                = true
    ip_address = "192.168.3.33"
    security_group_ids = [yandex_vpc_security_group.zabbix-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }
}

//-----------VM-4-(elastic)----------
resource "yandex_compute_instance" "elastic" {
  name        = "elastic" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-d" #зона ВМ должна совпадать с зоной subnet!!!
  hostname = "elastic"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-4.id
    nat                = false
    ip_address = "192.168.4.44"
    security_group_ids = [yandex_vpc_security_group.elastic-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }
}

//-----------VM-5-(kibana)----------
resource "yandex_compute_instance" "kibana" {
  name        = "kibana" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-d" #зона ВМ должна совпадать с зоной subnet!!!
  hostname = "kibana"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-4.id
    nat                = true
    ip_address = "192.168.3.34"
    security_group_ids = [yandex_vpc_security_group.kibana-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }
}

//-----------VM-6-(bastion)----------
resource "yandex_compute_instance" "bastion" {
  name        = "bastion" #Имя ВМ в облачной консоли
  platform_id = "standard-v3"
  zone        = "ru-central1-d" #зона ВМ должна совпадать с зоной subnet!!!
  hostname = "bastion"

  resources {
    cores         = 2
    memory        = 1
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu_2204_lts.image_id
      type     = "network-hdd"
      size     = 10
    }
  }

  scheduling_policy {
    preemptible = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.subnet-4.id
    nat                = true
    ip_address = "192.168.5.55"
    security_group_ids = [yandex_vpc_security_group.bastion-sg.id]
  }

  metadata = {
    user-data = "${file("cloud-init.yml")}"
  }

  connection {
    type        = "ssh"
    user        = "user"
#    private_key = file("~/.ssh/id_ed25519")
    host        = self.network_interface[0].nat_ip_address
  }

  provisioner "file" {
    source      = "./ansible"
    destination = "/home/user/"
  }
#   provisioner "file" {
#    source      = "./ansible/filebeat_conf/filebeat.yml"
#    destination = "/home/user/ansible/filebeat_conf/"
#  }
#   provisioner "file" {
#    source      = "./ansible/group_vars/all_servers"
#    destination = "/home/user/ansible/group_vars/"
#  }
#   provisioner "file" {
#    source      = "./ansible/my_web_site/index.nginx-debian.html.j2"
#    destination = "/home/user/ansible/my_web_site/"
#  }

  provisioner "file" {
    source      = "~/.ssh"
    destination = "/home/user/"
  }

  provisioner "remote-exec" {
  inline = [
<<EOT
chmod =600 ~/.ssh/id_ed25519
EOT
    ]
  }

  provisioner "remote-exec" {
  inline = [
<<EOT
sudo apt install ansible -y
EOT
    ]
  }

}