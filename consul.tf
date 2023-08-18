locals {
  nodes = {
    # Do not remove or change the order of items in the list
    "ravenna": {"server": true},
    "roosevelt": {"server": true},
    "woodlandpark": {"server": false},
    "beaconhill": {"server": false},
    "laurelhurst": {"server": true},
  }
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
  for_each = local.nodes

  name = "agent-policy-client-${each.key}"
  description = "Grants write access to self agent and self services"
  rules = <<-RULE
    agent "${each.key}" {
      policy = "write"
    }
    node "${each.key}" {
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
  for_each = local.nodes

  name = each.key
  description = "Grants write access to agent ${each.key}"
  policies = flatten([ 
    consul_acl_policy.default.id,
    consul_acl_policy.consul_agents[each.key].id,
    each.value.server ? [consul_acl_policy.consul_servers.id] : []
   ])
}

# Tokens
resource "consul_acl_token" "consul_agents" {
  for_each = local.nodes

  description = "Token for node ${each.key}"
  roles = [consul_acl_role.consul_agents[each.key].name]
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

resource "consul_key_prefix" "nomad_prometheus_config" {
  path_prefix = "nomad/prometheus/"

  subkeys = {
    "rules"  = data.local_file.nomad_prometheus_rules.content
  }
}