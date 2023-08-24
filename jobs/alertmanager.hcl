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
      dns {
        servers = ["1.1.1.1", "1.0.0.1", "${attr.unique.network.ip-address}"]  # Include non-internal DNS Resolvers to enable notifications when the internal resolvers are down
      }
    }

    task "alertmanager" {
      driver = "docker"

      config {
        network_mode = "weave"
        
        image = "prom/alertmanager:v0.26.0"

        args = [
          "--config.file=${NOMAD_TASK_DIR}/config/alertmanager.yml",
          "--web.external-url=https://alertmanager.brickyard.whitestar.systems"
        ]
      }

     service {
        name = "alertmanager"
        provider = "consul"
        port = 9093
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
  repeat_interval: 4h
  receiver: 'email-tom'  # Default Receiver
  routes:
    - receiver: 'webhook-homeassistant'
      group_wait: 0s
      matchers:
        - reciever=~"(.+ )?webhook-homeassistant( .+)?"
receivers:
- name: 'email-tom'
  email_configs:
  - to: tom@tompaulus.com
    send_resolved: true
- name: 'webhook-homeassistant'
  webhook_configs:
    - send_resolved: false
      max_alerts: 1
      url: {{ with nomadVar "nomad/jobs/obs-alertmanager" }}{{ .HomeAssistantWebhook }}{{ end }}
global:
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

