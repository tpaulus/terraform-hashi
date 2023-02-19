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
        "traefik.http.routers.grafana.rule=Host(`grafana.brickyard.whitestar.systems`)",
        "traefik.http.routers.grafana.middlewares=traefik-real-ip",
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
        image = "grafana/grafana:9.3.6"
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
        GF_PATHS_PROVISIONING = "/local/grafana/provisioning"
      }

      artifact {
        source      = "https://grafana.com/api/dashboards/1860/revisions/26/download"
        destination = "local/grafana/provisioning/dashboards/linux/linux-node-exporter.json"
        mode = "file"

      }
      template {
        data = <<EOF
apiVersion: 1

providers:
  - name: dashboards
    type: file
    updateIntervalSeconds: 30
    options:
      foldersFromFilesStructure: true
      path: /local/grafana/provisioning/dashboards

EOF
        destination = "/local/grafana/provisioning/dashboards/dashboards.yaml"
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
      }
    }
  }
}

