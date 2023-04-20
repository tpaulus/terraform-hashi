job "N8N" {
  datacenters = ["seaview"]
  type = "service"

  priority = 50

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "N8N" {
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

    volume "n8n-nfs-volume" {
      type            = "csi"
      source          = "n8n_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }


    task "N8N" {
      driver = "docker"
      config = {
        network_mode = "weave"
        image = "n8nio/n8n:0.225.0"

        auth_soft_fail = true
      }

      service {
        name         = "n8n"  # n8n.service.seaview.consul
        port         = 5678
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

      template {
        data = <<EOH
WEBHOOK_URL      = "https://n8n.brickyard.whitestar.systems/"
GENERIC_TIMEZONE = "America/Los_Angeles"
TZ               = "America/Los_Angeles"
{{ with nomadVar "SMTP" -}}
N8N_SMTP_HOST    = "{{ .host }}"
N8N_SMTP_PORT    = "{{ .port }}"
N8N_SMTP_USER    = "{{ .user }}"
N8N_SMTP_PASS    = "{{ .pass }}"
{{- end }}
N8N_SMTP_SENDER  = "n8n@nuc.whitestar.systems"
N8N_DIAGNOSTICS_ENABLED = "false"
N8N_HIRING_BANNER_ENABLED = "false"
        EOH

        destination = "secrets/file.env"
        env         = true
      }


      volume_mount {
          volume      = "n8n-nfs-volume"
          destination = "/root/.n8n"
          read_only   = false
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}