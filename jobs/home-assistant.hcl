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

  affinity {
    attribute = "${attr.unique.hostname}"
    value     = "magnolia"
    weight    = 100
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
      kill_timeout = "30s"
      config = {
        network_mode = "corp"
        dns_servers = ["10.0.10.3"]
        ipv4_address = "10.0.10.51"  # Temporary until Consul DNS issues are resolved

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

    task "Update-CoIoT-IPs" {
      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "home-automation/update_coiot.sh"
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
        source = "git::https://github.com/tpaulus/server-scripts"
      }
    }
  }
}