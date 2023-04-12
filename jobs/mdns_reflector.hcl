job "mdns_reflector" {
  datacenters = ["seaview"]
  type = "service"

  priority = 100

  reschedule {
   delay          = "30s"
   delay_function = "exponential"
   max_delay      = "10m"
   unlimited      = true
  }

  affinity {
    attribute = "${attr.unique.hostname}"
    operator  = "!="
    value     = "magnolia"
    weight    = 100
  }

  group "mDNS" {
    count = 1

    task "reflector" {
      driver = "docker"

      config {
        network_mode = "host"
        image   = "yuxzhu/mdns-reflector:latest"
        command = "/usr/local/bin/mdns-reflector"
        args = ["-fn", "enp16s0f1", "weave"]
      }

      resources {
        cpu    = 128
        memory = 100
      }
    }
  }
}
