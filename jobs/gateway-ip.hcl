job "cf-sync-gateway-ip" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "*/14 * * * *"
    prohibit_overlap = true
  }

  group "CF-Gateway" {
    count = 1

    task "update ip" {
      driver = "exec"

      config {
        command = "update-gateway-ip.sh"
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/CF_Gateway_IP" -}}
CF_API_TOKEN = {{ .CF_API_TOKEN }}
CF_ACCOUNT_ID = {{ .CF_ACCOUNT_ID }}
CF_GATEWAY_LOCATION = {{ .CF_GATEWAY_LOCATION }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      artifact {
        source = "https://raw.githubusercontent.com/tpaulus/server-scripts/main/update-gateway-ip.sh"
      }

      resources {
        cpu    = 256
        memory = 128
      }
    }
  }
}