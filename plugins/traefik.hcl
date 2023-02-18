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
      port "ping"{
        to = 8082
        static = 8082
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
        port     = "ping"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "traefik:v3.0"
        ports = ["http", "admin", "ping"]

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
        ]
      }

      template {
        data = <<EOF
[entryPoints]
  [entryPoints.http]
    address = ":{{ env "NOMAD_PORT_http" }}"
    asDefault =  true
    [entryPoints.http.forwardedHeaders]
      insecure = true

  [entryPoints.traefik]
    address = ":{{ env "NOMAD_PORT_admin" }}"

  [entryPoints.ping]
    address = ":{{ env "NOMAD_PORT_ping" }}"

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

[log]
  level = "WARN"
  noColor = true

[ping]
  entrypoint = "ping"
  
[metrics]
  [metrics.prometheus]
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