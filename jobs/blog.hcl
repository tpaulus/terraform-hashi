job "Blog" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "Blog" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "http" {}
    }

    volume "blog-nfs-volume" {
      type            = "csi"
      source          = "blog_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    service {
      name         = "blog"  # blog.service.seaview.consul
      port         = "http"
      provider     = "consul"

      tags = [
          "global", "blog",
          "traefik.enable=true",
          "traefik.http.routers.blog.rule=Host(`blog.tompaulus.com`)",
          "traefik.http.services.blog.loadbalancer.passhostheader=true"
      ]

      check {
        name     = "TCP Health Check"
        type     = "tcp"
        port     = "http"
        interval = "30s"
        timeout  = "5s"

        check_restart {
          limit = 3
          grace = "90s"
          ignore_warnings = false
        }
      }
    }

    task "ghost" {
      driver = "docker"
      config = {
        image = "docker.io/ghost:5.31.0"
        ports = ["http"]

        auth_soft_fail = true

        mount {
          type   = "bind"
          source = "local/config.production.json"
          target = "/var/lib/ghost/config.production.json"
        }
      }

      template {
        destination   = "local/config.production.json"
        data          = <<EOH
{
  "url": "https://blog.tompaulus.com/",
  "server": {
    "port": {{ env "NOMAD_PORT_http" }},
    "host": "0.0.0.0"
  },
  "mail": {
    "from": "Tom's Journal <blog@tompaulus.com>",
    "transport": "SMTP",
{{ with nomadVar "SMTP" -}}
    "options": {
      "host": "{{ .host }}",
      "port": {{ .port }},
      "service": "AWS SES",
      "auth": {
        "user": "{{ .user }}",
        "pass": "{{ .pass }}"
        }
    }
{{- end }}
  },
  "database": {
    "client": "sqlite3",
    "connection": {
      "filename": "/var/lib/ghost/content/data/ghost.db"
    }
  },
  "logging": {
    "transports": [
      "file",
      "stdout"
    ]
  },
  "process": "systemd",
  "paths": {
    "contentPath": "/var/lib/ghost/content"
  }
}
        EOH
        
      }

      volume_mount {
          volume      = "blog-nfs-volume"
          destination = "/var/lib/ghost/content"
          read_only   = false
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}