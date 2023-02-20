job "obs-consul_exporter" {
  datacenters = ["seaview"]
  type = "service"

  group "prometheus_consul_exporter" {

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }

      port "http" {
        to = 9107
      }
    }

    task "prometheus_consul_exporter" {
      driver = "docker"

      config {
        image = "prom/consul-exporter:v0.9.0"
        args  = []
      }

      resources {
        cpu    = 100
        memory = 128
      }
      
      service {
        name = "prometheus-consul-exporter"
        port = "http"
        tags = []
        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "3s"
          timeout  = "1s"
        }
      }
    }
  }
}

