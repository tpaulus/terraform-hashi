// ==== Plugins ====
resource "nomad_job" "Storage-Controller" {
  jobspec = file("${path.module}/plugins/storage-controller.hcl")
}

resource "nomad_job" "Storage-Node" {
  jobspec = file("${path.module}/plugins/storage-node.hcl")
}

# resource "nomad_job" "cloudflared" {
#   jobspec = file("${path.module}/plugins/cloudflared.hcl")
# }

// ==== Jobs ====
# resource "nomad_job" "Lunch_Money_Offsets" {
#   jobspec = file("${path.module}/jobs/offset_tracker.hcl")
# } Moved to K3s

# resource "nomad_job" "N8N" {
#   jobspec = file("${path.module}/jobs/n8n.hcl")
# } Moved to K3s

# resource "nomad_job" "Blog" {
#   jobspec = file("${path.module}/jobs/blog.hcl")
# } Moved to K3s

# resource "nomad_job" "Netbox" {
#   jobspec = file("${path.module}/jobs/netbox.hcl")
# } Moved to K3s

# resource "nomad_job" "HomeAssistant" {
#   jobspec = file("${path.module}/jobs/home-assistant.hcl") 
# } Moved to Broadmoor

# resource "nomad_job" "unifi-protect-backup" {
#   jobspec = file("${path.module}/jobs/backup-unifi-protect.hcl") 
# } Moved to K3s

# resource "nomad_job" "alertmanager" {
#   jobspec = file("${path.module}/jobs/alertmanager.hcl") 
# } Moved to K3s

# resource "nomad_job" "grafana" {
#   jobspec = file("${path.module}/jobs/grafana.hcl") 
# } Moved to K3s

# resource "nomad_job" "prometheus" {
#   jobspec = file("${path.module}/jobs/prometheus.hcl") 
# } Moved to K3s

# resource "nomad_job" "snmp-exporter" {
#   jobspec = file("${path.module}/jobs/snmp_exporter.hcl") 
# } Deprecated

# resource "nomad_job" "graphite-exporter" {
#   jobspec = file("${path.module}/jobs/graphite_exporter.hcl") 
# } Moved to K3s

# resource "nomad_job" "consul-exporter" {
#   jobspec = file("${path.module}/jobs/consul_exporter.hcl") 
# } Deprecated

# resource "nomad_job" "nut-exporter" {
#   jobspec = file("${path.module}/jobs/nut_exporter.hcl") 
# } Moved to K3s

# resource "nomad_job" "cloudprober" {
#   jobspec = file("${path.module}/jobs/cloudprober.hcl") 
# } Moved to K3s

# resource "nomad_job" "coa-utilities-bill-generation" {
#   jobspec = file("${path.module}/jobs/coa-utilities-bill-generation.hcl") 
# } Moved to K3s

# resource "nomad_job" "icloud_pd" {
#   jobspec = file("${path.module}/jobs/backup-icloud-photos.hcl") 
# } Deactivated

# resource "nomad_job" "opnsense-exporter" {
#   jobspec = file("${path.module}/jobs/opnsense-exporter.hcl")
# } Moved to K3s

# resource "nomad_job" "ansible-applier" {
#   jobspec = file("${path.module}/jobs/ansible-applier.hcl")
# } Deprecated

# resource "nomad_job" "restic-backend" {
#   jobspec = file("${path.module}/jobs/restic-backend.hcl")
# } Deprecated

# resource "nomad_job" "vlmcsd" {
#   jobspec = file("${path.module}/jobs/vlmcsd.hcl")
# } Moved to K3s

# resource "nomad_job" "warp-tunnel" {
#   jobspec = file("${path.module}/jobs/warp-tunnel.hcl")
# } Moved to Broadmoor