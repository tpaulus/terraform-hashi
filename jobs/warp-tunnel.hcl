job "net-warp-tunnel" {
  datacenters = ["seaview"]
  type        = "service"
  priority    = 90

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "cloudflared" {
    count = 1

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    task "cloudflared" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "cloudflare/cloudflared:2023.8.2"
        command = "tunnel"
        args = [
          "run --token \"${TOKEN}\""
        ]
      }

      template {
        data = <<EOF
{{- with nomadVar "cloudflared/brickyard-warp" -}}
TOKEN = "{{ .TunnelToken }}"
}
{{ end }}
EOF

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}
