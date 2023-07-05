job "ops-ansible-applier" {
  datacenters = ["seaview"]
  type        = "batch"

  priority = 25

  reschedule {
    attempts       = 5
    delay          = "5m"
    delay_function = "fibonacci"
    max_delay      = "1h"
  }

  parameterized {
    payload       = "required"
    meta_required = ["TARGET_HOSTNAME"]
  }

  group "ansible" {
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

    ephemeral_disk {
      migrate = true
      size    = 1000
      sticky  = true
    }

    task "ansible" {
      driver = "docker"

      constraint {
        # Do not run high-states against self, as this can cause issues if Nomad or Docker is restarted
        attribute = "${NOMAD_META_TARGET_HOSTNAME}"
        operator  = "!="
        value     = "${meta.unique.hostname}"
      }

      config {
        image          = "ghcr.io/tpaulus/ansible-container:main"
        auth_soft_fail = true

        command = "local/entrypoint.sh"
      }

      dispatch_payload {
        file = "playbooks.txt"
      }

      artifact {
        source      = "https://raw.githubusercontent.com/tpaulus/ansible/main/netbox_inventory.yaml"
        destination = "local/inventory.yaml"
      }

      template {
        destination = "secrets/ssh_key"
        data        = <<EOH
{{ with nomadVar "nomad/jobs/ops-ansible-applier" -}}
{{ .SSH_PRIV_KEY }}
{{- end }}
         EOH
        perms       = "600"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      template {
        destination = "secrets/vault_password"
        data        = <<EOH
{{ with nomadVar "nomad/jobs/ops-ansible-applier" -}}
{{ .VAULT_PASSWORD }}
{{- end }}
         EOH
        perms       = "600"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      template {
        data = <<EOH
{{ with nomadVar "nomad/jobs/ops-ansible-applier" -}}
NETBOX_TOKEN={{ .NETBOX_TOKEN }}
{{ end }}
        EOH

        destination = "secrets/file.env"
        env         = true
      }

      template {
        destination = "local/entrypoint.sh"
        data        = <<EOH
 #!/bin/sh
set -eoux

mkdir -p ~/.ssh
ln -s /secrets/ssh_key ~/.ssh/id_ed25519

mkdir -p /alloc/${NOMAD_META_TARGET_HOSTNAME}
cd /alloc/${NOMAD_META_TARGET_HOSTNAME}

ansible-galaxy collection install -r requirements.yml

ansible-pull \
  --vault-password-file /secrets/vault_password \
  --url https://github.com/tpaulus/ansible.git \
  -l ${NOMAD_META_TARGET_HOSTNAME} \
  -i /local/inventory.yaml \
  $(cat ${NOMAD_TASK_DIR}/config.json)
         EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }
    }
  }
}