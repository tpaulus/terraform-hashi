job "Lunch_Money_Offset_Tracker" {
  datacenters = ["seaview"]
  type = "batch"

  priority = 10

  periodic {
    cron = "*/15 * * * *"
    prohibit_overlap = true
  }

  group "offset sources" {
    count = 1

    task "lunchmoney-offsets" {
      driver = "docker"

      config {
        image = "ghcr.io/tpaulus/lunch-money-offset-tracker:main"
        
        auth {
          server_address = "ghcr.io"
          username = "tpaulus"
          password = "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"
        }
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/Lunch_Money_Offset_Tracker" -}}
LUNCHMONEY_KEY = "{{ .LUNCHMONEY_KEY }}"
NOTION_DB = "{{ .NOTION_DB }}"
NOTION_KEY = "{{ .NOTION_KEY }}"
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    }
  }
}