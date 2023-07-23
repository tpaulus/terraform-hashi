job "net-pihole" {
  datacenters = ["seaview"]
  type = "service"
  priority = 100

  reschedule {
   delay          = "5s"
   delay_function = "exponential"
   max_delay      = "1m"
   unlimited      = true
  }

  spread {
    attribute = "${node.datacenter}"
  }

  group "pihole" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    ephemeral_disk {
      migrate = false
      size    = 110
      sticky  = false
    }

    task "cloudflared" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      config {
        network_mode = "weave"
        image = "cloudflare/cloudflared:2023.7.1"
        entrypoint = ["/local/entrypoint.sh"]
        command = ""
      }

      template {
        destination = "local/entrypoint.sh"
        data = <<EOH
#!/usr/bin/env bash
set -euxo pipefail

ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' > /alloc/cloudflared_ip.txt

{{ with nomadVar "nomad/jobs/net-pihole" -}}
exec cloudflared --no-autoupdate proxy-dns --address 0.0.0.0 --upstream {{ .DNS_UPSTREAM_URL }} --port 5301 --metrics 0.0.0.0:50305
{{- end }}
EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      service {
        name     = "cloudflared-dns-proxy"
        provider = "consul"
        port     = 50305
        address_mode = "driver"
        tags = [
          "metrics=true"
        ]
      }
    }

    task "pihole" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "ghcr.io/pi-hole/pihole:2023.05.2"
        entrypoint = ["/local/entrypoint.sh"]
      }

      env {
        TZ = "America/Los_Angeles"
        WEBPASSWORD = ""
        DHCP_ACTIVE = "false"
        WEBTHEME = "default-dark"
      }

      resources {
        cpu = 1024
        memory = 2048
      }

      service {
        name     = "pihole"
        provider = "consul"
        port     = 53
        address_mode = "driver"
        tags = [
          "dns-resolver",
        ]
      }

       template {
        destination = "local/entrypoint.sh"
        data = <<EOH
#!/usr/bin/env bash
set -euxo pipefail

ip addr | grep 'state UP' -A2 | tail -n1 | awk '{print $2}' | cut -f1  -d'/' > /alloc/pihole_ip.txt

export PIHOLE_DNS_ = "$(cat /alloc/cloudflared_ip.txt):5301"
exec /s6-init
EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }
    }

    task "pihole-exporter" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      config {
        network_mode = "weave"
        image = "ekofr/pihole-exporter:v0.4.0"
        entrypoint = ["/local/entrypoint.sh"]
        command = ""
      }

      template {
        data = <<EOH
PIHOLE_PASSWORD=""
PORT=9617
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      template {
        destination = "local/entrypoint.sh"
        data = <<EOH
#!/usr/bin/env bash
set -euxo pipefail

export PIHOLE_HOSTNAME = "$(cat /alloc/pihole_ip.txt)"
exec ./pihole-exporter
EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      service {
        name     = "pihole-exporter"
        provider = "consul"
        port     = 9617
        address_mode = "driver"
        tags = [
          "metrics=true"
        ]
      }
    }
  }
}
