job "backup-unifi-protect" {
  datacenters = ["seaview"]
  type = "service"

  priority = 50

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "unifi-protect-backup" {
    count = 1

    restart {
      attempts = 1
      delay    = "60s"
      interval = "5m"
      mode     = "fail"
    }

    volume "unifi-protect-backup-nfs-volume" {
      type            = "csi"
      source          = "unifi_protect_backup_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    task "unifi-protect-backup" {
      driver = "docker"
      config {
        image = "ghcr.io/ep1cman/unifi-protect-backup:0.10.2"
        auth_soft_fail = true

        mount = {
          type   = "bind"
          source = "local/rclone.conf"
          target = "/root/.config/rclone/rclone.conf"
        }
      }

      template {
        destination   = "local/rclone.conf"
        data          = <<EOH
{{ with nomadVar "nomad/jobs/unifi-protect-backup" -}}
[b2]
type = b2
account = {{ .b2Account }}
key = {{ .b2Key }}
hard_delete = true

[compress-b2]
type = compress
remote = b2:seaview-protect

[encrypt-compress-b2]
type = crypt
remote = compress-b2:/
filename_encryption = off
directory_name_encryption = false
password = {{ .encryptionKey }}
{{- end }}
EOH
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/unifi-protect-backup" -}}
UFP_USERNAME = {{ .protectUsername }}
UFP_PASSWORD = {{ .protectPassword }}
UFP_ADDRESS = {{ .protectAddress }}
{{- end}}
UFP_SSL_VERIFY = false
RCLONE_RETENTION = 3d
RCLONE_DESTINATION = 'encrypt-compress-b2:/'
RCLONE_ARGS = '--config="{{ env "NOMAD_TASK_DIR" }}/rclone.conf"'
SQLITE_PATH = '/data/backup-events'
EOH
        destination = "secrets/file.env"
        env         = true
      }


      volume_mount {
          volume      = "unifi-protect-backup-nfs-volume"
          destination = "/data"
          read_only   = false
      }

      resources {
        cpu    = 1024
        memory = 1024
      }
    }
  }
}
