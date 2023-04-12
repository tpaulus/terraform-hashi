job "mdns_reflector" {
  datacenters = ["seaview"]
  type = "service"

  priority = 100

  group "mDNS" {
    count = 1

    task "reflector" {
      driver = "docker"

      config {
        network = "host"
        image   = "yuxzhu/mdns-reflector:latest"
        command = "mdns-reflector -fn $(route | grep '^default' | grep -o '[^ ]*$') weave"
      }

      resources {
        cpu    = 500 # 500 MHz
        memory = 256 # 256MB
      }
    }
  }
}
