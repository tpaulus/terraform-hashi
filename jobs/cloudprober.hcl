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

    update {
      max_parallel      = 1
      health_check      = "checks"
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
      progress_deadline = "10m"
      auto_revert       = true
      auto_promote      = true
      canary            = 1
    }

    task "cloudprober" {
      driver = "docker"

      config {
        network_mode = "weave"
        image = "cloudprober/cloudprober:v0.12.9"

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
  name: "Router DNS - Internal Query"
  type: DNS
  targets {
    host_names: "10.0.10.1"
  }
  dns_probe {
    resolved_domain: "consul.service.seaview.consul"
    query_type: A
  }
  additional_label {
    key: "location"
    value: "internal"
  }
  additional_label {
    key: "type"
    value: "dns"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Router DNS - External Query"
  type: DNS
  targets {
    host_names: "10.0.10.1"
  }
  dns_probe {
    resolved_domain: "tompaulus.com"
    query_type: A
  }
  additional_label {
    key: "location"
    value: "internal"
  }
  additional_label {
    key: "type"
    value: "dns"
  }
  interval_msec: 5000  # 5s
  timeout_msec: 1000   # 1s
}

probe {
  name: "Home Assistant"
  type: HTTP
  targets {
    host_names: "home.whitestar.systems"
  }
  {{ with nomadVar "nomad/jobs/obs-cloudprober" -}}
  http_probe {
    protocol: HTTPS
    
    header {
      key: "CF-Access-Client-Id"
      value: "{{ .ID }}"
    }
    header {
      key: "CF-Access-Client-Secret"
      value: "{{ .Secret }}"
    }
  }
  {{- end }}
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
  }
  validator {
      name: "expected_content"
      regex: "Home Assistant"
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
  http_probe {
    protocol: HTTPS
    tls_config {
      disable_cert_validation: true
    }
  }
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
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
  http_probe {
    protocol: HTTPS
  }
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
  }
  validator {
      name: "expected_content"
      regex: "[Jj]ournal"
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
  name: "Cloudflare"
  type: HTTP
  targets {
    host_names: "www.cloudflare.com"
  }
  http_probe {
    protocol: HTTPS
  }
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
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
  http_probe {
    protocol: HTTPS
  }
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
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
    host_names: "www.apple.com"
  }
  http_probe {
    protocol: HTTPS
  }
  validator {
      name: "status_code_2xx"
      http_validator {
          success_status_codes: "200-299"
      }
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
