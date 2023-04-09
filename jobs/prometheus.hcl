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
        static = 9090
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
        image = "prom/prometheus:v2.43.0"
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
  - /local/config/rules.yml

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

  - job_name: "node_exporter"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.10.48:9100
      - 10.0.10.64:9100
      - 10.0.10.80:9100

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

  - job_name: 'snmp-unifi'
    static_configs:
      - targets: &unifi_devices
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
      module: [unifi]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{ range service "prometheus-snmp-exporter" }}{{ .Address }}:{{ .Port }}{{ end }}

  - job_name: 'snmp-ubiquiti_unifi'
    static_configs:
      - targets: *unifi_devices

    metrics_path: /snmp
    params:
      module: [ubiquiti_unifi]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: {{ range service "prometheus-snmp-exporter" }}{{ .Address }}:{{ .Port }}{{ end }}

  - job_name: 'snmp-if_mib'
    static_configs:
      - targets: *unifi_devices

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

{{ range services }}
{{- if .Tags | contains "metrics=true" }}
{{- scratch.Set "metrics_path" "/metrics" }}
{{- range .Tags }}
{{- if . | contains "metrics_path=" }}
{{- scratch.Set "metrics_path" ( . | trimPrefix "metrics_path=") }}
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

{{- end }}
{{- end -}}
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/prometheus.yml"
      }

      template {
        data = <<EOH
---
groups:
- name: RaftBackups
  rules:
  - alert: NomadRaftBackups
    expr: time() - nomad_raft_backup_completed{} > 16200
    for: 1m
    annotations:
      summary: Nomad Raft Not Being Backed Up
      description: It has been over 4 hours since the Nomad Raft has been backed up
      dashboard: https://grafana.brickyard.whitestar.systems/d/p1er_aLVk/backups?orgId=1
  - alert: ConsulRaftBackups
    expr: time() - consul_raft_backup_completed{} > 16200
    for: 1m
    annotations:
      summary: Consul Raft Not Being Backed Up
      description: It has been over 4 hours since the Consul Raft has been backed up
      dashboard: https://grafana.brickyard.whitestar.systems/d/p1er_aLVk/backups?orgId=1
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/rules.yml"
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

