job "backup-icloud-photos" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "0 9,21 * * *"
    time_zone = "America/Los_Angeles"
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

    ephemeral_disk {
      migrate = true
      size    = 500
      sticky  = true
    }

    task "create-dirs" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      volume_mount {
        volume      = "photos-volume"
        destination = "/tmp/${NOMAD_ALLOC_ID}"
        propagation_mode = "private"
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "mkdir -p /tmp/${NOMAD_ALLOC_ID}/Tom"]
      }
    }

    task "set-cookie" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/backup-icloud-photos/Tom" -}}
COOKIE={{ .cookie }}
{{- end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "echo \"$COOKIE\"==== | fold -w 4 | sed '$ d' | tr -d '\n' | base64 --decode > ${NOMAD_ALLOC_DIR}/data/tomtompauluscom"]
      }
    }

    task "backup-photos" {
      driver = "docker"

      config {
        image = "icloudpd/icloudpd:1.16.3"
        auth_soft_fail = true
        interactive = true

        command = "icloudpd"
        args = [
          "--directory", "/photos/Tom",
          "--cookie-directory", "${NOMAD_ALLOC_DIR}/data/",
          "--username", "${ICLOUD_USERNAME}",
          "--password", "${ICLOUD_PASSWORD}",
          "--until-found", "10",
          "--auto-delete",
          "--smtp-username", "${SMTP_USERNAME}",
          "--smtp-password", "${SMTP_PASSWORD}",
          "--smtp-host", "${SMTP_SERVER}",
          "--smtp-port", "${SMTP_PORT}",
          "--notification-email", "${NOTIFICATION_EMAIL}",
          "--notification-email-from", "iCloud Photo Backups <nomad@whitestar.systems>",
          "--log-level", "debug",
          "--no-progress-bar",
        ]
      }

      volume_mount {
          volume      = "photos-volume"
          destination = "/photos"
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
ICLOUD_PASSWORD={{ .icloud_password }}
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

  group "Mel" {
    count = 1

    volume "photos-volume" {
      type            = "csi"
      source          = "icloud_pd_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    ephemeral_disk {
      migrate = true
      size    = 500
      sticky  = true
    }

    task "create-dirs" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      volume_mount {
        volume      = "photos-volume"
        destination = "/tmp/${NOMAD_ALLOC_ID}"
        propagation_mode = "private"
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "mkdir -p /tmp/${NOMAD_ALLOC_ID}/Mel"]
      }
    }

    task "set-cookie" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/backup-icloud-photos/Mel" -}}
COOKIE={{ .cookie }}
{{- end }}
        EOH

        destination = "secrets/cookie"
        env         = true
      }

      driver = "exec"
      config {
        command = "sh"
        args = ["-c", "echo \"$COOKIE\"==== | fold -w 4 | sed '$ d' | tr -d '\n' | base64 --decode > ${NOMAD_ALLOC_DIR}/data/melindamelearth"]
      }
    }

    task "backup-photos" {
      driver = "docker"

      config {
        image = "icloudpd/icloudpd:1.16.3"
        auth_soft_fail = true
        interactive = true

        command = "icloudpd"
        args = [
          "--directory", "/photos/Mel",
          "--cookie-directory", "${NOMAD_ALLOC_DIR}/data/",
          "--username", "${ICLOUD_USERNAME}",
          "--password", "${ICLOUD_PASSWORD}",
          "--until-found", "10",
          "--auto-delete",
          "--smtp-username", "${SMTP_USERNAME}",
          "--smtp-password", "${SMTP_PASSWORD}",
          "--smtp-host", "${SMTP_SERVER}",
          "--smtp-port", "${SMTP_PORT}",
          "--notification-email", "${NOTIFICATION_EMAIL}",
          "--notification-email-from", "iCloud Photo Backups <nomad@whitestar.systems>",
          "--log-level", "debug",
          "--no-progress-bar",
        ]
      }

      volume_mount {
          volume      = "photos-volume"
          destination = "/photos"
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

{{ with nomadVar "nomad/jobs/backup-icloud-photos/Mel" -}}
ICLOUD_USERNAME={{ .icloud_username }}
ICLOUD_PASSWORD={{ .icloud_password }}
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