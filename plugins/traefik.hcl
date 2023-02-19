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
        image = "traefik:v3.0.0-beta2"
        ports = ["http", "admin", "ping"]

        volumes = [
          "local/traefik.yaml:/etc/traefik/traefik.yaml",
        ]
      }

      template {
        data = <<EOF
entryPoints:
  http:
    address: ":{{ env "NOMAD_PORT_http" }}"
    asDefault: true
    forwardedHeaders:
      insecure: true
  traefik:
    address: ":{{ env "NOMAD_PORT_admin" }}"
  ping:
    address: ":{{ env "NOMAD_PORT_ping" }}"
api:
  dashboard: true
  insecure: true
providers:
  consulCatalog:
    prefix: traefik
    exposedByDefault: false
    watch: true
    endpoint:
      address: "{{ env "attr.unique.network.ip-address" }}:8500"
      scheme: http
log:
  level: WARN
  noColor: true
ping:
  entrypoint: ping
metrics:
  prometheus: {}

experimental:
  plugins:
    traefik-real-ip:
      moduleName: "github.com/soulbalz/traefik-real-ip"
      version: "v1.0.3"

http:
  middlewares:
    traefik-real-ip:
      traefik-real-ip:
        excludednets: []
EOF

        destination = "local/traefik.yaml"
      }

      resources {
        cpu    = 100
        memory = 128
      }
    }
  }
}