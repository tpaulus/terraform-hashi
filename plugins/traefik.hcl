job "traefik" {
  datacenters = ["seaview"]
  type        = "system"
  priority    = 100

  group "traefik" {
    network {
      port "http"{
        to = 8080
        static = 8080
      }
      port "admin"{
        to = 8081
        static = 8081
      }
    }

    service {
      name = "traefik"

      check {
        name     = "alive"
        type     = "tcp"
        port     = "http"
        interval = "10s"
        timeout  = "2s"
      }

      check {
        name     = "heathy"
        type     = "http"
        path     = "/ping"
        port     = "admin"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "docker.io/traefik:v3.0"
        ports = ["http", "admin"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.http]
  address = ":{{ env "NOMAD_PORT_http" }}"
  [entryPoints.http.forwardedHeaders]
    insecure = true

  [entryPoints.traefik]
  address = ":{{ env "NOMAD_PORT_admin" }}"

[api]
  dashboard = true
  insecure  = true

# Enable Consul Catalog configuration backend.
[providers.consulCatalog]
  prefix           = "traefik"
  exposedByDefault = false
  watch            = true

  [providers.consulCatalog.endpoint]
    address = "{{ env "attr.unique.network.ip-address" }}:8500"
    scheme  = "http"

[accessLog]
[log]
  level = "WARN"
  noColor = true

[ping]
EOF

        destination = "local/traefik.toml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}