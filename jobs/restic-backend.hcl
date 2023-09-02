job "storage-restic" {
  datacenters = ["seaview"]
  type = "service"

  priority = 90

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "restic-rest-server" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    volume "backing-volume" {
      type            = "csi"
      source          = "restic_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "restic-rest-server" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "restic/rest-server:0.12.1"

        args = ["--prometheus", "--prometheus-no-auth", "--path", "/data"]

        auth_soft_fail = true
      }

      service {
        name         = "restic"  # restic.service.seaview.consul
        port         = 8000
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "storage", "restic",
          "metrics=true"
        ]

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
          address_mode = "driver"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      env {
        PASSWORD_FILE = "secrets/.htpasswd"
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/storage-restic" -}}
{{ range .Tuples -}}
{{ .K }}:{{ .V }}
{{ end }}
{{- end }}
        EOH

        perms = "600"
        destination = "secrets/.htpasswd"
      }


      volume_mount {
          volume      = "backing-volume"
          destination = "/data"
          read_only   = false
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}