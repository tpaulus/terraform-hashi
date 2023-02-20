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

      port "http" {}
    }
    service {
      name = "cloudprober"
      provider = "consul"
      port = "http"
      
      tags = [
        "metrics=true"
      ]

      check {
        type     = "http"
        path     = "/status"
        interval = "3s"
        timeout  = "1s"
      }
    }

    task "alertmanager" {
      driver = "docker"

      config {
        image = "prom/alertmanager:v0.25.0"
        ports = ["http"]

        args = [
          "--config.file${NOMAD_TASK_DIR}/cloudprober.cfg"
        ]
      }

      env {
        CLOUDPROBER_PORT = "NOMAD_PORT_http"
        CLOUDPROBER_HOST = "${attr.unique.network.ip-address}"
      }

      resources {
        cpu    = 200
        memory = 256
      }
      template {
        data = <<EOF
# Internal Services
probe {
  name: "Router Consul DNS"
  type: DNS
  targets {
    host_names: "10.0.10.3"
  }
  fqdn: "consul.service.seaview.consul"
  queryType: A
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}


probe {
  name: "Home Assistant"
  type: HTTP
  targets {
    host_names: "home.whitestar.systems"
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
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Google Homepage"
  type: HTTP
  targets {
    host_names: "www.google.com"
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

