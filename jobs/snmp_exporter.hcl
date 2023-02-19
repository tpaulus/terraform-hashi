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
        command = "--config.file=${NOMAD_TASK_DIR}/snmp.yml"
      }

      resources {
        cpu    = 100
        memory = 64
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
        source = "https://gist.githubusercontent.com/tpaulus/1b2c652b8e7ac16a94de1ae4b673520a/raw/8e8ff62df8e8eef52af1197a6bb21f7b47370578/snmp.yml"
        destination = "local/"
      }
    }
  }
}

