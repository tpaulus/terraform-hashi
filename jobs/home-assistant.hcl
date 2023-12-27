job "ha-HomeAssistant" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "5s"
   delay_function = "exponential"
   max_delay      = "1m"
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
        servers = ["${attr.unique.network.ip-address}"]
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
      kill_timeout = "30s"
      config {
        network_mode = "weave"

        image = "ghcr.io/home-assistant/home-assistant:2023.12.4"

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
        port         = 8123
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

    task "Update-CoIoT-IPs" {
      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "update_coiot.sh"
      }

      template {
        data = <<EOH
{{- with nomadVar "nomad/jobs/HomeAssistant/home-assistant/Update-CoIoT-IPs" }}
HOSTS = {{ .Hosts }}
{{- end }}
{{ range service "HomeAssistant" -}}
PEER="{{ .Address }}"
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      artifact {
        source = "https://raw.githubusercontent.com/tpaulus/server-scripts/main/home-automation/update_coiot.sh"
      }
    }

    task "mdns-reflector" {
      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      driver = "docker"

      config {
        network_mode = "host"
        image   = "yuxzhu/mdns-reflector:latest"
        command = "/usr/local/bin/mdns-reflector"
        args = ["-fn", "${meta.network.primary_interface}", "weave"]
      }

      resources {
        cpu    = 128
        memory = 100
      }
    }
  }
}