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
        command = "backups/consul.sh"
      }

      artifact {
        source = "git::https://github.com/tpaulus/server-scripts.git"
      }
    }
  }
}