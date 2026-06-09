# 1. Target group – включает обе ВМ
resource "yandex_alb_target_group" "web_tg" {
  name = "web-tg-${var.flow}"

  target {
    subnet_id = yandex_vpc_subnet.develop_a.id
    ip_address = yandex_compute_instance.web_a.network_interface.0.ip_address
  }
  target {
    subnet_id = yandex_vpc_subnet.develop_b.id
    ip_address = yandex_compute_instance.web_b.network_interface.0.ip_address
  }
}

# 2. Backend group – настройки балансировки и healthcheck
resource "yandex_alb_backend_group" "web_bg" {
  name = "web-bg-${var.flow}"

  http_backend {
    name             = "web-backend"
    port             = 80
    weight           = 1
    target_group_ids = [yandex_alb_target_group.web_tg.id]

    load_balancing_config {
      panic_threshold = 50
    }

    healthcheck {
      timeout  = "5s"
      interval = "10s"
      http_healthcheck {
      path = "/"
      }
    } 
  }
}

# 3. HTTP router – направляем трафик с "/" на backend group
resource "yandex_alb_http_router" "web_router" {
  name = "web-router-${var.flow}"
}

resource "yandex_alb_virtual_host" "web_vhost" {
  name           = "web-vhost-${var.flow}"
  http_router_id = yandex_alb_http_router.web_router.id

  route {
    name = "web-route"
    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.web_bg.id
        timeout          = "5s"
      }
    }
  }
}

# 4. Application Load Balancer – публичный listener на порту 80
resource "yandex_alb_load_balancer" "web_lb" {
  name               = "web-lb-${var.flow}"
  network_id         = yandex_vpc_network.develop.id
  security_group_ids = [yandex_vpc_security_group.web_sg.id] # разрешает входящий 80/443

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.develop_a.id
    }
    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.develop_b.id
    }
  }

  listener {
    name = "web-listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.web_router.id
      }
    }
  }

  #Подключаем логирование
  log_options {
    log_group_id = yandex_logging_group.lb_logs.id
    # discard_rule {}  # При желании можно настроить фильтрацию логов по кодам ответов
  }
}


# Вывод публичного IP балансировщика
output "lb_public_ip" {
  value = yandex_alb_load_balancer.web_lb.listener[0].endpoint[0].address[0].external_ipv4_address[0].address
}