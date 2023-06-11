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
        image = "prom/prometheus:v2.44.0"
        
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
{{key "nomad/prometheus/config"}}
EOH

        change_mode   = "noop"
        destination   = "local/config/prometheus.yml.tpl"
      }

      template {
        source        = "local/config/prometheus.yml.tpl"
        destination   = "local/config/prometheus.yml"

        change_mode   = "signal"
        change_signal = "SIGHUP"
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

