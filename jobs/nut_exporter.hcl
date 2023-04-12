job "obs-nut-exporter" {
  datacenters = ["seaview"]
  type = "service"

  group "prometheus_nut_exporter" {
    count = 1

    task "prometheus_snmp_exporter" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "ghcr.io/druggeri/nut_exporter:3.0.0"
      }

      resources {
        cpu    = 1024
        memory = 128
      }

      service {
        name     = "prometheus-nut-exporter-main-ups"
        provider = "consul"
        port     = 9199
        address_mode = "driver"
        tags = [
          "metrics=true",
          "metrics_path=/ups_metrics"
        ]
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/obs-nut-exporter" -}}
NUT_EXPORTER_SERVER = {{ .NUT_EXPORTER_SERVER }}
NUT_EXPORTER_USERNAME = {{ .NUT_EXPORTER_USERNAME }}
NUT_EXPORTER_PASSWORD = {{ .NUT_EXPORTER_PASSWORD }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}

