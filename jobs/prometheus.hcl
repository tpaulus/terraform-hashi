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
        network_mode = "weave"
        image = "prom/prometheus:v2.48.1"
        
        args = [
          "--config.file=/etc/prometheus/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--storage.tsdb.retention.time=4w",
          "--web.listen-address=0.0.0.0:9090",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.external-url=https://prometheus.brickyard.whitestar.systems",
          "--enable-feature=auto-gomaxprocs,new-service-discovery-manager,memory-snapshot-on-shutdown"
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
  - /local/config/rules.yml

alerting:
 alertmanagers:
    - consul_sd_configs:
      - server: {{ env "attr.unique.network.ip-address" }}:8500
        services:
        - alertmanager

storage:
  tsdb:
    out_of_order_time_window: 1m

scrape_configs:
  - job_name: prometheus
    static_configs:
    - targets:
      - 0.0.0.0:9090

  - job_name: "node_exporter"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.10.1:9100
      - 10.0.10.24:9100
      - 10.0.10.32:9100
      - 10.0.10.64:9100
      - 10.0.10.80:9100

  - job_name: "coredns"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.10.1:9253

  - job_name: "grimd"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.1.1:10005

  - job_name: "weave"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.10.24:21049
      - 10.0.10.64:21049
      - 10.0.10.80:21049

  - job_name: "consul"
    metrics_path: "/metrics"
    consul_sd_configs:
      - server: "{{ env "attr.unique.network.ip-address" }}:8500"
        services:
          - "prometheus-consul-exporter"

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

  - job_name: graphite
    static_configs:
      - targets:
          - {{ range service "prometheus-graphite-exporter" }}{{ .Address }}:{{ .Port }}{{ end }}
    honor_labels: true  

{{ range services }}
{{- if .Tags | contains "metrics=true" }}
{{- scratch.Set "metrics_path" "/metrics" }}
{{- range .Tags }}
{{- if . | contains "metrics_path=" }}
{{- scratch.Set "metrics_path" ( . | trimPrefix "metrics_path=") }}
{{- end }}
{{- end }}

{{- scratch.Set "node_as_instance" "false" }}
{{- range .Tags }}
{{- if . | contains "node_name_as_instance" }}
{{- scratch.Set "node_as_instance" "true" }}
{{- end }}
{{- end }}

  - job_name: {{ .Name }}
    metrics_path: "{{ scratch.Get "metrics_path" }}"
    params:
      format:
      - "prometheus"
    consul_sd_configs:
    - server: "{{ env "attr.unique.network.ip-address" }}:8500"
      services:
        - "{{ .Name }}"
    {{ if eq (scratch.Get "node_as_instance") "true" -}}
    relabel_configs:
    - action: replace
      source_labels: [__meta_consul_node]
      target_label: instance
    {{- end }}
{{- end }}
{{- end -}}
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      template {
        data = <<EOH
{{key "nomad/prometheus/rules"}}
EOH

        change_mode     = "signal"
        change_signal   = "SIGHUP"
        destination     = "local/config/rules.yml"
      }

      resources {
        cpu    = 5000
        memory = 6144
      }
      service {
        name = "prometheus"
        port = 9090
        provider = "consul"
        address_mode = "driver"

        tags = [
          "global", "metrics",
        ]

        check {
          type     = "http"
          path     = "/-/healthy"
          interval = "3s"
          timeout  = "1s"
          address_mode = "driver"
        }
      }
    }
  }
}

