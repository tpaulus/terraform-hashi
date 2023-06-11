locals {
  nodes = [
    {"hostname": "magnolia", "server": true},
    {"hostname":"ravenna", "server": true},
    {"hostname":"roosevelt", "server": true},
    {"hostname":"woodlandpark", "server": false},
    {"hostname": "broadmoor", "server": true},
  ]
}

# Policies
resource "consul_acl_policy" "default" {
  name = "default-policy"
  description = "Grants read access to agents and services"
  rules = <<-RULE
    agent_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }

    query_prefix "" {
      policy = "read"
    }

    key_prefix "" {
      policy = "write"
    }

    keyring = "read"
  RULE
}

resource "consul_acl_policy" "consul_servers" {
  name = "agent-policy-server"
  description = "Grants write access to server agent"
  rules = <<-RULE
      acl = "write"

      operator = "write"

      service_prefix "" {
        policy = "write"
      }

      session_prefix "" {
        policy = "read"
      }

      agent_prefix "" {
        policy = "read"
      }
  RULE
}
resource "consul_acl_policy" "consul_agents" {
  count = length(local.nodes)
  name = "agent-policy-client-${local.nodes[count.index].hostname}"
  description = "Grants write access to self agent and self services"
  rules = <<-RULE
  agent "${local.nodes[count.index].hostname}" {
    policy = "write"
  }
  node "${local.nodes[count.index].hostname}" {
    policy = "write"
  }
  service_prefix "" {
    policy = "write"
  }
  RULE
}

resource "consul_acl_policy" "nomad" {
  name  = "nomad"
  description = "Nomad Access Policy"
  rules = <<-RULE
    key_prefix "" {
      policy = "read"
    }
    service_prefix "" {
      policy = "write"
    }
    RULE
}

# Roles
resource "consul_acl_role" "consul_agents" {
  count = length(local.nodes)
  name = local.nodes[count.index].hostname
  description = "Grants write access to agent ${local.nodes[count.index].hostname}"
  policies = flatten([ 
    consul_acl_policy.default.id,
    consul_acl_policy.consul_agents[count.index].id,
    local.nodes[count.index].server ? [consul_acl_policy.consul_servers.id] : []
   ])
}

# Tokens
resource "consul_acl_token" "consul_agents" {
  count = length(local.nodes)
    description = "Token for node ${local.nodes[count.index].hostname}"
    roles = [consul_acl_role.consul_agents[count.index].name]
}

resource "consul_acl_token" "nomad" {
  description = "Nomad Access Token"
  policies = ["${consul_acl_policy.nomad.name}"]
  local = false
}

# KVs
data "local_file" "nomad_prometheus_rules" {
  filename = "${path.module}/jobs/configuration/prometheus/rules.yaml"
}

data "local_file" "nomad_prometheus_config" {
  filename = "${path.module}/jobs/configuration/prometheus/config.yaml.tpl"
}

resource "consul_key_prefix" "nomad_prometheus_config" {
  path_prefix = "nomad/prometheus/"

  subkeys = {
    "config" = data.local_file.nomad_prometheus_config.content
    "rules"  = data.local_file.nomad_prometheus_rules.content
  }
}