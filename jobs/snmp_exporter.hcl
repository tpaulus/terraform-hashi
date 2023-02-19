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
    }
  }
}

