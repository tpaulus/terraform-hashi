// ==== Plugins ====
resource "nomad_job" "Storage-Controller" {
  jobspec = file("${path.module}/plugins/storage-controller.hcl")
}

resource "nomad_job" "Storage-Node" {
  jobspec = file("${path.module}/plugins/storage-node.hcl")
}


resource "nomad_job" "Traefik" {
  jobspec = file("${path.module}/plugins/traefik.hcl")
}

resource "nomad_job" "cloudflared" {
  jobspec = file("${path.module}/plugins/cloudflared.hcl")
}


// ==== Volumes ====
resource "nomad_external_volume" "n8n_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "n8n_volume"
  name         = "n8n_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode     = "single-node-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "blog_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "blog_volume"
  name         = "blog_volume"
  capacity_min = "1GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "netbox_db_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "netbox_db_volume"
  name         = "netbox_db_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "netbox_media_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "netbox_media_volume"
  name         = "netbox_media_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "z2m_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "z2m_volume"
  name         = "z2m_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "mqtt_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "mqtt_volume"
  name         = "mqtt_volume"
  capacity_min = "1GiB"
  capacity_max = "1GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "home_assistant_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "home_assistant_volume"
  name         = "home_assistant_volume"
  capacity_min = "10GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "unifi_protect_backup_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "unifi_protect_backup_volume"
  name         = "unifi_protect_backup_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "grafana_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "grafana_volume"
  name         = "grafana_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "prometheus_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "prometheus_volume"
  name         = "prometheus_volume"
  capacity_min = "10GiB"
  capacity_max = "100GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "immich_photos_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "immich_photos_volume"
  name         = "immich_photos_volume"
  capacity_min = "1024GiB"
  capacity_max = "1024GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "immich_db_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "immich_db_volume"
  name         = "immich_db_volume"
  capacity_min = "1GiB"
  capacity_max = "10GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

resource "nomad_external_volume" "immich_search_volume" {
  type         = "csi"
  plugin_id    = "org.democratic-csi.truenas-nfs"
  volume_id    = "immich_search_volume"
  name         = "immich_search_volume"
  capacity_min = "1GiB"
  capacity_max = "2.5GiB"

  capability {
    access_mode = "multi-node-reader-only"
    attachment_mode = "file-system"
  }

  capability {
    access_mode = "multi-node-multi-writer"
    attachment_mode = "file-system"
  }

  mount_options {
    fs_type = "nfs"
    mount_flags = ["noatime", "nfsvers=3", "nolock"]
  }
}

// ==== Jobs ====
resource "nomad_job" "Lunch_Money_Offsets" {
  jobspec = file("${path.module}/jobs/offset_tracker.hcl")
}

resource "nomad_job" "MQTT" {
  jobspec = file("${path.module}/jobs/mosquitto.hcl")
}

resource "nomad_job" "CF_Gateway_IP_Updater" {
  jobspec = file("${path.module}/jobs/gateway-ip.hcl")
}

resource "nomad_job" "N8N" {
  jobspec = file("${path.module}/jobs/n8n.hcl")
}

resource "nomad_job" "Blog" {
  jobspec = file("${path.module}/jobs/blog.hcl")
}

resource "nomad_job" "Netbox" {
  jobspec = file("${path.module}/jobs/netbox.hcl")
}

resource "nomad_job" "Zigbee2Mqtt" {
  jobspec = file("${path.module}/jobs/zigbee2mqtt.hcl")
}

resource "nomad_job" "HomeAssistant" {
  jobspec = file("${path.module}/jobs/home-assistant.hcl") 
}

resource "nomad_job" "unifi-protect-backup" {
  jobspec = file("${path.module}/jobs/unifi-protect-backup.hcl") 
}

resource "nomad_job" "alertmanager" {
  jobspec = file("${path.module}/jobs/alertmanager.hcl") 
}

resource "nomad_job" "grafana" {
  jobspec = file("${path.module}/jobs/grafana.hcl") 
}

resource "nomad_job" "prometheus" {
  jobspec = file("${path.module}/jobs/prometheus.hcl") 
}

resource "nomad_job" "snmp-exporter" {
  jobspec = file("${path.module}/jobs/snmp_exporter.hcl") 
}

resource "nomad_job" "graphite-exporter" {
  jobspec = file("${path.module}/jobs/graphite_exporter.hcl") 
}

resource "nomad_job" "consul-exporter" {
  jobspec = file("${path.module}/jobs/consul_exporter.hcl") 
}

resource "nomad_job" "cloudprober" {
  jobspec = file("${path.module}/jobs/cloudprober.hcl") 
}

resource "nomad_job" "coa-utilities-bill-generation" {
  jobspec = file("${path.module}/jobs/coa-utilities-bill-generation.hcl") 
}

resource "nomad_job" "immich" {
  jobspec = file("${path.module}/jobs/immich.hcl") 
}