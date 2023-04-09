job "obs-alertmanager" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }
  
  group "alertmanager" {
    count = 1

    network {
      port "http" {
        to = 9093
      }
    }
    service {
      name = "alertmanager"
      provider = "consul"
      port = "http"
      
      tags = [
        "global", "metrics",
        "traefik.enable=true",
        "traefik.http.routers.alertmanager.rule=Host(`alertmanager.brickyard.whitestar.systems`)",
      ]

      check {
        type     = "http"
        path     = "/-/healthy"
        interval = "3s"
        timeout  = "1s"
      }
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:v0.25.0"
        ports = ["http"]

        args = [
          "--config.file=${NOMAD_TASK_DIR}/config/alertmanager.yml"
        ]
      }

      resources {
        cpu    = 200
        memory = 256
      }
      template {
        data = <<EOH
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'email-tom'
receivers:
- name: 'email-tom'
  email_configs:
  - to: tom@tompaulus.com
gobal:
{{ with nomadVar "SMTP" -}}
  smtp_from: alertmanager@whitestar.systems
  smtp_smarthost: "{{ .host }}:{{ .port }}"
  smtp_auth_username: {{ .user }}
  smtp_auth_password: {{ .pass }}
  smtp_require_tls: true
{{- end }}
EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/alertmanager.yml"
      }
    }
  }
}

