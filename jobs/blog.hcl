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

      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    volume "blog-nfs-volume" {
      type            = "csi"
      source          = "blog_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
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

    task "wait-for-db" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "while ! nc -z ghost-db.service.seaview.consul 61612; do sleep 1; done"]
      }
    }

    task "ghost" {
      driver = "docker"
      config {
        image = "ghost:5.39.0"
        ports = ["http"]

        auth_soft_fail = true

        mount = {
          type   = "bind"
          source = "secrets/config.production.json"
          target = "/var/lib/ghost/config.production.json"
        }
      }

      template {
        destination   = "secrets/config.production.json"
        data          = <<EOH
{
  "url": "https://blog.tompaulus.com/",
  "server": {
    "port": {{ env "NOMAD_PORT_http" }},
    "host": "0.0.0.0"
  },
  "comments": {
    "url": false
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
    "client": "mysql",
    "connection": {
      "host": "ghost-db.service.seaview.consul",
      "port": 61612,
      {{ with nomadVar "nomad/jobs/Blog" -}}
      "user": "{{ .dbUser }}",
      "password": "{{ .dbPassword }}",
      "database": "{{ .dbName }}"
      {{- end }}
    },
    "pool": {
      "min": 2,
      "max": 20
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


  group "DB" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      port "mysql" {
        to = 3306
        static = 61612
      }
    }

    volume "blog_db_volume" {
      type            = "csi"
      source          = "blog_db_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "mysql" {
      driver = "docker"
      config {
        image = "mysql:8.0.32"
        ports = ["mysql"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "blog_db_volume"
        destination = "/var/lib/mysql"
        read_only   = false
      }

      service {
        name         = "ghost-db"
        tags         = ["internal", "db"]
        port         = "mysql"
        provider     = "consul"

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          port     = "mysql"
          interval = "30s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      resources {
        cpu    = 1024
        memory = 2048
      }

      template {
        data = <<EOH
MYSQL_ROOT_PASSWORD={{ timestamp | sha256Hex }}

{{ with nomadVar "nomad/jobs/Blog" -}}
MYSQL_DATABASE={{ .dbName }}
MYSQL_USER={{ .dbUser }}
MYSQL_PASSWORD={{ .dbPassword }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }
    }
  }
}