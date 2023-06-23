job "net-unifi-controller" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  group "Controller" {
    count = 1

    restart {
      attempts = 3
      delay    = "15s"
      interval = "10m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    volume "unifi-controller-volume" {
      type            = "csi"
      source          = "unifi_controller_volume"
      read_only       = false
      attachment_mode = "file-system"
      access_mode     = "single-node-writer"
    }

    ephemeral_disk {
      migrate = true
      size    = 1000
      sticky  = true
    }

    task "unifi-controller" {
      driver = "docker"
      config {
        network_mode = "weave"
        image = "jacobalberty/unifi:v7.4.156"

        auth_soft_fail = true
        mount = {
          type   = "bind"
          source = "local/00_link_logs_dir.sh"
          target = "/usr/unifi/init.d/00_link_logs_dir" #File names for run-parts MUST NOT have an extension
        }
      }

      env {
        TZ = "America/Los_Angeles"
      }

      service {
        name         = "unifi"  # unifi.service.seaview.consul
        port         = 8443
        provider     = "consul"
        address_mode = "driver"

        tags = [
          "global", "unifi", "networking"
        ]

        check {
          name     = "Device Interface Health Check"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
          port     = 8080
          address_mode = "driver"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }

        check {
          name     = "UI Health Check"
          type     = "http"
          protocol = "https"
          tls_skip_verify = true
          path     = "/"
          interval = "3s"
          timeout  = "1s"
          address_mode = "driver"

          check_restart {
            limit = 3
            grace = "90s"
            ignore_warnings = false
          }
        }
      }

      template {
        destination   = "local/00_link_logs_dir.sh"
        data          = <<EOH
#!/bin/sh
echo "Symlinking Log Dir to Alloc Dir"
mkdir -p /alloc/controller-logs
chown -R unifi:unifi /alloc/controller-logs
rm -rf /unifi/log || true
ln --symbolic -i /alloc/controller-logs/ /unifi/log
        EOH
        perms = "755"
        uid = 999
        gid = 999
        change_mode = "noop"
      }

      volume_mount {
          volume      = "unifi-controller-volume"
          destination = "/unifi/data"
          read_only   = false
      }

      resources {
        cpu    = 2048
        memory = 3072
      }
    }

    task "log-rotate" {
      lifecycle {
        hook = "poststart"
        sidecar = true
      }

      driver = "docker"
      config {
        image = "blacklabelops/logrotate:1.3"

        auth_soft_fail = true
      }

      env {
        LOGS_DIRECTORIES = "/alloc/controller-logs"
        LOGROTATE_INTERVAL = "daily"
        LOGROTATE_COPIES = "10"
        LOGROTATE_SIZE = "100M"
      }

      resources {
        cpu    = 100
        memory = 300
      }
    }
  }
}