variable "consul_token" {
    type = string
    sensitive = true
}

variable "cf_access_client_id" {
    type = string
}

variable "cf_access_client_secret" {
    type = string
    sensitive = true
}