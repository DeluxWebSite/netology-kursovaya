//----------TARGET_GROUP---------
resource "yandex_alb_target_group" "ngx-target-group" {
  name      = "ngx-target-group"

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-1.id}"
    ip_address   = "${yandex_compute_instance.nginxserver1.network_interface.0.ip_address}"
  }

  target {
    subnet_id = "${yandex_vpc_subnet.subnet-2.id}"
    ip_address   = "${yandex_compute_instance.nginxserver2.network_interface.0.ip_address}"
  }
}

//----------BACKEND_GROUP---------
resource "yandex_alb_backend_group" "nginx-backend-group" {
  name      = "nginx-backend-group"

  http_backend {
    name = "backend-1"
    weight = 1
    port = 80
    target_group_ids = [yandex_alb_target_group.ngx-target-group.id]

    load_balancing_config {
      panic_threshold = 0
    }
    healthcheck {
      timeout = "1s"
      interval = "3s"
      healthy_threshold    = 2
      unhealthy_threshold  = 2
      healthcheck_port     = 80
      http_healthcheck {
        path  = "/"
      }
    }
  }
}

//----------------- HTTP router -----------------
resource "yandex_alb_http_router" "nginx-router" {
  name      = "nginx-router"
}

resource "yandex_alb_virtual_host" "ngx-virtual-host" {
  name                    = "ngx-virtual-host"
  http_router_id          = yandex_alb_http_router.nginx-router.id
  route {
    name                  = "ngx-route"
    http_route {
      http_route_action {
        backend_group_id  = yandex_alb_backend_group.nginx-backend-group.id
      }
    }
  }
}

//----------BALANCER----------
resource "yandex_alb_load_balancer" "nginx-balancer" {
  name        = "nginx-balancer"
  network_id  = yandex_vpc_network.network-1.id

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.subnet-1.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.subnet-2.id
    }
//    location {
//      zone_id   = "ru-central1-c" //--нет в яндексе такой зоны
//      subnet_id = yandex_vpc_subnet.subnet-3.id
//    }
    location {
      zone_id   = "ru-central1-d"
      subnet_id = yandex_vpc_subnet.subnet-4.id
    }
  }

  listener {
    name = "my-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [ 80 ]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.nginx-router.id
      }
    }
  }
}

//----------ГРУППЫ БЕЗОПАСНОСТИ----------
//----------БАСТИОН----------
resource "yandex_vpc_security_group" "bastion-sg" {
  name        = "bastion-sg"
  description = "access via ssh"
  network_id  = "${yandex_vpc_network.network-1.id}"
  ingress {
      protocol          = "TCP"
      description       = "ssh-in"
      port              = 22
      v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      protocol          = "ANY"
      description       = "any for basion to out"
      from_port         = 0
      to_port           = 65535
      v4_cidr_blocks = ["0.0.0.0/0"]
    }
}



//----------nginx----------
resource "yandex_vpc_security_group" "nginx-sg" {
  name        = "nginx-sg"
  description = "rules for nginx"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "80"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.5.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"]
  }

  ingress {
    description = "Health checks from NLB"
    protocol = "TCP"
    predefined_target = "loadbalancer_healthchecks"
  }


  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

//----------ZABBIX_server----------
resource "yandex_vpc_security_group" "zabbix-sg" {
  name        = "zabbix-sg"
  description = "rules for zabbix"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "TCP"
    description    = "HTTP in"
    port           = "8080"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.5.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10051"
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "192.168.4.0/24"]
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

//----------ELASTIC----------
resource "yandex_vpc_security_group" "elastic-sg" {
  name        = "elastic-sg"
  description = "rules for elastic"
  network_id  = "${yandex_vpc_network.network-1.id}"


  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.5.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "elastic agent in"
    port           = "9200"
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24"]
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

//----------KIBANA----------
resource "yandex_vpc_security_group" "kibana-sg" {
  name        = "kibana-sg"
  description = "rules for kibana"
  network_id  = "${yandex_vpc_network.network-1.id}"

  ingress {
    protocol       = "TCP"
    description    = "kibana interface"
    port           = "5601"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ssh in"
    port           = "22"
    v4_cidr_blocks = ["192.168.5.0/24"]
  }

  ingress {
    protocol       = "TCP"
    description    = "zabbix in"
    port           = "10050"
    v4_cidr_blocks = ["192.168.3.0/24"]
  }

  egress {
    description    = "ANY"
    protocol       = "ANY"
    from_port         = 0
    to_port           = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}



//----------РАСПИСАНИЕ СНИМКОВ ДИСКОВ ВМ----------
//resource "yandex_compute_snapshot_schedule" "daily" {
//  name = "daily"
//
//  schedule_policy {
//    expression = "00 17 ? * *"
//  }
//
//  retention_period = "168h"
//
//  disk_ids = [yandex_compute_instance.vm-1.boot_disk.0.disk_id, yandex_compute_instance.vm-2.boot_disk.0.disk_id, yandex_compute_instance.vm-3.boot_disk.0.disk_id, yandex_compute_instance.vm-4.boot_disk.0.disk_id, yandex_compute_instance.vm-5.boot_disk.0.disk_id, yandex_compute_instance.vm-6.boot_disk.0.disk_id]
//}




//----------ШЛЮЗ И ТАБЛИЦА МАРШРУТИЗАЦИИ----------
resource "yandex_vpc_gateway" "nginx1-2_elastic_gateway" {
  name = "nginx-elastic-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "nginx1-2_elastic" {
  name       = "nginx-elastic-route-table"
  network_id = yandex_vpc_network.network-1.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nginx1-2_elastic_gateway.id
  }
}



//----------СЕТЬ----------
resource "yandex_vpc_network" "network-1" {
  name = "network1"
}

//----------ПОДСЕТЬ-1----------
resource "yandex_vpc_subnet" "subnet-1" {
  name           = "subnet1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//----------ПОДСЕТЬ-2----------
resource "yandex_vpc_subnet" "subnet-2" {
  name           = "subnet2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//----------ПОДСЕТЬ-3----------
#resource "yandex_vpc_subnet" "subnet-3" {
#  name           = "subnet3"
#  zone           = "ru-central1-b"
#  network_id     = yandex_vpc_network.network-1.id
#  v4_cidr_blocks = ["192.168.3.0/24", "192.168.5.0/24"]
#}

//----------ПОДСЕТЬ-4----------
resource "yandex_vpc_subnet" "subnet-4" {
  name           = "subnet4"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.network-1.id
  v4_cidr_blocks = ["192.168.3.0/24", "192.168.4.0/24", "192.168.5.0/24"]
  route_table_id = yandex_vpc_route_table.nginx1-2_elastic.id
}

//----------вывод IP адреса бастиона----------
output "external_ip_address_BASTION" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

//---------- to hosts.ini ---------
resource "local_file" "inventory" {
  content  = <<-XYZ
  [webservers]
  ${yandex_compute_instance.nginxserver1.network_interface[0].ip_address}
  ${yandex_compute_instance.nginxserver2.network_interface[0].ip_address}
  [zabbix]
  ${yandex_compute_instance.zabbix.network_interface[0].ip_address}
  ${yandex_compute_instance.zabbix.network_interface[0].nat_ip_address}
  [elastic]
  ${yandex_compute_instance.elastic.network_interface[0].ip_address}
  [kibana]
  ${yandex_compute_instance.kibana.network_interface[0].ip_address}
  ${yandex_compute_instance.kibana.network_interface[0].nat_ip_address}
  [bastion]
  ${yandex_compute_instance.bastion.network_interface[0].nat_ip_address}
  XYZ
  filename = "./hosts.ini"
}