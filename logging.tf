# Создаём лог-группу (место для хранения логов)

resource "yandex_logging_group" "lb_logs" {
  name             = "lb-logs-${var.flow}"            # Имя лог-группы, чтобы легко её найти
  retention_period = "168h"                           # Логи будут храниться 7 дней (168 часов)
  # folder_id       = var.folder_id                   # Обычно не требуется, так как задан в provider
}