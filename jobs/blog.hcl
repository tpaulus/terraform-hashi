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

    task "ghost" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "ghost:5.68.0"

        auth_soft_fail = true

        mount = {
          type   = "bind"
          source = "secrets/config.production.json"
          target = "/var/lib/ghost/config.production.json"
        }
      }

      service {
        name         = "blog"  # blog.service.seaview.consul
        port         = 2368
        provider     = "consul"
        address_mode = "driver"

        tags = [
            "global", "blog"
        ]

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
          address_mode = "driver"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      template {
        destination   = "secrets/config.production.json"
        data          = <<EOH
{
  "url": "https://blog.tompaulus.com/",
  "server": {
    "port": 2368,
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
      "port": 3306,
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
        network_mode = "weave"
        image = "mysql:8.1.0"

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
        port         = 3306
        provider     = "consul"
        address_mode = "driver"

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
          address_mode = "driver"

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