job "ops-ansible-applier" {
  datacenters = ["seaview"]
  type        = "batch"

  priority = 25

  reschedule {
    attempts       = 5
    delay          = "30s"
    delay_function = "fibonacci"
    max_delay      = "30m"
  }

  parameterized {
    payload       = "required"
    meta_required = ["TARGET_HOSTNAME"]
  }

  group "ansible" {
    count = 1

    restart {
      attempts = 1
      delay    = "15s"
      interval = "2m"
      mode     = "fail"
    }

    network {
      dns {
        servers = ["${attr.unique.network.ip-address}"]
      }
    }

    task "create-silences" {
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"

      config {
        network_mode = "weave"

        image = "prom/alertmanager:v0.25.0"

        entrypoint = ["/bin/sh"]
        command    = "/local/entrypoint.sh"

        mount {
          type   = "bind"
          source = "local/amtool_config.yml"
          target = "/etc/amtool/config.yml"
        }
      }

      dispatch_payload {
        file = "playbooks.txt"
      }

      template {
        destination = "local/amtool_config.yml"
        data        = <<EOH
alertmanager.url: "http://alertmanager.service.seaview.consul:9093"
author: "Ansible Applier"
comment_required: true
        EOH
        
        perms       = "644"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      template {
        destination = "local/entrypoint.sh"
        data        = <<EOH
#!/bin/bash
set -euxo pipefail

if [[ "{{ env "attr.unique.hostname" }}" == "{{ env "NOMAD_META_TARGET_HOSTNAME"}}" ]]; then
    echo "Cannot highstate self, aborting"
    exit 2
fi

amtool silence add\
  --duration="2h" \
  --comment="Ansible Auto Apply of $(cat /local/playbooks.txt) (Nomad Job ID: {{ env "NOMAD_ALLOC_ID" }}) (Nomad Alloc: {{ env "NOMAD_ALLOC_NAME"}})" \
  node="{{ env "NOMAD_META_TARGET_HOSTNAME"}}"
        EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }
    }

    task "ansible" {
      driver = "docker"

      config {
        image          = "ghcr.io/tpaulus/ansible-container:main"
        auth_soft_fail = true

        entrypoint = ["/bin/bash"]
        command    = "/local/entrypoint.sh"

        network_mode = "weave"

        mount {
          type   = "bind"
          source = "local/ansible.cfg"
          target = "/etc/ansible/ansible.cfg"
        }
      }

      dispatch_payload {
        file = "playbooks.txt"
      }

      artifact {
        source      = "git::https://github.com/tpaulus/ansible.git"
        destination = "local/ansible-repo"
        mode        = "dir"
        options {
            ref   = "main"
            depth = 1
        }
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
        destination = "local/ansible.cfg"
        data        = <<EOH
[defaults]
host_key_checking = False
enable_plugins = nb_inventory, auto, yaml, ini
        EOH
        perms       = "644"
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
#!/bin/bash
set -euxo pipefail

if [[ "{{ env "attr.unique.hostname" }}" == "{{ env "NOMAD_META_TARGET_HOSTNAME"}}" ]]; then
    echo "Cannot highstate self, aborting"
    exit 2
fi

eval `ssh-agent`
ssh-add /secrets/ssh_key

cd /local/ansible-repo

ansible-galaxy collection install -r requirements.yml

playbooks=`cat {{ env "NOMAD_TASK_DIR" }}/playbooks.txt`

echo "Executing Playbooks: $playbooks"

ansible-playbook \
  --vault-password-file /secrets/vault_password \
  --limit '~(?i){{ env "NOMAD_META_TARGET_HOSTNAME" }}' \
  --inventory netbox_inventory.yaml \
  --user ansible-applier \
  $playbooks
        EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      resources {
        cpu    = 1024
        memory = 2048
      }
    }

    task "expire-silences" {
      lifecycle {
        hook = "poststop"
        sidecar = false
      }

      driver = "docker"

      config {
        network_mode = "weave"

        image = "prom/alertmanager:v0.25.0"

        entrypoint = ["/bin/sh"]
        command    = "/local/entrypoint.sh"

        mount {
          type   = "bind"
          source = "local/amtool_config.yml"
          target = "/etc/amtool/config.yml"
        }
      }

      template {
        destination = "local/amtool_config.yml"
        data        = <<EOH
alertmanager.url: "http://alertmanager.service.seaview.consul:9093"
author: "Ansible Applier"
comment_required: true
        EOH
        
        perms       = "644"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }

      template {
        destination = "local/entrypoint.sh"
        data        = <<EOH
#!/bin/bash
set -euxo pipefail

amtool silence query node="{{ env "NOMAD_META_TARGET_HOSTNAME"}}"

amtool silence expire $(amtool silence query -q node="{{ env "NOMAD_META_TARGET_HOSTNAME"}}") 
        EOH
        perms       = "755"
        uid         = 0
        gid         = 0
        change_mode = "noop"
      }
    }

  }
}
