job "obs-grafana" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }
  

  group "grafana" {
    count = 1

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }

      port "http" {
        to = 3000
      }
    }

    volume "grafana" {
      type = "csi"
      read_only = false
      source = "grafana_volume"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    service {
      name = "grafana"
      port = "http"
      tags = [
        "global", "metrics",
        "traefik.enable=true",
        "traefik.http.routers.grafana.rule=Host(`grafana.brickyard.whitestar.systems`)"
      ]
    }

    task "grafana" {
      driver = "docker"
      volume_mount {
        volume      = "grafana"
        destination = "/var/lib/grafana"
        read_only   = false
      }

      config {
        image = "grafana/grafana:9.4.2"
        ports = ["http"]
      }

      resources {
        cpu    = 500
        memory = 1024
      }

      env {
        GF_LOG_LEVEL = "DEBUG"
        GF_LOG_MODE = "console"
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
        GF_PATHS_CONFIG = "${NOMAD_TASK_DIR}/grafana.ini"
        GF_PATHS_PROVISIONING = "${NOMAD_TASK_DIR}/grafana/provisioning"
        GF_INSTALL_PLUGINS = "grafana-clock-panel,grafana-piechart-panel"
      }

      template {
        data = <<EOF
[users]
allow_sign_up = false
auto_assign_org = true
auto_assign_org_role = Editor

[auth.jwt]
jwk_set_url = https://whitestar.cloudflareaccess.com/cdn-cgi/access/certs
enabled = true
header_name = Cf-Access-Jwt-Assertion
username_claim = email
email_claim = email
auto_sign_up = true
        EOF

        destination = "/local/grafana.ini"

      }

      template {
        data = <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus.service.{{ env "NOMAD_DC" }}.consul:9090
EOF
        destination = "/local/grafana/provisioning/datasources/datasources.yaml"

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }
    }
  }
}

