job "cloudflared" {
  datacenters = ["seaview"]
  type        = "system"
  priority    = 100

  update {
    max_parallel = 1
    stagger      = "1m"
  }

  group "cloudflared" {
    network {
      mode = "host"

      port "metrics" {}
    }

    task "cloudflared" {
      driver = "docker"

      config {
        image = "cloudflare/cloudflared:2023.3.0"
        ports = ["metrics"]
        command = "tunnel"
        args = [
          "run \"${TUNNEL_NAME}\""
        ]

        volumes = [
          "secrets/cert.pem:/etc/cloudflared/cert.pem",
          "secrets/credentials.json:/etc/cloudflared/credentials.json",
          "local/config.yaml:/etc/cloudflared/config.yaml"
        ]
      }

      env {
        TUNNEL_NAME = "${attr.unique.hostname}.${node.datacenter}.${node.region}"
        TUNNEL_ORIGIN_CERT = "${NOMAD_SECRETS_DIR}/cert.pem"
        TUNNEL_METRICS = "0.0.0.0:${NOMAD_PORT_metrics}"
      }

      service {
      name = "cloudflared"
      provider = "consul"
      port = "metrics"
      
      tags = [
        "metrics=true"
      ]
    }

      template {
        data = <<EOF
{{/* Create Via `cloudflared tunnel create magnolia.seaview.us` */}}
{{- $hostname := env "attr.unique.hostname" }}
{{- $dc := env "node.datacenter" }}
{{- $configVarName := print "cloudflared/" $hostname "_" $dc "_us" }}
{{- with nomadVar $configVarName -}}
{
  "AccountTag": "{{ .AccountTag }}",
  "TunnelSecret": "{{ .TunnelSecret }}",
  "TunnelID": "{{ .TunnelID }}"
}
{{ end }}
EOF

        destination = "secrets/credentials.json"
      }

      template {
        data = <<EOF
{{ with nomadVar "cloudflared/origin_cert" -}}
{{ .PrivateKey }}
{{ .Certificate }}
{{ .ArgoTunnelToken }}
{{- end }}
EOF

        destination = "secrets/cert.pem"
      }

      template {
        data = <<EOF
{{ $hostname := env "attr.unique.hostname" }}
{{- $dc := env "node.datacenter" }}
{{- $configVarName := print "cloudflared/" $hostname "_" $dc "_us" }}
{{- with nomadVar $configVarName -}}
tunnel: {{ .TunnelID }}
{{- end }}
credentials-file: /etc/cloudflared/credentials.json
warp-routing:
  enabled: false

ingress:
# https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/tunnel-guide/local/local-management/ingress/
- hostname: nomad.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:4646
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - d219a1e2d81d3034f30ad054bbcda9de6e7b8ac3107acbe2c5c66f5b36a7ca35
- hostname: consul.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8500
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - e0012900257cb7560d6c1b025d3a5372210750431fe5109902e617a8aab25468
- hostname: netbox.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest:
    disableChunkedEncoding: true
    access:
      required: true
      teamName: whitestar
      audTag:
      - 268fe8ea853dbd153ec9023eb2187d88b33c0a45be66dea14a9113a26292c0cb
- hostname: n8n.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - ef26a6100d89e6f3fa04694054ea9b865369ae2e0579a02fb7e95ee751d8d0e7
- hostname: alertmanager.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - 5d3ead708d3639809c0b20fcff4a0294b73d483cdddd3cdf663dc82ef7bde503
- hostname: grafana.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - 383cd50986ddcddc0018638011ea367e4a2dc57dd0b59635b18b9f8be0c144f7
- hostname: prometheus.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest:
    access:
      required: true
      teamName: whitestar
      audTag:
      - fa3dd83c769193080cdc3a7156abea0e265e6f87c8b788551d7a7f87c521e75a
- hostname: immich.brickyard.whitestar.systems
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest: {}
- hostname: blog.tompaulus.com
  service: http://{{ env "attr.unique.network.ip-address" }}:8080
  originRequest: {}
- service: http://{{ env "attr.unique.network.ip-address" }}:8082
  hostname: n3d.brickyard.whitestar.systems
  originRequest: {}
- service: http_status:421
EOF

        destination = "local/config.yaml"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}