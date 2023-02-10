job "backup-consul" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "0 */4 * * *"
    prohibit_overlap = true
  }

  group "backup-consul" {
    task "backup-consul" {
      driver = "raw_exec"

      config {
        command = "consul.sh"
      }

      artifact {
        source = "https://raw.githubusercontent.com/tpaulus/server-scripts/main/backups/consul.sh"
      }
    }
  }
}