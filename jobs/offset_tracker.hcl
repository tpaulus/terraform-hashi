job "Monarch_Offset_Tracker" {
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
        image = "ghcr.io/tpaulus/monarch-offset-tracker:main"
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/Monarch_Offset_Tracker" -}}
{{ range .Tuples -}}
{{ .K }}="{{ .V }}"
{{ end }}
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