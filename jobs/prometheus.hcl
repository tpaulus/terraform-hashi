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
        image = "prom/prometheus:v2.43.1"
        
        args = [
          "--config.file=/etc/prometheus/config/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.listen-address=0.0.0.0:9090",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.external-url=https://prometheus.brickyard.whitestar.systems"
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

  - job_name: "weave"
    metrics_path: "/metrics"
    static_configs:
    - targets:
      - 10.0.10.48:21049
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
  - alert: Nomad Raft Backups Missing
    expr: time() - min(nomad_raft_backup_completed{}) > 16200
    for: 1m
    annotations:
      summary: Nomad Raft Not Being Backed Up
      description: It has been over 4 hours since the Nomad Raft has been backed up
      dashboard: https://grafana.brickyard.whitestar.systems/d/p1er_aLVk/backups?orgId=1
  - alert: Consul Raft Backups Missing
    expr: time() - min(consul_raft_backup_completed{}) > 16200
    for: 1m
    annotations:
      summary: Consul Raft Not Being Backed Up
      description: It has been over 4 hours since the Consul Raft has been backed up
      dashboard: https://grafana.brickyard.whitestar.systems/d/p1er_aLVk/backups?orgId=1

- name: UPSAlerts
  rules:
  - alert: UPS On Batt
    expr: network_ups_tools_ups_status{flag="OB"} == 1
    annotations:
      summary: UPS Is On Battery
      description: UPS is on battery power
      dashboard: https://grafana.brickyard.whitestar.systems/d/j4a-DMWRk/ups-statistics?orgId=1

- name: Cloudprober
  rules:
  - alert: Internal Service Down
    expr: sum(rate(success{job="cloudprober", location="internal"}[1m])) by (probe) / sum(rate(total{job="cloudprober", location="internal"}[1m])) by (probe) < 0.50
    for: 3m
    annotations:
      summary: "{{ $labels.probe }} Is Down"
      description: "{{ $labels.probe }} is failing Cloudprober Healthchecks"
      dashboard: https://grafana.brickyard.whitestar.systems/d/bztcrl14k/status-overview
  - alert: Internet Down
    expr: sum(rate(success{job="cloudprober", location="external"}[1m])) / sum(rate(total{job="cloudprober", location="external"}[1m])) < 0.75
    for: 3m
    annotations:
      summary: Internet is Down
      description: External Healthchecks are failing - Internet or DNS May be down
      dashboard: https://grafana.brickyard.whitestar.systems/d/bztcrl14k/status-overview
  - alert: Primary Internet Down
    expr: sum(rate(success{probe="Internet - Lumen"}[1m]) / rate(total{probe="Internet - Lumen"}[1m])) < 0.75
    for: 3m
    annotations:
      summary: Centurylink is Down
      dashboard: https://grafana.brickyard.whitestar.systems/d/a6c53492-cfb0-41c9-8f71-cce622706523/internet-uplink
  - alert: Backup Internet Down
    expr: sum(rate(success{probe="Internet - T-Mobile"}[1m]) / rate(total{probe="Internet - T-Mobile"}[1m])) < 0.75
    for: 3m
    annotations:
      summary: T-Mobile is Down
      dashboard: https://grafana.brickyard.whitestar.systems/d/a6c53492-cfb0-41c9-8f71-cce622706523/internet-uplink

- name: Consul
  rules:
  - alert: Consul agent is not healthy
    expr: consul_health_node_status{status="critical"} == 1
    for: 1m
    annotations:
      title: Consul agent is down
      description: Consul agent is not healthy on {{ $labels.node }}.
  - alert: Consul cluster is degraded
    expr: min(consul_raft_peers) < 3
    for: 1m
    annotations:
      title: Consul cluster is degraded
      description: Consul cluster has {{ $value }} servers alive. This may lead to cluster break.

- name: Node
  rules:
  - alert: MDRAID degraded
    expr: (node_md_disks - node_md_disks{state="active"}) != 0
    for: 1m
    annotations:
      title: "MDRAID on node {{ $labels.instance }} is in degrade mode"
      description: "Degraded RAID array {{ $labels.device }} on {{ $labels.instance }}: {{ $value }} disks failed"
  - alert: Node down
    expr: up{job="node_exporter"} == 0
    for: 3m
    annotations:
      title: "Node {{ $labels.instance }} is down"
      description: "Failed to scrape {{ $labels.job }} on {{ $labels.instance }} for more than 3 minutes. Node seems down."
  - alert: Weave Network Down
    expr: node_systemd_unit_state{name="weave.service", state!="active"} != 0
    for: 2m
    annotations:
      title: "Weave is not running on {{ $labels.instance }}"
      description: "Weave Network on {{ $labels.instance }} is not active, current state: {{ $labels.state }}"

- name: NomadJobs
  rules:
  - alert: Home Assistant Down
    expr: nomad_nomad_job_summary_running{exported_job="ha-HomeAssistant"} == 0
    for: 5m
    annotations:
      title: Home Assistant is Down
      description: No Nomad Job is running for Home Assistant
      link: "https://nomad.brickyard.whitestar.systems/ui/jobs/ha-HomeAssistant@default"

EOH

        left_delimiter  = "[["
        right_delimiter = "]]"
        change_mode     = "signal"
        change_signal   = "SIGHUP"
        destination     = "local/config/rules.yml"
      }

      resources {
        cpu    = 1000
        memory = 2048
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

