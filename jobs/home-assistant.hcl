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
      dns {
        servers = ["10.0.1.249", "1.1.1.1", "1.0.0.1"]
      }

      port "http" {
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
        network_mode = "corp"
        image = "ghcr.io/home-assistant/home-assistant:2023.1.7"
        ports = ["http"]

        auth_soft_fail = true

        volumes = ["/etc/localtime:/etc/localtime:ro"]
      }

      volume_mount {
          volume      = "home-assistant-nfs-volume"
          destination = "/config"
          read_only   = false
      }

      service {
        name         = "HomeAssistant"
        port         = "http"
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "home-automation"
        ]
      }

      resources {
        cpu    = 2048
        memory = 3072
      }
    }
  }
}