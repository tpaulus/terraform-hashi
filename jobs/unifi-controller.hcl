job "Net-UnifiController" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "Controller" {
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

    volume "unifi-controller-volume" {
      type            = "csi"
      source          = "unifi_controller_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    ephemeral_disk {
      migrate = true
      size    = 500
      sticky  = true
    }


    task "unifi-controller" {
      driver = "docker"
      config = {
        network_mode = "weave"
        image = "jacobalberty/unifi:v7.4.156"

        auth_soft_fail = true

        mount {
          type   = "bind"
          source = "/unifi/logs"
          target = "${NOMAD_ALLOC_DIR}/logs"
        }
      }

      env {
        TZ = "America/Los_Angeles"
      }

      service {
        name         = "unifi"  # unifi.service.seaview.consul
        port         = 8443
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "unifi", "networking"
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

      volume_mount {
          volume      = "unifi-controller-volume"
          destination = "/unifi/data"
          read_only   = false
      }

      resources {
        cpu    = 2048
        memory = 3072
      }
    }
  }
}