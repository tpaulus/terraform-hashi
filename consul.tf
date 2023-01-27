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

resource "consul_acl_token" "nomad" {
  description = "Nomad Access Token"
  policies = ["${consul_acl_policy.nomad.name}"]
  local = false
}