job "obs-cloudprober" {
  datacenters = ["seaview"]
  type = "service"

  priority = 75

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }
  
  group "cloudprober" {
    count = 1

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    task "cloudprober" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "cloudprober/cloudprober:v0.12.6"

        args = [
          "--config_file", "${NOMAD_TASK_DIR}/cloudprober.cfg"
        ]
      }

      resources {
        cpu    = 200
        memory = 256
      }

      service {
        name = "cloudprober"
        provider = "consul"
        port = 9313
        address_mode = "driver"
        
        tags = [
          "metrics=true"
        ]

        check {
          type     = "http"
          path     = "/status"
          interval = "3s"
          timeout  = "1s"
          address_mode = "driver"
        }
      }

      template {
        data = <<EOF
# Internal Services
probe {
  name: "Home Assistant"
  type: HTTP
  targets {
    host_names: "home.whitestar.systems"
  }
  additional_label {
    key: "location"
    value: "internal"
  }
  additional_label {
    key: "type"
    value: "service"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Protect NVR"
  type: HTTP
  targets {
    host_names: "protect.brickyard.whitestar.systems"
  }
  tls_config {
    disable_cert_validation: true
  }
  additional_label {
    key: "location"
    value: "internal"
  }
  additional_label {
    key: "type"
    value: "service"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Blog"
  type: HTTP
  targets {
    host_names: "blog.tompaulus.com"
  }
  additional_label {
    key: "location"
    value: "internal"
  }
  additional_label {
    key: "type"
    value: "service"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

# External Services

probe {
  name: "1.1.1.1"
  type: PING
  targets {
    host_names: "1.1.1.1"
  }
  additional_label {
    key: "location"
    value: "external"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Google Homepage"
  type: HTTP
  targets {
    host_names: "www.google.com"
  }
  additional_label {
    key: "location"
    value: "external"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Apple Homepage"
  type: HTTP
  targets {
    host_names: "apple.com"
  }
  additional_label {
    key: "location"
    value: "external"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}
EOF

        change_mode   = "signal"
        change_signal = "SIGHUP"
        destination   = "local/cloudprober.cfg"
      }
    }
  }
}

