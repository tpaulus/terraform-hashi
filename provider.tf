terraform {
  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "2.18.0"
    }
    nomad = {
      source = "hashicorp/nomad"
      version = "2.0.0"
    }
  }
}

provider "consul" {
  address = "https://consul.brickyard.whitestar.systems"
  token = var.consul_token

  header {
    name = "CF-Access-Client-Id"
    value = var.cf_access_client_id
  }

  header {
    name = "CF-Access-Client-Secret"
    value = var.cf_access_client_secret
  }
}

provider "nomad" {
  address = "https://nomad.brickyard.whitestar.systems"

  headers {
    name = "CF-Access-Client-Id"
    value = var.cf_access_client_id
  }

  headers {
    name = "CF-Access-Client-Secret"
    value = var.cf_access_client_secret
  }
}