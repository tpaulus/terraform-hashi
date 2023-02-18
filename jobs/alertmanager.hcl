job "alertmanager" {
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
        image = "docker.io/prom/alertmanager:v0.25.0"
        args = [
          "--config.file=/etc/alertmanager/config/alertmanager.yml"
        ]
        volumes = [
          "local/config:/etc/alertmanager/config",
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
  receiver: 'web.hook'
receivers:
- name: 'web.hook'
  webhook_configs:
  - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']

EOH

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/config/alertmanager.yml"
      }
    }
  }
}

