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
        command = "backups/nomad.sh"
      }

      artifact {
        source = "git::https://github.com/tpaulus/server-scripts"
      }
    }
  }
}