job "vlmcsd" {
  datacenters = ["seaview"]
  type = "service"

  priority = 50

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "vlmcsd" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    task "vlmcsd" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "mikolatero/vlmcsd:latest"

        auth_soft_fail = true
      }

      service {
        name         = "vlmcsd"  # vlmcsd.service.seaview.consul
        port         = 1688
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "n8n"
        ]

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
          address_mode = "driver"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}