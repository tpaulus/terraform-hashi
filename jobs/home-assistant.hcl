job "HomeAssistant" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "home-assistant" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      port "web-ui" {
        to = 8123
      }
    }

    volume "home-assistant-nfs-volume" {
      type            = "csi"
      source          = "home_assistant_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "home-assistant" {
      driver = "docker"
      config = {
        network = "corp"
        image = "ghcr.io/home-assistant/home-assistant:2023.1.7"
        ports = ["web-ui"]

        auth_soft_fail = true

        volumes = ["/etc/localtime:/etc/localtime:ro"]
      }

      volume_mount {
          volume      = "home-assistant"
          destination = "/app/data"
          read_only   = false
      }

      service {
        name         = "HomeAssistant"
        port         = "web-ui"
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "home-automation",
          "traefik.enable=true",
          "traefik.http.routers.blog.rule=Host(`home.whitestar.systems`)",
          "traefik.http.services.blog.loadbalancer.passhostheader=true"
        ]

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          port     = "http"
          interval = "60s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }

        check {
          name     = "HTTP Health Check"
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "60s"
          timeout  = "5s"

          header {
            X-Forwarded-Host  = ["home.whitestar.systems"]
            X-Forwarded-For   = ["127.0.0.1"]
            X-Forwarded-Proto = ["https"]
          }

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      resources {
        cpu    = 2048
        memory = 3072
      }
    }
  }
}