job "obs-nut-exporter" {
  datacenters = ["seaview"]
  type = "service"

  group "prometheus_nut_exporter" {
    count = 1

    network {
      port "metrics" {
        to = 9199
      }
    }

    task "prometheus_snmp_exporter" {
      driver = "docker"
      config {
        image = "ghcr.io/druggeri/nut_exporter:3.0.0"
        ports = ["metrics"]
      }

      resources {
        cpu    = 1024
        memory = 128
      }

      service {
        name     = "prometheus-nut-exporter-main-ups"
        provider = "consul"
        port     = "metrics"
        tags = [
          "metrics=true",
          "metrics_path=/ups_metrics"
        ]
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/CF_Gateway_IP" -}}
NUT_EXPORTER_SERVER = {{ .CF_API_TOKEN }}
NUT_EXPORTER_USERNAME = {{ .CF_ACCOUNT_ID }}
NUT_EXPORTER_PASSWORD = {{ .CF_GATEWAY_LOCATION }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}

