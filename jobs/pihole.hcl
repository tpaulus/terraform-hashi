job "net-pihole" {
  datacenters = ["seaview"]
  type = "service"
  priority = 100

  reschedule {
   delay          = "5s"
   delay_function = "exponential"
   max_delay      = "1m"
   unlimited      = true
  }

  spread {
    attribute = "${node.datacenter}"
  }

  group "pihole" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    task "cloudflared" {
      driver = "docker"

      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      config {
        network_mode = "weave"
        image = "cloudflare/cloudflared:2023.7.1"
        command = "proxy-dns"
        args = ["--address 0.0.0.0", "--upstream \"$UPSTREAM_URL\"", "--port 5301", "--metrics 0.0.0.0:50305"]
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/net-pihole" -}}
UPSTREAM_URL = {{ .DNS_UPSTREAM_URL }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }
      
      service {
        name     = "${BASE}"
        provider = "consul"
        port     = 50305
        address_mode = "driver"
        tags = [
          "metrics=true",
        ]
      }


      service {
        name     = "cloudflared-dns-proxy"
        provider = "consul"
        port     = 50305
        address_mode = "driver"
        tags = [
          "metrics=true",
        ]
      }
    }

    task "pihole" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "ghcr.io/pi-hole/pihole:2023.05.2"
      }

      resources {
        cpu = 1024
        memory = 2048
      }

      service {
        name     = "pihole"
        provider = "consul"
        port     = 53
        address_mode = "driver"
        tags = [
          "dns-resolver",
        ]
      }

      service {
        name     = "${BASE}"
        provider = "consul"
        port     = 80
        address_mode = "driver"
        tags = []
      }

       template {
        data = <<EOH
TZ = "America/Los_Angeles"
WEBPASSWORD = ""
DHCP_ACTIVE = "false"
WEBTHEME = "default-dark"

PIHOLE_DNS_ = "${NOMAD_JOB_NAME}-${NOMAD_GROUP_NAME}-cloudflared.service.${NOMAD_DC}.consul"
        EOH

        destination = "secrets/file.env"
        env         = true
      }
    }

    task "pihole-exporter" {
      driver = "docker"

      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      config {
        network_mode = "weave"
        image = "ekofr/pihole-exporter:v0.4.0"
      }

      template {
        data = <<EOH
PIHOLE_PASSWORD=""
PORT=9617
PIHOLE_HOSTNAME="${NOMAD_JOB_NAME}-${NOMAD_GROUP_NAME}-pihole.service.${NOMAD_DC}.consul"
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      service {
        name     = "pihole-exporter"
        provider = "consul"
        port     = 9617
        address_mode = "driver"
        tags = [
          "metrics=true"
        ]
      }
    }
  }
}
