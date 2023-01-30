job "HomeAssistant" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "home-assistant" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      port "http" {
        to = 8123
      }
    }

    volume "home-assistant-nfs-volume" {
      type            = "csi"
      source          = "home_assistant_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "home-assistant" {
      driver = "docker"
      config = {
        network_mode = "corp"
        dns_servers = ["10.0.10.99", "1.1.1.1", "1.0.0.1"]

        image = "ghcr.io/home-assistant/home-assistant:2023.1.7"
        ports = ["http"]

        auth_soft_fail = true

        volumes = ["/etc/localtime:/etc/localtime:ro"]
      }

      volume_mount {
          volume      = "home-assistant-nfs-volume"
          destination = "/config"
          read_only   = false
      }

      service {
        name         = "HomeAssistant"
        port         = "http"
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "home-automation"
        ]
      }

      resources {
        cpu    = 2048
        memory = 3072
      }
    }

    task "Update-CoIoT-IPs" {
      lifecycle {
        hook = "poststart"
        sidecar = false
      }

      driver = "exec"
      config {
        command = "bash /local/update-ips.sh"
      }

      template {
        destination = "/local/update-ips.sh"
        data = <<EOH
{{- range service "HomeAssistant" -}}
PEER="{{ .Address }}"
{{- end }}

{{- with nomadVar "nomad/jobs/HomeAssistant/home-assistant/Update-CoIoT-IPs" }}
for HOST in "{{ .Hosts }}"; do
  # Save Current Settings
  current_settings=$(mktemp)
  curl -X GET http://$HOST/settings --silent > $current_settings

  new_settings=$(mktemp)
  jq '.coiot.peer = "$PEER:5683"' $current_settings > $new_settings

  # Update Settings
  curl --location --request POST "http://$HOST/settings" \
    --header "Content-Type: application/json" \
    --data-raw @$new_settings \
    --silent > /dev/null

  echo "Settings Updated on $HOST"

  # Reboot
  # curl -X GET http://$HOST/reboot
  echo "Issued Reboot Command to $HOST"

  rm $current_settings $new_settings
done
{{- end }}
        EOH
      }
    }
  }
}