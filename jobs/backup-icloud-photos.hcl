job "backup-icloud-photos" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "0 */12 * * *"
    prohibit_overlap = true
  }

  group "Tom" {
    count = 1

    volume "photos-volume" {
      type            = "csi"
      source          = "icloud_pd_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    volume "cookies-volume" {
      type            = "csi"
      source          = "icloud_pd_cookies_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "backup-photos" {
      driver = "docker"

      config {
        image = "icloudpd/icloudpd:1.12.0"
        auth_soft_fail = true

        args = [
          "--directory", "/photos/Tom",
          "--cookie-directory", "/cookies/Tom",
          "--username", "$ICLOUD_USERNAME",
          "--until-found", "10",
          "--auto-delete",
          "--smtp-username", "$SMTP_USERNAME",
          "--smtp-password", "$SMTP_PASSWORD",
          "--smtp-host", "$SMTP_SERVER",
          "--smtp-port", "$SMTP_PORT",
          "--notification-email", "$NOTIFICATION_EMAIL",
          "--notification-email-from", "iCloud Photo Backups <nomad@whitestar.systems>",
          "--log-level", "info",
          "--no-progress-bar",
        ]
      }

      volume_mount {
          volume      = "photos-volume"
          destination = "/photos"
          read_only   = false
      }

      volume_mount {
          volume      = "cookies-volume"
          destination = "/cookies"
          read_only   = false
      }

      template {
        data = <<EOH
TZ="America/Los_Angeles"

{{ with nomadVar "SMTP" -}}
SMTP_PORT={{ .port }}
SMTP_SERVER="{{ .host }}"
SMTP_USERNAME="{{ .user }}"
SMTP_PASSWORD="{{ .pass }}"
{{- end }}

{{ with nomadVar "nomad/jobs/backup-icloud-photos/Tom" -}}
ICLOUD_USERNAME={{ .icloud_username }}
NOTIFICATION_EMAIL={{ .notification_email }}
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
}