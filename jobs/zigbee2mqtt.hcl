job "ha-Zigbee2MQTT" {
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
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    volume "z2m-nfs-volume" {
      type            = "csi"
      source          = "z2m_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "z2m" {
      driver = "docker"
      config = {
        network_mode = "weave"

        image = "koenkk/zigbee2mqtt:1.30.3"

        auth_soft_fail = true

        devices = [
          {
            host_path = "/dev/ttyUSB0"
            container_path = "/dev/ttyUSB0"
          }
        ]
      }

    service {
      name         = "Zigbee2MQTT"
      port         = 8080
      provider     = "consul"
      address_mode = "driver"

      tags = [
        "global", "home-automation"
      ]
    }

      template {
        data = <<EOH
TZ=America/Los_Angeles
ZIGBEE2MQTT_CONFIG_MQTT_SERVER=mqtt://{{ range service "mqtt" }}{{ .Address }}:{{ .Port }}{{ end }}
{{ with nomadVar "nomad/jobs/Zigbee2MQTT" -}}
ZIGBEE2MQTT_CONFIG_MQTT_USER={{ .user }}
ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD={{ .pass }}
{{- end }}
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
        device "1a86/usb/7523" {}

        cpu    = 1024
        memory = 1024
      }
    }
  }
}