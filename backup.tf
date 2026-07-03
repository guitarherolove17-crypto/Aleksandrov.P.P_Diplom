# Собираем ID дисков всех ВМ
locals {
  disk_ids = [
    yandex_compute_instance.bastion.boot_disk[0].disk_id,
    yandex_compute_instance.web_a.boot_disk[0].disk_id,
    yandex_compute_instance.web_b.boot_disk[0].disk_id,
    yandex_compute_instance.web_zabbix.boot_disk[0].disk_id,
    yandex_compute_instance.web_kibana.boot_disk[0].disk_id,
    yandex_compute_instance.web_elasticsearch.boot_disk[0].disk_id,
  ]
}

resource "yandex_compute_snapshot_schedule" "daily_backup" {
  name = "daily-backup-${var.flow}"
  description = "Ежедневное резервное копирование дисков всех ВМ"

  schedule_policy {
    expression = "0 2 * * *"   # каждый день в 2:00 по UTC
  }

  retention_period = "168h"    # 7 дней

  snapshot_spec {
    description = "Автоматический снапшот от {{ creation_time }}"
  }

  disk_ids = local.disk_ids
}