job "Netbox" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "Frontend" {
    count = 2

    restart {
      attempts = 5
      delay    = "15s"
      interval = "2m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "http" {
        to = 8080
      }
    }


    volume "netbox-media-nfs-volume" {
      type            = "csi"
      source          = "netbox_media_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "netbox-ui" {
      driver = "docker"
      config = {
        image = "docker.io/netboxcommunity/netbox:v3.4.4"
        ports = ["http"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "netbox-media-nfs-volume"
        destination = "/opt/netbox/netbox/media"
        read_only   = false
      }

      service {
        name         = "netbox"  # netbox.service.seaview.consul
        port         = "http"
        provider     = "consul"

        tags = [
          "global", "netbox",
          "traefik.enable=true",
          "traefik.http.routers.netbox.rule=Host(`netbox.whitestar.systems`)",
          "traefik.http.middlewares.netbox-retry.retry.attempts=5",
          "traefik.http.middlewares.netbox-retry.retry.initialinterval=100ms"
        ]

        check {
          name     = "TCP Health Check"
          type     = "tcp"
          port     = "http"
          interval = "60s"
          timeout  = "5s"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }

        check {
          name     = "HTTP Health Check"
          type     = "http"
          port     = "http"
          path     = "/"
          interval = "60s"
          timeout  = "5s"

          header {
            X-Forwarded-Host  = ["netbox.whitestar.systems"]
            X-Forwarded-For   = ["127.0.0.1"]
            X-Forwarded-Proto = ["https"]
          }

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      resources {
        cpu    = 512
        memory = 256
      }

      template {
        data = <<EOH
CORS_ORIGIN_ALLOW_ALL=True
DB_HOST={{ range service "netbox-db" }}{{ .Address }}{{ end }}
{{ with nomadVar "nomad/jobs/Netbox" -}}
DB_NAME={{ .dbName }}
DB_PASSWORD={{ .dbPassword }}
DB_USER={{ .dbUser }}
{{- end }}
DB_PORT={{ range service "netbox-db" }}{{ .Port }}{{ end }}
{{ with nomadVar "SMTP" -}}
EMAIL_FROM=netbox@whitestar.systems
EMAIL_PASSWORD={{ .pass }}
EMAIL_PORT={{ .port }}
EMAIL_SERVER= {{ .host }}
EMAIL_TIMEOUT=5
EMAIL_USERNAME={{ .user }}
{{- end }}
EMAIL_USE_SSL=false
EMAIL_USE_TLS=true
GRAPHQL_ENABLED=true
HOUSEKEEPING_INTERVAL=86400
MEDIA_ROOT=/opt/netbox/netbox/media
METRICS_ENABLED=false
REDIS_CACHE_DATABASE=0
{{ range service "netbox-redis-cache" -}}
REDIS_CACHE_HOST={{ .Address }}
REDIS_CACHE_PORT={{ .Port }}
{{ end }}
REDIS_CACHE_INSECURE_SKIP_TLS_VERIFY=false
REDIS_CACHE_PASSWORD={{ with nomadVar "nomad/jobs/Netbox" }}{{ .redisCachePassword }}{{ end }}
REDIS_CACHE_SSL=false
REDIS_DATABASE=0
{{ range service "netbox-redis" -}}
REDIS_HOST={{ .Address }}
REDIS_PORT={{ .Port }}
{{- end }}
REDIS_INSECURE_SKIP_TLS_VERIFY=false
REDIS_PASSWORD={{ with nomadVar "nomad/jobs/Netbox" }}{{ .redisPassword }}{{ end }}
REDIS_SSL=false
RELEASE_CHECK_URL=https://api.github.com/repos/netbox-community/netbox/releases
SECRET_KEY={{ with nomadVar "nomad/jobs/Netbox" }}{{ .secretKey }}{{ end }}
SKIP_SUPERUSER=true
WEBHOOKS_ENABLED=true
        EOH

        destination = "secrets/file.env"
        env         = true
      }
    }
  }

  group "Housekeeping" {
    count = 1
    
    restart {
      attempts = 5
      delay    = "15s"
      interval = "2m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }
    }

    task "netbox-housekeeping" {
      driver = "docker"
      config = {
        image = "docker.io/netboxcommunity/netbox:v3.4.4"

        auth_soft_fail = true

        command = "/opt/netbox/housekeeping.sh"
      }

      resources {
        cpu    = 256
        memory = 512
      }

      template {
        data = <<EOH
CORS_ORIGIN_ALLOW_ALL=True
DB_HOST={{ range service "netbox-db" }}{{ .Address }}{{ end }}
{{ with nomadVar "nomad/jobs/Netbox" -}}
DB_NAME={{ .dbName }}
DB_PASSWORD={{ .dbPassword }}
DB_USER={{ .dbUser }}
{{- end }}
DB_PORT={{ range service "netbox-db" }}{{ .Port }}{{ end }}
{{ with nomadVar "SMTP" -}}
EMAIL_FROM=netbox@whitestar.systems
EMAIL_PASSWORD={{ .pass }}
EMAIL_PORT={{ .port }}
EMAIL_SERVER= {{ .host }}
EMAIL_TIMEOUT=5
EMAIL_USERNAME={{ .user }}
{{- end }}
EMAIL_USE_SSL=false
EMAIL_USE_TLS=true
GRAPHQL_ENABLED=true
HOUSEKEEPING_INTERVAL=86400
MEDIA_ROOT=/opt/netbox/netbox/media
METRICS_ENABLED=false
REDIS_CACHE_DATABASE=0
{{ range service "netbox-redis-cache" -}}
REDIS_CACHE_HOST={{ .Address }}
REDIS_CACHE_PORT={{ .Port }}
{{ end }}
REDIS_CACHE_INSECURE_SKIP_TLS_VERIFY=false
REDIS_CACHE_PASSWORD={{ with nomadVar "nomad/jobs/Netbox" }}{{ .redisCachePassword }}{{ end }}
REDIS_CACHE_SSL=false
REDIS_DATABASE=0
{{ range service "netbox-redis" -}}
REDIS_HOST={{ .Address }}
REDIS_PORT={{ .Port }}
{{- end }}
REDIS_INSECURE_SKIP_TLS_VERIFY=false
REDIS_PASSWORD={{ with nomadVar "nomad/jobs/Netbox" }}{{ .redisPassword }}{{ end }}
REDIS_SSL=false
RELEASE_CHECK_URL=https://api.github.com/repos/netbox-community/netbox/releases
SECRET_KEY={{ with nomadVar "nomad/jobs/Netbox" }}{{ .secretKey }}{{ end }}
SKIP_SUPERUSER=true
WEBHOOKS_ENABLED=true
        EOH

        destination = "secrets/file.env"
        env         = true
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
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "psql" {
        to = 5432
      }
    }

    volume "netbox-nfs-volume" {
      type            = "csi"
      source          = "netbox_db_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "postgres" {
      driver = "docker"
      config = {
        image = "docker.io/postgres:15.1-alpine"
        ports = ["psql"]

        auth_soft_fail = true
      }

      volume_mount {
        volume      = "netbox-nfs-volume"
        destination = "/var/lib/postgresql/data"
        read_only   = false
      }

      service {
        name         = "netbox-db"
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
{{ with nomadVar "nomad/jobs/Netbox" -}}
POSTGRES_DB={{ .dbName }}
POSTGRES_PASSWORD={{ .dbPassword }}
POSTGRES_USER={{ .dbUser }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

    }
  }

  group "DB Cache" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "redis" {
        to = "6379"
      }
    }


    task "redis-cache" {
      driver = "docker"
      config = {
        image = "docker.io/redis:7.0.8-alpine"
        ports = ["redis"]

        auth_soft_fail = true
        args = ["/local/redis.conf"]

        mount {
          type   = "bind"
          source = "local"
          target = "/data"
        }
      }

      service {
        name         = "netbox-redis-cache"
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

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/Netbox" -}}
requirepass {{ .redisCachePassword }}
{{- end }}
        EOH

        destination = "/local/redis.conf"
      }

      resources {
        cpu    = 256
        memory = 512
      }
    }
  }

  group "App Cache" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["1.1.1.1", "1.0.0.1"]
      }

      port "redis" {
        to = "6379"
      }
    }

    task "redis" {
      driver = "docker"
      config = {
        image = "docker.io/redis:7.0.8-alpine"
        ports = ["redis"]

        auth_soft_fail = true
        args = ["/local/redis.conf"]

        mount {
          type   = "bind"
          source = "local"
          target = "/data"
        }
      }

      service {
        name         = "netbox-redis"
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

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/Netbox" -}}
requirepass {{ .redisPassword }}
appendonly yes
{{- end }}
        EOH

        destination = "/local/redis.conf"
      }

      resources {
        cpu    = 256
        memory = 512
      }
    }
  }
}
