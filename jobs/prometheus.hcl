job "obs-prometheus" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }
  
  group "prometheus" {

    network {
      port "http" {
        to = 9090
      }
    }

    volume "prometheus-volume" {
      type            = "csi"
      source          = "prometheus_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v2.42.0"
        ports = ["http"]
        
        args = [
          "--config.file=/etc/prometheus/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:9090",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles"
        ]

        volumes = [
          "local/config:/etc/prometheus/config",
        ]
      }

      volume_mount {
          volume      = "prometheus-volume"
          destination = "/prometheus"
          read_only   = false
      }

      template {
        data = <<EOH
---
global:
  scrape_interval: 30s
  evaluation_interval: 3s

rule_files:
  - rules.yml

alerting:
 alertmanagers:
    - consul_sd_configs:
      - server: {{ env "attr.unique.network.ip-address" }}:8500
        services:
        - alertmanager

scrape_configs:
  - job_name: prometheus
    static_configs:
    - targets:
      - 0.0.0.0:9090
  - job_name: "nomad_server"
    metrics_path: "/v1/metrics"
    params:
      format:
      - "prometheus"
    consul_sd_configs:
    - server: "{{ env "attr.unique.network.ip-address" }}:8500"
      services:
        - "nomad"
      tags:
        - "http"
  - job_name: "nomad_client"
    metrics_path: "/v1/metrics"
    params:
      format:
      - "prometheus"
    consul_sd_configs:
    - server: "{{ env "attr.unique.network.ip-address" }}:8500"
      services:
        - "nomad-client"
  - job_name: 'snmp'
    static_configs:
      - targets:
        - 10.0.1.63   # STTLWASCQ01
        - 10.0.1.214  # STTLWASCQ02
        - 10.0.1.97   # STTLWASCQ03
        - 10.0.1.196  # STTLWASCQ04
        - 10.0.1.91   # STTLWASCS01
        - 10.0.1.73   # STTLWASCS02
        # STTLWASCS03 does not support SNMP
        - 10.0.1.140  # STTLWASCS04
        # STTLWASCS05 does not support SNMP

    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{ range service "prometheus-snmp-exporter" }}{{ .Address }}:{{ .Port }}{{ end }}
  - job_name: graphite
    static_configs:
      - targets:
          - {{ range service "prometheus-graphite-exporter" }}{{ .Address }}:{{ .Port }}{{ end }}
    honor_labels: true  


EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      resources {
        cpu    = 1000
        memory = 2048
      }
      service {
        name = "prometheus"
        port = "http"
        provider = "consul"

        tags = [
          "global", "metrics",
          "traefik.enable=true",
          "traefik.http.routers.prometheus.rule=Host(`prometheus.brickyard.whitestar.systems`)",
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "3s"
          timeout  = "1s"
        }
      }
    }
  }
}

