job "Immich" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }


  group "Server" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "http" {
        to = "3001"
      }
    }

    service {
      name     = "immich-api"
      port     = "http"
      provider = "consul"

      tags = [
        "traefik.enable=true",
        "traefik.http.routers.service-immich-api.rule=Host(`immich.brickyard.whitestar.systems`) && Pathprefix(`/api`)",
        "traefik.http.routers.service-immich-api.middlewares=service-immich-api-strip",
        "traefik.http.middlewares.service-immich-api-strip.stripprefix.prefixes=/api"
      ]
    }

    volume "photos-volume" {
      type            = "csi"
      source          = "immich_photos_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "immich-server" {
      driver = "docker"
      config {
        image = "altran1502/immich-server:v1.50.1"
        command = "/bin/sh"
        args    = ["./start-server.sh"]

        ports = ["http"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "photos-volume"
        destination = "/usr/src/app/upload"
        read_only   = false
      }

      env {
        NODE_ENV = "production"
        TYPESENSE_ENABLED = "false"
      }

      template {
        data = <<EOH
{{ range service "immich-db" -}}
DB_HOSTNAME =  {{ .Address }}
DB_PORT = {{ .Port }}
{{- end}}

{{ with nomadVar "nomad/jobs/immich/db" -}}
DB_USERNAME = {{ .POSTGRES_USER }}
DB_PASSWORD = {{ .POSTGRES_PASSWORD }}
DB_DATABASE_NAME = {{ .POSTGRES_DB }}
{{- end }}

{{ range service "immich-redis" -}}
REDIS_HOSTNAME = {{ .Address }}
REDIS_PORT = {{ .Port }}
{{- end }}

{{ range service "immich-ml" -}}
IMMICH_MACHINE_LEARNING_URL=http://{{ .Address }}:{{ .Port }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }

  group "MicroServices" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    volume "photos-volume" {
      type            = "csi"
      source          = "immich_photos_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "immich-worker" {
      driver = "docker"
      config {
        image = "altran1502/immich-server:v1.50.1"
        command = "/bin/sh"
        args    = ["./start-microservices.sh"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "photos-volume"
        destination = "/usr/src/app/upload"
        read_only   = false
      }

      env {
        NODE_ENV = "production"
        TYPESENSE_ENABLED = "false"
      }

      template {
        data = <<EOH
{{ range service "immich-db" -}}
DB_HOSTNAME =  {{ .Address }}
DB_PORT = {{ .Port }}
{{- end}}

{{ with nomadVar "nomad/jobs/immich/db" -}}
DB_USERNAME = {{ .POSTGRES_USER }}
DB_PASSWORD = {{ .POSTGRES_PASSWORD }}
DB_DATABASE_NAME = {{ .POSTGRES_DB }}
{{- end }}

{{ range service "immich-redis" -}}
REDIS_HOSTNAME = {{ .Address }}
REDIS_PORT = {{ .Port }}
{{- end }}

{{ range service "immich-ml" -}}
IMMICH_MACHINE_LEARNING_URL=http://{{ .Address }}:{{ .Port }}
{{- end }}

REVERSE_GEOCODING_PRECISION=3
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }

  group "ML" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "http" {
        to = "3003"
      }
    }

    service {
      name     = "immich-ml"
      port     = "http"
      provider = "consul"
    }

    volume "photos-volume" {
      type            = "csi"
      source          = "immich_photos_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "immich-ml" {
      driver = "docker"
      config {
        image = "altran1502/immich-machine-learning:v1.50.1"
        ports = ["http"]

        auth_soft_fail = true

        mount = {
          type   = "bind"
          source = "local/"
          target = "/cache"
        }
      }

      volume_mount {
        volume      = "photos-volume"
        destination = "/usr/src/app/upload"
        read_only   = false
      }

      env {
        NODE_ENV = "production"
      }

      template {
        data = <<EOH
{{ range service "immich-db" -}}
DB_HOSTNAME =  {{ .Address }}
DB_PORT = {{ .Port }}
{{- end}}

{{ with nomadVar "nomad/jobs/immich/db" -}}
DB_USERNAME = {{ .POSTGRES_USER }}
DB_PASSWORD = {{ .POSTGRES_PASSWORD }}
DB_DATABASE_NAME = {{ .POSTGRES_DB }}
{{- end }}

{{ range service "immich-redis" -}}
REDIS_HOSTNAME = {{ .Address }}
REDIS_PORT = {{ .Port }}
{{- end }}

REVERSE_GEOCODING_PRECISION=3
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 3072
        memory = 1024
      }
    }

  }

  group "Frontend" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "http" {
        to = "3000"
      }
    }

    service {
      name     = "immich-web"
      port     = "http"
      provider = "consul"


      tags = [
        "traefik.enable=true",
        "traefik.http.routers.service-immich-http.rule=Host(`immich.brickyard.whitestar.systems`)"
      ]
    }

    task "immich-web" {
      driver = "docker"
      config {
        image   = "altran1502/immich-web:v1.50.1"
        command = "/bin/sh"
        args    = ["./entrypoint.sh"]
        ports   = ["http"]

        auth_soft_fail = true
      }

      env {
        NODE_ENV = "production"
        TYPESENSE_ENABLED = "false"
      }

      template {
        data = <<EOH
{{ range service "immich-db" -}}
DB_HOSTNAME =  {{ .Address }}
DB_PORT = {{ .Port }}
{{- end}}

{{ with nomadVar "nomad/jobs/immich/db" -}}
DB_USERNAME = {{ .POSTGRES_USER }}
DB_PASSWORD = {{ .POSTGRES_PASSWORD }}
DB_DATABASE_NAME = {{ .POSTGRES_DB }}
{{- end }}

{{ range service "immich-redis" -}}
REDIS_HOSTNAME = {{ .Address }}
REDIS_PORT = {{ .Port }}
{{- end }}

{{ range service "immich-api" -}}
IMMICH_SERVER_URL=http://{{ .Address }}:{{ .Port }}
{{- end }}
{{ range service "immich-ml" -}}
IMMICH_MACHINE_LEARNING_URL=http://{{ .Address }}:{{ .Port }}
{{- end }}

REVERSE_GEOCODING_PRECISION=3
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }

  group "redis" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      port "redis" {
        to = "6379"
      }
    }

    task "redis" {
      driver = "docker"
      config {
        image = "redis:7.0.9"
        ports = ["redis"]

        auth_soft_fail = true

        mount = {
          type   = "bind"
          source = "local"
          target = "/data"
        }
      }

      resources {
        cpu    = 256
        memory = 512
      }

      service {
        name         = "immich-redis"
        tags         = ["internal"]
        port         = "redis"
        provider     = "consul"

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          port     = "redis"
          interval = "30s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }
    }
  }

  group "DB" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "psql" {
        to = 5432
      }
    }

    volume "db-volume" {
      type            = "csi"
      source          = "immich_db_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "immich-postgres" {
      driver = "docker"
      config {
        image = "postgres:15.2-alpine"
        ports = ["psql"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "db-volume"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      service {
        name         = "immich-db"
        tags         = ["internal", "db"]
        port         = "psql"
        provider     = "consul"

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          port     = "psql"
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
        memory = 1024
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/immich/db" -}}
{{ range .Tuples -}}
{{ .K }}="{{ .V }}"
{{ end }}
{{- end }}
PG_DATA="/var/lib/postgresql/data"
        EOH

        destination = "secrets/file.env"
        env         = true
      }

    }
  }
}