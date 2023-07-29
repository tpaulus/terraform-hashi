job "obs-opnsense-exporter" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }
  
  group "opnsense-exporter" {
    count = 1

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    task "opnsense-exporter" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "ghcr.io/tpaulus/opnsense-exporter:main"
      }

      template {
        data = <<EOH
METRICS_PORT=8080
DELAY=5

OPNSENSE_URL=https://10.0.10.1
OPNSENSE_SSL_VERIFY=false
{{ with nomadVar "nomad/jobs/obs-opnsense-exporter" -}}
OPNSENSE_KEY={{ .key }}
OPNSENSE_SECRET={{ .secret }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "opnsense-exporter"
        provider = "consul"
        port = 8080
        address_mode = "driver"
        
        tags = [
          "metrics=true"
        ]

        check {
          type     = "http"
          path     = "/"
          interval = "3s"
          timeout  = "1s"
          address_mode = "driver"
        }
      }
    }
  }
}
