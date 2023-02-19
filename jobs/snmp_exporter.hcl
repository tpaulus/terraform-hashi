job "obs-snmp-exporter" {
  datacenters = ["seaview"]
  type = "service"

  group "prometheus_snmp_exporter" {
    count = 1

    network {
      port "http" {
        to = 9116
      }
    }

    task "prometheus_snmp_exporter" {
      driver = "docker"
      config {
        image = "prom/snmp-exporter:v0.21.0"
        ports = ["http"]
        command = "--config.file=${NOMAD_TASK_DIR}/snmp.yaml"
      }

      resources {
        cpu    = 1024
        memory = 128
      }

      service {
        name     = "prometheus-snmp-exporter"
        provider = "consul"
        port     = "http"
        tags     = ["global", "metrics", "metrics-scraper"]
        check {
          type     = "http"
          path     = "/"
          interval = "30s"
          timeout  = "30s"
        }
      }

      artifact {
        source = "https://gist.githubusercontent.com/tpaulus/750d0faeb117d7362bb9300eda770ec9/raw/9399bd903b5d9525621029398e0106cf3486d779/snmp.yaml"
        destination = "local/"
      }
    }
  }
}

