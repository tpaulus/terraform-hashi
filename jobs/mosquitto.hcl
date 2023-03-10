job "MQTT" {
  datacenters = ["seaview"]
  type        = "service"
  priority    = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "MQTT" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      port "broker" {
        to = 1883
      }
    }

    volume "mqtt-volume" {
      type            = "csi"
      source          = "mqtt_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "mosquitto" {
      driver = "docker"
      kill_timeout = "30s"
      config = {
        network_mode = "corp"
        dns_servers = ["10.0.10.3"]

        image = "eclipse-mosquitto:2.0.15"
        ports = ["broker"]

        auth_soft_fail = true

        mount {
          type   = "bind"
          source = "local"
          target = "/mosquitto/config/"
        }
      }

      service {
        name         = "mqtt"  # mqtt.service.seaview.consul
        tags         = ["global", "mqtt"]
        port         = "broker"
        provider     = "consul"
        address_mode = "driver"
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }

      volume_mount {
        volume      = "mqtt-volume"
        destination = "/persistence"
        read_only   = false
      }

      template {
        destination   = "local/mosquitto.conf"
        change_mode   = "signal"
        change_signal = "SIGHUP"

        data          = <<EOH
listener 1883
allow_anonymous false

autosave_interval 60
persistence true
persistence_location /persistence
persistent_client_expiration 1h

password_file {{ env "NOMAD_SECRETS_DIR" }}/passwords.txt
        EOH
        
      }

      template {
        destination   = "secrets/passwords.txt"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        data          = <<EOH
        {{ with nomadVar "nomad/jobs/MQTT" -}}
        home-assistant:{{ .homeAssistantPassword }}
        z2m:{{ .z2mPassword }}
        {{- end }}
        EOH
      }
    }
  }
}