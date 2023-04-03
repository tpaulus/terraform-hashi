job "coa-utilities-bill-generation" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "0 0 2 * *"
    prohibit_overlap = true
  }

  group "Next-Century" {
    count = 1

    task "generate-bill" {
      driver = "docker"

      config {
        image = "ghcr.io/tpaulus/nextcentury-payhoa:main"
      }

      template {
        data = <<EOH
{{ with nomadVar "SMTP" -}}
SMTP_PORT={{ .port }}
SMTP_SERVER="{{ .host }}"
SMTP_USERNAME="{{ .user }}"
SMTP_PASSWORD="{{ .pass }}"
{{- end }}

TZ="America/Los_Angeles"

{{ with nomadVar "nomad/jobs/coa-utilities-bill-generation" -}}
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
