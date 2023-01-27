job "CF_Gateway_IP" {
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
        source = "https://gist.githubusercontent.com/tpaulus/50db3ba892841b44a2b8fed88a50d3c1/raw/e403262ef47ac11c7bdd52f4e05c2190ba278d6b/update-gateway-ip.sh"
      }

      resources {
        cpu    = 256
        memory = 128
      }
    }
  }
}