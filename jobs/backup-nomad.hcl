job "backup-nomad" {
  datacenters = ["seaview"]
  type = "batch"

  periodic {
    cron = "0 */4 * * *"
    prohibit_overlap = true
  }

  group "backup-nomad" {
    task "backup-nomad" {
      driver = "raw_exec"

      config {
        command = "nomad.sh"
      }

      artifact {
        source = "https://raw.githubusercontent.com/tpaulus/server-scripts/main/backups/nomad.sh"
      }
    }
  }
}