job "Zigbee2MQTT" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }


  group "z2m" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      port "http" {}
    }

    volume "z2m-nfs-volume" {
      type            = "csi"
      source          = "z2m_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    service {
      name         = "Zigbee2MQTT"
      port         = "http"
      provider     = "consul"

      tags = [
        "global", "home-automation",
        "traefik.enable=true",
        "traefik.http.routers.blog.rule=Host(`z2m.brickyard.whitestar.systems`)",
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
    }

    task "z2m" {
      resources {
        device "1a86/usb/7523" {}

      driver = "docker"
      config = {
        image = "docker.io/koenkk/zigbee2mqtt:1.29.2"
        ports = ["http"]

        auth_soft_fail = true

//        devices = [
//          {
//            host_path = "/dev/ttyUSB0"
//          }
//        ]
      }

      template {
        data = <<EOH
TZ=America/Los_Angeles
ZIGBEE2MQTT_CONFIG_FRONTEND_PORT={{ env "NOMAD_PORT_http" }}
ZIGBEE2MQTT_CONFIG_MQTT_SERVER=mqtt://{{ range service "mqtt" }}{{ .Address }}:{{ .Port }}{{ end }}
ZIGBEE2MQTT_CONFIG_MQTT_USER={{}}
ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD={{}}
ZIGBEE2MQTT_CONFIG_MQTT_CLIENT_ID={{ env "NOMAD_ALLOC_NAME" }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      volume_mount {
          volume      = "z2m-nfs-volume"
          destination = "/app/data"
          read_only   = false
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}